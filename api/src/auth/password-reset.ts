import { sendPasswordResetOtpEmail } from '../email/resend-mailer';
import { DatabaseService } from '../db/database-service';
import { validateEmail, validateResetPassword } from '../db/validators';
import { hashPassword, uuid } from '../utils';
import {
  generateOtpCode,
  hashOtp,
  isOtpExpired,
  maxOtpAttempts,
  newOtpSaltB64,
  otpExpiresAtIso,
  verifyOtpHash,
} from './otp-crypto';

const RESEND_COOLDOWN_SEC = 60;
const MAX_REQUESTS_PER_HOUR = 5;

export interface PasswordResetEnv {
  JWT_SECRET: string;
  RESEND_API_KEY?: string;
  RESEND_FROM_EMAIL?: string;
}

function clientMeta(request: Request): { ip: string | null; ua: string | null } {
  return {
    ip:
      request.headers.get('CF-Connecting-IP') ??
      request.headers.get('X-Forwarded-For')?.split(',')[0]?.trim() ??
      null,
    ua: request.headers.get('User-Agent'),
  };
}

async function signResetToken(
  userId: string,
  requestId: string,
  secret: string,
): Promise<string> {
  const header = btoa(JSON.stringify({ alg: 'HS256', typ: 'JWT' }))
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
  const body = btoa(
    JSON.stringify({
      sub: userId,
      purpose: 'password_reset',
      rid: requestId,
      exp: Date.now() + 15 * 60 * 1000,
    }),
  )
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
  const data = `${header}.${body}`;
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const sig = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(data));
  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(sig)))
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
  return `${data}.${sigB64}`;
}

export async function verifyResetToken(
  token: string,
  secret: string,
): Promise<{ userId: string; requestId: string } | null> {
  try {
    const [header, body, sig] = token.split('.');
    if (!header || !body || !sig) return null;
    const data = `${header}.${body}`;
    const key = await crypto.subtle.importKey(
      'raw',
      new TextEncoder().encode(secret),
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['verify'],
    );
    const sigBytes = Uint8Array.from(
      atob(sig.replace(/-/g, '+').replace(/_/g, '/')),
      (c) => c.charCodeAt(0),
    );
    const valid = await crypto.subtle.verify(
      'HMAC',
      key,
      sigBytes,
      new TextEncoder().encode(data),
    );
    if (!valid) return null;
    const payload = JSON.parse(
      atob(body.replace(/-/g, '+').replace(/_/g, '/')),
    ) as Record<string, unknown>;
    if (payload.purpose !== 'password_reset') return null;
    if (typeof payload.exp === 'number' && payload.exp < Date.now()) return null;
    if (typeof payload.sub !== 'string' || typeof payload.rid !== 'string') {
      return null;
    }
    return { userId: payload.sub, requestId: payload.rid };
  } catch {
    return null;
  }
}

export async function handleRequestPasswordOtp(
  db: DatabaseService,
  env: PasswordResetEnv,
  request: Request,
  emailRaw: string,
): Promise<{ ok: true; requestId: string } | { ok: false; message: string; status: number }> {
  const email = emailRaw.trim().toLowerCase();
  if (!validateEmail(email)) {
    return { ok: false, message: 'Enter a valid email address.', status: 400 };
  }

  const user = await db.findUserByEmail(email);
  if (!user) {
    return {
      ok: false,
      message: 'No account found with this email.',
      status: 404,
    };
  }
  if (!user.password_hash) {
    return {
      ok: false,
      message:
        'This account uses Google sign-in. Please continue with Google to access your account.',
      status: 400,
    };
  }

  const recent = await db.countRecentPasswordResetRequests(email, 60);
  if (recent >= MAX_REQUESTS_PER_HOUR) {
    return {
      ok: false,
      message: 'Too many reset attempts. Please try again later.',
      status: 429,
    };
  }

  const meta = clientMeta(request);
  const otp = generateOtpCode();
  const salt = newOtpSaltB64();
  const pepper = env.JWT_SECRET;
  const otpHash = await hashOtp(otp, salt, pepper);
  const requestId = uuid();

  await db.invalidateActivePasswordResetOtps(user.id);
  await db.insertPasswordResetOtp({
    id: requestId,
    userId: user.id,
    email,
    otpHash,
    otpSalt: salt,
    expiresAt: otpExpiresAtIso(5),
    ipAddress: meta.ip,
    userAgent: meta.ua,
  });
  await db.insertPasswordResetAudit({
    id: uuid(),
    userId: user.id,
    email,
    eventType: 'otp_requested',
    ipAddress: meta.ip,
    userAgent: meta.ua,
  });

  const mailed = await sendPasswordResetOtpEmail(env, email, otp);
  if (!mailed.ok) {
    await db.markPasswordResetOtpUsed(requestId);
    return {
      ok: false,
      message: mailed.error ?? 'Could not send verification email.',
      status: 503,
    };
  }

  return { ok: true, requestId };
}

export async function handleResendPasswordOtp(
  db: DatabaseService,
  env: PasswordResetEnv,
  request: Request,
  emailRaw: string,
  requestId: string,
): Promise<{ ok: true; requestId: string } | { ok: false; message: string; status: number }> {
  const email = emailRaw.trim().toLowerCase();
  const row = await db.getPasswordResetOtp(requestId);
  if (!row || row.email !== email) {
    return { ok: false, message: 'Invalid reset request.', status: 400 };
  }
  if (row.used) {
    return { ok: false, message: 'This reset link has already been used.', status: 400 };
  }

  const created = new Date(row.created_at.replace(' ', 'T') + 'Z').getTime();
  const secondsSince = (Date.now() - created) / 1000;
  if (secondsSince < RESEND_COOLDOWN_SEC) {
    const wait = Math.ceil(RESEND_COOLDOWN_SEC - secondsSince);
    return {
      ok: false,
      message: `Resend OTP in ${wait}s`,
      status: 429,
    };
  }

  return handleRequestPasswordOtp(db, env, request, email);
}

export async function handleVerifyPasswordOtp(
  db: DatabaseService,
  env: PasswordResetEnv,
  request: Request,
  emailRaw: string,
  requestId: string,
  otp: string,
): Promise<
  | { ok: true; resetToken: string }
  | { ok: false; message: string; status: number }
> {
  const email = emailRaw.trim().toLowerCase();
  const row = await db.getPasswordResetOtp(requestId);
  if (!row || row.email !== email) {
    return { ok: false, message: 'Invalid verification code.', status: 400 };
  }
  if (row.used) {
    return { ok: false, message: 'This code has already been used.', status: 400 };
  }
  if (isOtpExpired(row.expires_at)) {
    return {
      ok: false,
      message: 'OTP expired. Please request a new code.',
      status: 400,
    };
  }
  if (row.attempts >= maxOtpAttempts()) {
    await db.markPasswordResetOtpUsed(requestId);
    return {
      ok: false,
      message: 'Too many failed attempts. Please request a new code.',
      status: 400,
    };
  }

  const valid = await verifyOtpHash(otp, row.otp_salt, row.otp_hash, env.JWT_SECRET);
  const meta = clientMeta(request);

  if (!valid) {
    await db.incrementPasswordResetAttempts(requestId);
    await db.insertPasswordResetAudit({
      id: uuid(),
      userId: row.user_id,
      email,
      eventType: 'otp_failed',
      ipAddress: meta.ip,
      userAgent: meta.ua,
    });
    return { ok: false, message: 'Invalid verification code.', status: 400 };
  }

  await db.markPasswordResetOtpVerified(requestId);
  await db.insertPasswordResetAudit({
    id: uuid(),
    userId: row.user_id,
    email,
    eventType: 'otp_verified',
    ipAddress: meta.ip,
    userAgent: meta.ua,
  });

  const resetToken = await signResetToken(row.user_id, requestId, env.JWT_SECRET);
  return { ok: true, resetToken };
}

export async function handleResetPassword(
  db: DatabaseService,
  env: PasswordResetEnv,
  request: Request,
  resetToken: string,
  password: string,
  confirmPassword: string,
): Promise<{ ok: true } | { ok: false; message: string; status: number }> {
  if (password !== confirmPassword) {
    return { ok: false, message: 'Passwords do not match.', status: 400 };
  }
  const check = validateResetPassword(password);
  if (!check.valid) {
    return { ok: false, message: check.message, status: 400 };
  }

  const parsed = await verifyResetToken(resetToken, env.JWT_SECRET);
  if (!parsed) {
    return {
      ok: false,
      message: 'Reset session expired. Please start again.',
      status: 401,
    };
  }

  const row = await db.getPasswordResetOtp(parsed.requestId);
  if (!row || row.user_id !== parsed.userId || !row.verified || row.used) {
    return { ok: false, message: 'Invalid reset session.', status: 400 };
  }

  const passwordHash = await hashPassword(password);
  await db.updateUserPassword(parsed.userId, passwordHash);
  await db.markPasswordResetOtpUsed(parsed.requestId);

  const meta = clientMeta(request);
  await db.insertPasswordResetAudit({
    id: uuid(),
    userId: parsed.userId,
    email: row.email,
    eventType: 'password_reset_success',
    ipAddress: meta.ip,
    userAgent: meta.ua,
  });

  return { ok: true };
}

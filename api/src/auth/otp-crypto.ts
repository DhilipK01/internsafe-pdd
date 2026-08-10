/** Cryptographic OTP generation and verification (hashed storage only). */

const OTP_LENGTH = 6;
const MAX_ATTEMPTS = 5;

export function generateOtpCode(): string {
  const buf = new Uint32Array(1);
  crypto.getRandomValues(buf);
  const n = buf[0]! % 1_000_000;
  return n.toString().padStart(OTP_LENGTH, '0');
}

export function otpExpiresAtIso(minutes = 5): string {
  const d = new Date(Date.now() + minutes * 60 * 1000);
  return d.toISOString().replace('T', ' ').slice(0, 19);
}

export async function hashOtp(
  otp: string,
  saltB64: string,
  pepper: string,
): Promise<string> {
  const enc = new TextEncoder();
  const salt = Uint8Array.from(atob(saltB64), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    'raw',
    enc.encode(pepper),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const sig = await crypto.subtle.sign(
    'HMAC',
    key,
    enc.encode(`${saltB64}:${otp.trim()}`),
  );
  return btoa(String.fromCharCode(...new Uint8Array(sig)));
}

export async function verifyOtpHash(
  otp: string,
  saltB64: string,
  storedHash: string,
  pepper: string,
): Promise<boolean> {
  const expected = await hashOtp(otp, saltB64, pepper);
  if (expected.length !== storedHash.length) return false;
  let diff = 0;
  for (let i = 0; i < expected.length; i++) {
    diff |= expected.charCodeAt(i) ^ storedHash.charCodeAt(i);
  }
  return diff === 0;
}

export function isOtpExpired(expiresAt: string): boolean {
  const exp = new Date(expiresAt.includes('T') ? expiresAt : `${expiresAt}Z`);
  return Number.isNaN(exp.getTime()) || exp.getTime() < Date.now();
}

export function maxOtpAttempts(): number {
  return MAX_ATTEMPTS;
}

export function newOtpSaltB64(): string {
  const salt = crypto.getRandomValues(new Uint8Array(16));
  return btoa(String.fromCharCode(...salt));
}

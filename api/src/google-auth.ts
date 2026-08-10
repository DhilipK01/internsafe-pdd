export class GoogleAuthError extends Error {
  constructor(
    message: string,
    readonly status = 400,
  ) {
    super(message);
    this.name = 'GoogleAuthError';
  }
}

export type GoogleTokenPayload = {
  sub: string;
  email: string;
  name?: string;
  picture?: string;
};

export function getGoogleClientId(env: {
  GOOGLE_CLIENT_ID?: string;
  GOOGLE_WEB_CLIENT_ID?: string;
}): string | undefined {
  return env.GOOGLE_CLIENT_ID?.trim() || env.GOOGLE_WEB_CLIENT_ID?.trim() || undefined;
}

export function requireJwtSecret(secret: string | undefined): string {
  if (!secret?.trim()) {
    throw new GoogleAuthError(
      'Server auth is not configured (JWT_SECRET missing on Worker)',
      503,
    );
  }
  return secret.trim();
}

/** Validates a Google ID token via Google's tokeninfo endpoint. */
export async function verifyGoogleIdToken(
  idToken: string,
  expectedClientId?: string,
): Promise<GoogleTokenPayload> {
  const isAccessToken = !idToken.startsWith('ey');
  const param = isAccessToken ? `access_token=${encodeURIComponent(idToken)}` : `id_token=${encodeURIComponent(idToken)}`;
  const res = await fetch(
    `https://oauth2.googleapis.com/tokeninfo?${param}`,
  );
  const data = (await res.json()) as Record<string, string>;

  if (!res.ok || data.error) {
    throw new GoogleAuthError(
      data.error_description ?? data.error ?? 'Invalid Google token',
      401,
    );
  }

  if (!data.sub?.trim()) {
    throw new GoogleAuthError('Invalid Google token payload', 401);
  }

  if (!data.email?.trim() || !data.email.includes('@')) {
    throw new GoogleAuthError(
      'Google account must provide an email address',
      400,
    );
  }

  if (expectedClientId) {
    const aud = data.aud ?? '';
    const azp = data.azp ?? '';
    if (aud !== expectedClientId && azp !== expectedClientId) {
      throw new GoogleAuthError('Google client mismatch', 401);
    }
  }

  return {
    sub: data.sub.trim(),
    email: data.email.trim().toLowerCase(),
    name: data.name?.trim() || undefined,
    picture: data.picture?.trim() || undefined,
  };
}

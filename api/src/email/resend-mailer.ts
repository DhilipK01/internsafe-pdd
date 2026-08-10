export interface ResendEnv {
  RESEND_API_KEY?: string;
  RESEND_FROM_EMAIL?: string;
}

export async function sendPasswordResetOtpEmail(
  env: ResendEnv,
  to: string,
  otp: string,
): Promise<{ ok: boolean; error?: string }> {
  const apiKey = env.RESEND_API_KEY?.trim();
  const from =
    env.RESEND_FROM_EMAIL?.trim() || 'INTERNSAFE AI <onboarding@resend.dev>';

  if (!apiKey) {
    return {
      ok: false,
      error:
        'Email service is not configured. Set RESEND_API_KEY on the API worker.',
    };
  }

  try {
    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from,
        to: [to],
        subject: 'INTERNSAFE AI Password Reset OTP',
        html: `<div style="font-family:Arial,sans-serif;max-width:480px"><h2 style="color:#0d9488">INTERNSAFE AI</h2><p>Your verification code is:</p><p style="font-size:32px;font-weight:bold;letter-spacing:8px">${otp}</p><p>This code expires in <strong>5 minutes</strong>.</p><p style="color:#888;font-size:13px">If you did not request this password reset, please ignore this email.</p><p style="color:#888;font-size:13px">— INTERNSAFE AI Security Team</p></div>`,
        text: `Your verification code is: ${otp}\n\nThis code expires in 5 minutes.\n\nIf you did not request this password reset, please ignore this email.\n\n- INTERNSAFE AI Security Team`,
      }),
    });
    if (!res.ok) {
      const text = await res.text();
      return {
        ok: false,
        error: `Email delivery failed (${res.status}): ${text.slice(0, 200)}`,
      };
    }
    return { ok: true };
  } catch (e) {
    return {
      ok: false,
      error: e instanceof Error ? e.message : 'Email delivery failed',
    };
  }
}

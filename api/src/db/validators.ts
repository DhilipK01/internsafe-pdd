const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const REPORT_TYPES = new Set([
  'Registration Fee Scam',
  'Fake Offer Letter',
  'Data Harvesting',
  'No-Show Company',
  'Impersonation',
  'Unpaid Internship Trap',
  'fake_offer',
  'payment_fraud',
  'data_theft',
  'impersonation',
  'ghost_company',
  'other',
]);
const RISK_LEVELS = new Set(['low', 'medium', 'high', 'critical', 'unknown']);

export function validateEmail(email: string): boolean {
  return EMAIL_RE.test(email.trim().toLowerCase());
}

export function validatePassword(password: string): boolean {
  return password.length >= 6;
}

export function validateResetPassword(password: string): {
  valid: boolean;
  message: string;
  checks: Record<string, boolean>;
} {
  const checks = {
    minLength: password.length >= 8,
    uppercase: /[A-Z]/.test(password),
    lowercase: /[a-z]/.test(password),
    number: /[0-9]/.test(password),
    special: /[^A-Za-z0-9]/.test(password),
  };
  const valid = Object.values(checks).every(Boolean);
  const message = valid
    ? 'Password meets requirements.'
    : 'Password must be at least 8 characters and include uppercase, lowercase, a number, and a special character.';
  return { valid, message, checks };
}

export function validateCompanyName(name: string): boolean {
  return name.trim().length >= 2;
}

export function validateReportType(type: string): boolean {
  const t = type.trim();
  return t.length >= 3 && (REPORT_TYPES.has(t) || t.length <= 80);
}

export function validateRiskLevel(level: string): boolean {
  return RISK_LEVELS.has(level);
}

export function validateDescription(desc: string): boolean {
  return desc.trim().length >= 10;
}

export function validateFileSize(size: number, maxBytes = 10 * 1024 * 1024): boolean {
  return size > 0 && size <= maxBytes;
}

export function sanitizeLikeQuery(q: string): string {
  return q.replace(/[%_]/g, '').trim().toLowerCase();
}

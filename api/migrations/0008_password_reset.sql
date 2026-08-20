-- Password reset OTPs and audit (production forgot-password flow)

ALTER TABLE users ADD COLUMN auth_version INTEGER NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS password_reset_otps (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  otp_hash TEXT NOT NULL,
  otp_salt TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  expires_at TEXT NOT NULL,
  verified INTEGER NOT NULL DEFAULT 0,
  attempts INTEGER NOT NULL DEFAULT 0,
  used INTEGER NOT NULL DEFAULT 0,
  resend_count INTEGER NOT NULL DEFAULT 0,
  ip_address TEXT,
  user_agent TEXT
);

CREATE INDEX IF NOT EXISTS idx_reset_otps_user ON password_reset_otps(user_id);
CREATE INDEX IF NOT EXISTS idx_reset_otps_email ON password_reset_otps(email);
CREATE INDEX IF NOT EXISTS idx_reset_otps_expires ON password_reset_otps(expires_at);

CREATE TABLE IF NOT EXISTS password_reset_audit (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  email TEXT NOT NULL,
  event_type TEXT NOT NULL,
  ip_address TEXT,
  user_agent TEXT,
  metadata TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_reset_audit_email ON password_reset_audit(email);
CREATE INDEX IF NOT EXISTS idx_reset_audit_created ON password_reset_audit(created_at DESC);

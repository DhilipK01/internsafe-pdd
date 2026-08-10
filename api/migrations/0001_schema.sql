-- INTERNSAFE production schema (Cloudflare D1 / SQLite)
-- Seed-free. Apply via: npm run db:migrate

PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS schema_migrations (
  version TEXT PRIMARY KEY,
  applied_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ---------------------------------------------------------------------------
-- 1. users
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  auth_uid TEXT UNIQUE,
  google_sub TEXT UNIQUE,
  email TEXT NOT NULL UNIQUE COLLATE NOCASE,
  password_hash TEXT,
  name TEXT NOT NULL,
  photo_url TEXT,
  college_name TEXT,
  phone TEXT,
  role TEXT NOT NULL DEFAULT 'student'
    CHECK (role IN ('student', 'admin', 'moderator')),
  is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  last_login TEXT,
  deleted_at TEXT,
  CHECK (length(trim(name)) > 0),
  CHECK (instr(email, '@') > 0)
);

-- ---------------------------------------------------------------------------
-- 2. user_settings
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_settings (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  dark_mode INTEGER NOT NULL DEFAULT 0 CHECK (dark_mode IN (0, 1)),
  notifications_enabled INTEGER NOT NULL DEFAULT 1 CHECK (notifications_enabled IN (0, 1)),
  language TEXT NOT NULL DEFAULT 'en',
  scan_sensitivity TEXT NOT NULL DEFAULT 'medium'
    CHECK (scan_sensitivity IN ('low', 'medium', 'high')),
  theme_mode TEXT NOT NULL DEFAULT 'system',
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ---------------------------------------------------------------------------
-- 3. uploaded_files
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS uploaded_files (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  file_name TEXT NOT NULL,
  original_name TEXT NOT NULL,
  file_type TEXT NOT NULL,
  mime_type TEXT NOT NULL,
  file_size INTEGER NOT NULL CHECK (file_size > 0 AND file_size <= 10485760),
  r2_key TEXT NOT NULL UNIQUE,
  r2_url TEXT,
  public_url TEXT,
  upload_type TEXT NOT NULL DEFAULT 'general',
  upload_status TEXT NOT NULL DEFAULT 'completed'
    CHECK (upload_status IN ('pending', 'uploading', 'completed', 'failed')),
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  deleted_at TEXT
);

-- ---------------------------------------------------------------------------
-- 4. companies
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS companies (
  id TEXT PRIMARY KEY,
  company_name TEXT NOT NULL,
  normalized_name TEXT NOT NULL UNIQUE,
  website TEXT,
  email_domain TEXT,
  linkedin_url TEXT,
  gst_number TEXT,
  cin_number TEXT,
  address TEXT,
  city TEXT,
  state TEXT,
  country TEXT DEFAULT 'IN',
  trust_score INTEGER CHECK (trust_score IS NULL OR (trust_score >= 0 AND trust_score <= 100)),
  danger_score INTEGER NOT NULL DEFAULT 0 CHECK (danger_score >= 0 AND danger_score <= 100),
  total_reports INTEGER NOT NULL DEFAULT 0 CHECK (total_reports >= 0),
  verified_status TEXT NOT NULL DEFAULT 'unverified'
    CHECK (verified_status IN ('unverified', 'pending', 'verified', 'flagged')),
  mca_verified INTEGER NOT NULL DEFAULT 0,
  gst_verified INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  deleted_at TEXT,
  CHECK (length(trim(company_name)) > 0)
);

-- ---------------------------------------------------------------------------
-- 5. blacklist_reports
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS blacklist_reports (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  company_id TEXT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  company_name TEXT NOT NULL,
  normalized_company TEXT NOT NULL,
  report_type TEXT NOT NULL,
  fraud_type TEXT NOT NULL,
  title TEXT,
  description TEXT NOT NULL CHECK (length(trim(description)) >= 10),
  amount_lost REAL CHECK (amount_lost IS NULL OR amount_lost >= 0),
  severity INTEGER NOT NULL DEFAULT 3 CHECK (severity BETWEEN 1 AND 5),
  evidence_count INTEGER NOT NULL DEFAULT 0 CHECK (evidence_count >= 0),
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'reviewed', 'verified', 'rejected')),
  college TEXT,
  evidence_file_id TEXT REFERENCES uploaded_files(id) ON DELETE SET NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  deleted_at TEXT,
  CHECK (length(trim(company_name)) > 0)
);

-- ---------------------------------------------------------------------------
-- 6. report_evidence
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS report_evidence (
  id TEXT PRIMARY KEY,
  report_id TEXT NOT NULL REFERENCES blacklist_reports(id) ON DELETE CASCADE,
  file_id TEXT NOT NULL REFERENCES uploaded_files(id) ON DELETE CASCADE,
  evidence_type TEXT NOT NULL DEFAULT 'document'
    CHECK (evidence_type IN ('document', 'screenshot', 'email', 'chat', 'payment', 'other')),
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE (report_id, file_id)
);

-- ---------------------------------------------------------------------------
-- 7. verification_results
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS verification_results (
  id TEXT PRIMARY KEY,
  company_id TEXT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  mca_status TEXT NOT NULL DEFAULT 'unknown'
    CHECK (mca_status IN ('unknown', 'active', 'inactive', 'not_found')),
  gst_status TEXT NOT NULL DEFAULT 'unknown'
    CHECK (gst_status IN ('unknown', 'valid', 'invalid', 'not_found')),
  complaint_count INTEGER NOT NULL DEFAULT 0 CHECK (complaint_count >= 0),
  website_age_days INTEGER,
  employee_estimate INTEGER,
  address_verified INTEGER NOT NULL DEFAULT 0 CHECK (address_verified IN (0, 1)),
  trust_score INTEGER CHECK (trust_score IS NULL OR (trust_score >= 0 AND trust_score <= 100)),
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ---------------------------------------------------------------------------
-- 8. fraud_patterns (global reference)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fraud_patterns (
  id TEXT PRIMARY KEY,
  pattern_name TEXT NOT NULL UNIQUE,
  pattern_type TEXT NOT NULL
    CHECK (pattern_type IN ('offer', 'interview', 'payment', 'data_theft', 'impersonation', 'other')),
  keywords TEXT NOT NULL,
  severity INTEGER NOT NULL DEFAULT 3 CHECK (severity BETWEEN 1 AND 5),
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ---------------------------------------------------------------------------
-- 9. resumes
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS resumes (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  file_id TEXT NOT NULL REFERENCES uploaded_files(id) ON DELETE CASCADE,
  extracted_text TEXT,
  safety_score INTEGER CHECK (safety_score IS NULL OR (safety_score >= 0 AND safety_score <= 100)),
  risk_level TEXT NOT NULL DEFAULT 'unknown'
    CHECK (risk_level IN ('unknown', 'low', 'medium', 'high', 'critical')),
  scan_status TEXT NOT NULL DEFAULT 'pending'
    CHECK (scan_status IN ('pending', 'processing', 'pending_analysis', 'completed', 'failed')),
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  deleted_at TEXT
);

-- ---------------------------------------------------------------------------
-- 10. offer_checks (before scans — scans references offer_checks)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS offer_checks (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  uploaded_file_id TEXT REFERENCES uploaded_files(id) ON DELETE SET NULL,
  file_id TEXT REFERENCES uploaded_files(id) ON DELETE SET NULL,
  offer_text TEXT,
  text_content TEXT,
  result TEXT NOT NULL DEFAULT 'pending_analysis',
  status TEXT NOT NULL DEFAULT 'pending_analysis',
  confidence_score INTEGER CHECK (confidence_score IS NULL OR (confidence_score >= 0 AND confidence_score <= 100)),
  confidence INTEGER,
  risk_level TEXT CHECK (risk_level IS NULL OR risk_level IN ('low', 'medium', 'high', 'critical', 'unknown')),
  analysis_summary TEXT,
  summary TEXT,
  reasons_json TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  completed_at TEXT
);

-- ---------------------------------------------------------------------------
-- 11. scans
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS scans (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  scan_type TEXT NOT NULL
    CHECK (scan_type IN ('resume', 'offer', 'company', 'data_safety', 'general')),
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'processing', 'pending_analysis', 'completed', 'failed')),
  risk_level TEXT,
  result_json TEXT,
  error_message TEXT,
  resume_id TEXT REFERENCES resumes(id) ON DELETE SET NULL,
  offer_check_id TEXT REFERENCES offer_checks(id) ON DELETE SET NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  completed_at TEXT
);

-- ---------------------------------------------------------------------------
-- 12. scan_findings
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS scan_findings (
  id TEXT PRIMARY KEY,
  resume_id TEXT NOT NULL REFERENCES resumes(id) ON DELETE CASCADE,
  scan_id TEXT REFERENCES scans(id) ON DELETE SET NULL,
  finding_type TEXT NOT NULL,
  finding_value TEXT NOT NULL,
  risk_level TEXT NOT NULL DEFAULT 'medium'
    CHECK (risk_level IN ('low', 'medium', 'high', 'critical')),
  recommendation TEXT,
  page_number INTEGER CHECK (page_number IS NULL OR page_number > 0),
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ---------------------------------------------------------------------------
-- 13. company_searches
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS company_searches (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  company_id TEXT REFERENCES companies(id) ON DELETE SET NULL,
  search_query TEXT NOT NULL,
  query TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ---------------------------------------------------------------------------
-- 14. notifications
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS notifications (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  body TEXT,
  type TEXT NOT NULL DEFAULT 'info'
    CHECK (type IN ('info', 'alert', 'scan', 'report', 'system')),
  is_read INTEGER NOT NULL DEFAULT 0 CHECK (is_read IN (0, 1)),
  read INTEGER NOT NULL DEFAULT 0 CHECK (read IN (0, 1)),
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ---------------------------------------------------------------------------
-- 15. activity_logs
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS activity_logs (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  action_type TEXT NOT NULL,
  activity_type TEXT,
  target_id TEXT,
  target_type TEXT,
  title TEXT NOT NULL,
  subtitle TEXT,
  result_label TEXT,
  metadata_json TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ---------------------------------------------------------------------------
-- 16. saved_reports
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS saved_reports (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  report_type TEXT NOT NULL
    CHECK (report_type IN ('blacklist', 'company', 'resume', 'offer', 'scan')),
  reference_id TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE (user_id, report_type, reference_id)
);

-- ---------------------------------------------------------------------------
-- data_safety_checks (app feature — persisted in D1)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS data_safety_checks (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  stage TEXT NOT NULL,
  requested_json TEXT NOT NULL,
  result_json TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ---------------------------------------------------------------------------
-- Triggers: recompute company danger/trust on report changes
-- ---------------------------------------------------------------------------
CREATE TRIGGER IF NOT EXISTS trg_blacklist_after_insert
AFTER INSERT ON blacklist_reports
WHEN NEW.deleted_at IS NULL
BEGIN
  UPDATE companies
  SET
    total_reports = (
      SELECT COUNT(*) FROM blacklist_reports
      WHERE company_id = NEW.company_id AND deleted_at IS NULL
    ),
    danger_score = (
      SELECT MIN(100, MAX(0, CAST(
        (COUNT(*) * 8)
        + (COALESCE(AVG(severity), 3) * 12)
        + (SUM(CASE WHEN created_at > datetime('now', '-30 days') THEN 1 ELSE 0 END) * 5)
        + (SUM(evidence_count) * 2)
      AS INTEGER)))
      FROM blacklist_reports
      WHERE company_id = NEW.company_id AND deleted_at IS NULL
    ),
    trust_score = MAX(0, 100 - (
      SELECT MIN(100, MAX(0, CAST(
        (COUNT(*) * 8)
        + (COALESCE(AVG(severity), 3) * 12)
        + (SUM(CASE WHEN created_at > datetime('now', '-30 days') THEN 1 ELSE 0 END) * 5)
        + (SUM(evidence_count) * 2)
      AS INTEGER)))
      FROM blacklist_reports
      WHERE company_id = NEW.company_id AND deleted_at IS NULL
    )),
    updated_at = datetime('now')
  WHERE id = NEW.company_id;
END;

CREATE TRIGGER IF NOT EXISTS trg_blacklist_after_update
AFTER UPDATE ON blacklist_reports
BEGIN
  UPDATE companies
  SET
    total_reports = (
      SELECT COUNT(*) FROM blacklist_reports
      WHERE company_id = NEW.company_id AND deleted_at IS NULL
    ),
    danger_score = (
      SELECT MIN(100, MAX(0, CAST(
        (COUNT(*) * 8)
        + (COALESCE(AVG(severity), 3) * 12)
        + (SUM(CASE WHEN created_at > datetime('now', '-30 days') THEN 1 ELSE 0 END) * 5)
        + (SUM(evidence_count) * 2)
      AS INTEGER)))
      FROM blacklist_reports
      WHERE company_id = NEW.company_id AND deleted_at IS NULL
    ),
    trust_score = MAX(0, 100 - (
      SELECT MIN(100, MAX(0, CAST(
        (COUNT(*) * 8)
        + (COALESCE(AVG(severity), 3) * 12)
        + (SUM(CASE WHEN created_at > datetime('now', '-30 days') THEN 1 ELSE 0 END) * 5)
        + (SUM(evidence_count) * 2)
      AS INTEGER)))
      FROM blacklist_reports
      WHERE company_id = NEW.company_id AND deleted_at IS NULL
    )),
    updated_at = datetime('now')
  WHERE id = NEW.company_id;
END;

CREATE TRIGGER IF NOT EXISTS trg_report_evidence_after_insert
AFTER INSERT ON report_evidence
BEGIN
  UPDATE blacklist_reports
  SET evidence_count = (
    SELECT COUNT(*) FROM report_evidence WHERE report_id = NEW.report_id
  ),
  updated_at = datetime('now')
  WHERE id = NEW.report_id;
END;

INSERT OR IGNORE INTO schema_migrations (version) VALUES ('0001_schema');

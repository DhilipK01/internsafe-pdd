-- Share settings, analytics, and soft-delete support
PRAGMA foreign_keys = ON;

ALTER TABLE shared_links ADD COLUMN visibility TEXT NOT NULL DEFAULT 'public';
ALTER TABLE shared_links ADD COLUMN is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1));

ALTER TABLE activity_logs ADD COLUMN deleted_at TEXT;
ALTER TABLE scans ADD COLUMN deleted_at TEXT;
ALTER TABLE offer_checks ADD COLUMN deleted_at TEXT;
ALTER TABLE data_safety_checks ADD COLUMN deleted_at TEXT;

CREATE TABLE IF NOT EXISTS share_analytics (
  id TEXT PRIMARY KEY,
  share_id TEXT NOT NULL REFERENCES shared_links(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  event_type TEXT NOT NULL CHECK (event_type IN ('created', 'opened', 'revoked', 'copied')),
  device_type TEXT,
  platform TEXT,
  user_agent TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_share_analytics_share
  ON share_analytics (share_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_share_analytics_token
  ON share_analytics (token, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_activity_not_deleted
  ON activity_logs (user_id, created_at DESC)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_scans_not_deleted
  ON scans (user_id, created_at DESC)
  WHERE deleted_at IS NULL;

INSERT OR IGNORE INTO schema_migrations (version) VALUES ('0006_share_delete_system');

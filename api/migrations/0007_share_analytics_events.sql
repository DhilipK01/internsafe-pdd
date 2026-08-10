-- Relax share_analytics event_type for web/app analytics (SQLite: recreate table)
PRAGMA foreign_keys = OFF;

CREATE TABLE IF NOT EXISTS share_analytics_new (
  id TEXT PRIMARY KEY,
  share_id TEXT NOT NULL REFERENCES shared_links(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  event_type TEXT NOT NULL,
  device_type TEXT,
  platform TEXT,
  user_agent TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

INSERT OR IGNORE INTO share_analytics_new
  SELECT id, share_id, token, event_type, device_type, platform, user_agent, created_at
  FROM share_analytics;

DROP TABLE IF EXISTS share_analytics;
ALTER TABLE share_analytics_new RENAME TO share_analytics;

CREATE INDEX IF NOT EXISTS idx_share_analytics_share
  ON share_analytics (share_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_share_analytics_token
  ON share_analytics (token, created_at DESC);

PRAGMA foreign_keys = ON;

INSERT OR IGNORE INTO schema_migrations (version) VALUES ('0007_share_analytics_events');

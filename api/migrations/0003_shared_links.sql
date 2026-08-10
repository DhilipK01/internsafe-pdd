-- Public share links for in-app deep linking (Option A: Worker hostname)
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS shared_links (
  id TEXT PRIMARY KEY,
  token TEXT NOT NULL UNIQUE,
  resource_type TEXT NOT NULL
    CHECK (resource_type IN ('offer_check', 'company_verify', 'scan', 'blacklist')),
  resource_id TEXT,
  created_by TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  snapshot_json TEXT NOT NULL,
  expires_at TEXT NOT NULL,
  view_count INTEGER NOT NULL DEFAULT 0 CHECK (view_count >= 0),
  revoked_at TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_shared_links_token_active
  ON shared_links (token)
  WHERE revoked_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_shared_links_created_by
  ON shared_links (created_by, created_at DESC);

INSERT OR IGNORE INTO schema_migrations (version) VALUES ('0003_shared_links');

-- AI intelligence tables: embeddings, jobs, assistant, clusters

CREATE TABLE IF NOT EXISTS ai_processing_jobs (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  job_type TEXT NOT NULL
    CHECK (job_type IN ('resume', 'offer', 'company', 'data_safety', 'cluster')),
  reference_id TEXT NOT NULL,
  scan_id TEXT,
  status TEXT NOT NULL DEFAULT 'queued'
    CHECK (status IN ('queued', 'processing', 'completed', 'failed')),
  celery_task_id TEXT,
  error_message TEXT,
  started_at TEXT,
  completed_at TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS content_embeddings (
  id TEXT PRIMARY KEY,
  source_type TEXT NOT NULL
    CHECK (source_type IN ('resume', 'offer', 'report', 'company', 'message')),
  source_id TEXT NOT NULL,
  user_id TEXT REFERENCES users(id) ON DELETE SET NULL,
  text_snippet TEXT,
  embedding_json TEXT NOT NULL,
  model_name TEXT NOT NULL DEFAULT 'all-MiniLM-L6-v2',
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_embeddings_source ON content_embeddings(source_type, source_id);

CREATE TABLE IF NOT EXISTS fraud_campaign_clusters (
  id TEXT PRIMARY KEY,
  cluster_type TEXT NOT NULL,
  cluster_key TEXT NOT NULL,
  report_ids_json TEXT NOT NULL,
  cluster_size INTEGER NOT NULL DEFAULT 0,
  campaign_risk TEXT NOT NULL DEFAULT 'medium',
  metadata_json TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS assistant_sessions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  context_json TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS assistant_messages (
  id TEXT PRIMARY KEY,
  session_id TEXT NOT NULL REFERENCES assistant_sessions(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
  content TEXT NOT NULL,
  metadata_json TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS ai_processing_logs (
  id TEXT PRIMARY KEY,
  job_id TEXT REFERENCES ai_processing_jobs(id) ON DELETE SET NULL,
  level TEXT NOT NULL DEFAULT 'info',
  message TEXT NOT NULL,
  details_json TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Extend resumes with AI recommendation blob
-- SQLite: add column if not exists via new migration pattern
ALTER TABLE resumes ADD COLUMN ai_recommendation_json TEXT;
ALTER TABLE resumes ADD COLUMN extracted_text_confidence REAL;
ALTER TABLE offer_checks ADD COLUMN ai_recommendation_json TEXT;
ALTER TABLE offer_checks ADD COLUMN extracted_text TEXT;
ALTER TABLE offer_checks ADD COLUMN embedding_json TEXT;

INSERT OR IGNORE INTO schema_migrations (version) VALUES ('0004_ai_intelligence');

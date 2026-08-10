-- Store file bytes when R2 is unavailable (preview + AI fallback), max ~3MB enforced in API.
ALTER TABLE uploaded_files ADD COLUMN content_base64 TEXT;

INSERT OR IGNORE INTO schema_migrations (version) VALUES ('0005_file_content');

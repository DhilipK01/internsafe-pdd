-- Rollback production schema (destructive — drops all application tables)

DELETE FROM schema_migrations WHERE version IN ('0001_schema', '0002_indexes');

DROP TRIGGER IF EXISTS trg_report_evidence_after_insert;
DROP TRIGGER IF EXISTS trg_blacklist_after_update;
DROP TRIGGER IF EXISTS trg_blacklist_after_insert;

DROP TABLE IF EXISTS data_safety_checks;
DROP TABLE IF EXISTS saved_reports;
DROP TABLE IF EXISTS activity_logs;
DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS company_searches;
DROP TABLE IF EXISTS scan_findings;
DROP TABLE IF EXISTS scans;
DROP TABLE IF EXISTS offer_checks;
DROP TABLE IF EXISTS resumes;
DROP TABLE IF EXISTS fraud_patterns;
DROP TABLE IF EXISTS verification_results;
DROP TABLE IF EXISTS report_evidence;
DROP TABLE IF EXISTS blacklist_reports;
DROP TABLE IF EXISTS companies;
DROP TABLE IF EXISTS uploaded_files;
DROP TABLE IF EXISTS user_settings;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS schema_migrations;

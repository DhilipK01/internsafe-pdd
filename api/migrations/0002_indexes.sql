-- INTERNSAFE search & filter indexes

-- users
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_created ON users(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_users_active ON users(is_active) WHERE deleted_at IS NULL;

-- companies
CREATE INDEX IF NOT EXISTS idx_companies_name ON companies(company_name COLLATE NOCASE);
CREATE INDEX IF NOT EXISTS idx_companies_normalized ON companies(normalized_name);
CREATE INDEX IF NOT EXISTS idx_companies_trust ON companies(trust_score);
CREATE INDEX IF NOT EXISTS idx_companies_danger ON companies(danger_score DESC);
CREATE INDEX IF NOT EXISTS idx_companies_reports ON companies(total_reports DESC);
CREATE INDEX IF NOT EXISTS idx_companies_city ON companies(city);
CREATE INDEX IF NOT EXISTS idx_companies_status ON companies(verified_status);

-- blacklist_reports
CREATE INDEX IF NOT EXISTS idx_blacklist_user ON blacklist_reports(user_id);
CREATE INDEX IF NOT EXISTS idx_blacklist_company ON blacklist_reports(company_id);
CREATE INDEX IF NOT EXISTS idx_blacklist_normalized ON blacklist_reports(normalized_company);
CREATE INDEX IF NOT EXISTS idx_blacklist_type ON blacklist_reports(report_type);
CREATE INDEX IF NOT EXISTS idx_blacklist_status ON blacklist_reports(status);
CREATE INDEX IF NOT EXISTS idx_blacklist_severity ON blacklist_reports(severity DESC);
CREATE INDEX IF NOT EXISTS idx_blacklist_created ON blacklist_reports(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_blacklist_user_company ON blacklist_reports(user_id, company_id);

-- uploaded_files
CREATE INDEX IF NOT EXISTS idx_files_user ON uploaded_files(user_id);
CREATE INDEX IF NOT EXISTS idx_files_status ON uploaded_files(upload_status);
CREATE INDEX IF NOT EXISTS idx_files_created ON uploaded_files(created_at DESC);

-- resumes
CREATE INDEX IF NOT EXISTS idx_resumes_user ON resumes(user_id);
CREATE INDEX IF NOT EXISTS idx_resumes_risk ON resumes(risk_level);
CREATE INDEX IF NOT EXISTS idx_resumes_status ON resumes(scan_status);
CREATE INDEX IF NOT EXISTS idx_resumes_created ON resumes(created_at DESC);

-- scan_findings
CREATE INDEX IF NOT EXISTS idx_findings_resume ON scan_findings(resume_id);
CREATE INDEX IF NOT EXISTS idx_findings_risk ON scan_findings(risk_level);
CREATE INDEX IF NOT EXISTS idx_findings_type ON scan_findings(finding_type);

-- scans
CREATE INDEX IF NOT EXISTS idx_scans_user ON scans(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_scans_type ON scans(scan_type);
CREATE INDEX IF NOT EXISTS idx_scans_status ON scans(status);
CREATE INDEX IF NOT EXISTS idx_scans_risk ON scans(risk_level);

-- offer_checks
CREATE INDEX IF NOT EXISTS idx_offers_user ON offer_checks(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_offers_status ON offer_checks(status);
CREATE INDEX IF NOT EXISTS idx_offers_risk ON offer_checks(risk_level);

-- company_searches
CREATE INDEX IF NOT EXISTS idx_searches_user ON company_searches(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_searches_query ON company_searches(search_query COLLATE NOCASE);
CREATE INDEX IF NOT EXISTS idx_searches_company ON company_searches(company_id);

-- notifications
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(user_id, is_read);

-- activity_logs
CREATE INDEX IF NOT EXISTS idx_activity_user ON activity_logs(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activity_type ON activity_logs(action_type);
CREATE INDEX IF NOT EXISTS idx_activity_target ON activity_logs(target_type, target_id);

-- saved_reports
CREATE INDEX IF NOT EXISTS idx_saved_user ON saved_reports(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_saved_type ON saved_reports(report_type);

-- verification_results
CREATE INDEX IF NOT EXISTS idx_verification_company ON verification_results(company_id, created_at DESC);

-- report_evidence
CREATE INDEX IF NOT EXISTS idx_evidence_report ON report_evidence(report_id);

-- fraud_patterns
CREATE INDEX IF NOT EXISTS idx_fraud_type ON fraud_patterns(pattern_type);
CREATE INDEX IF NOT EXISTS idx_fraud_severity ON fraud_patterns(severity DESC);

-- data_safety_checks
CREATE INDEX IF NOT EXISTS idx_data_safety_user ON data_safety_checks(user_id, created_at DESC);

INSERT OR IGNORE INTO schema_migrations (version) VALUES ('0002_indexes');

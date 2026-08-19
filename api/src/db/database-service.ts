import { DbClient } from './client';
import { aggregateCompanyRisk, calcDangerScore, calcTrustScore } from './danger-score';
import { normalizeCompany, uuid } from '../utils';

export type AuthUserRow = {
  id: string;
  email: string;
  name: string;
  college?: string;
};

export class DatabaseService {
  private readonly db: DbClient;

  constructor(d1: D1Database) {
    this.db = new DbClient(d1);
  }

  // --- Users ---
  async findUserByEmail(email: string) {
    return this.db.first<{
      id: string;
      email: string;
      name: string;
      college_name: string | null;
      password_hash: string | null;
    }>(
      this.db
        .prepare(
          `SELECT id, email, name, college_name, password_hash
           FROM users WHERE email = ? AND deleted_at IS NULL`,
        )
        .bind(email.trim().toLowerCase()),
    );
  }

  async findUserById(id: string): Promise<AuthUserRow | null> {
    const row = await this.db.first<{
      id: string;
      email: string;
      name: string;
      college_name: string | null;
    }>(
      this.db
        .prepare(
          `SELECT id, email, name, college_name FROM users
           WHERE id = ? AND deleted_at IS NULL`,
        )
        .bind(id),
    );
    if (!row) return null;
    return {
      id: row.id,
      email: row.email,
      name: row.name,
      college: row.college_name ?? undefined,
    };
  }

  async findUserByGoogle(sub: string, email: string) {
    return this.db.first<{
      id: string;
      email: string;
      name: string;
      college_name: string | null;
    }>(
      this.db
        .prepare(
          `SELECT id, email, name, college_name FROM users
           WHERE (google_sub = ? OR auth_uid = ? OR email = ?) AND deleted_at IS NULL`,
        )
        .bind(sub, sub, email.toLowerCase()),
    );
  }

  async createUser(params: {
    id: string;
    email: string;
    passwordHash?: string;
    name: string;
    college?: string;
    googleSub?: string;
    photoUrl?: string;
  }): Promise<void> {
    await this.db.run(
      this.db
        .prepare(
          `INSERT INTO users (
            id, email, password_hash, name, college_name,
            google_sub, auth_uid, photo_url, last_login
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, datetime('now'))`,
        )
        .bind(
          params.id,
          params.email.trim().toLowerCase(),
          params.passwordHash ?? null,
          params.name.trim(),
          params.college ?? null,
          params.googleSub ?? null,
          params.googleSub ?? null,
          params.photoUrl ?? null,
        ),
    );
    await this.createDefaultSettings(params.id);
  }

  async updateGoogleUser(
    id: string,
    sub: string,
    photoUrl: string | null,
  ): Promise<void> {
    await this.db.run(
      this.db
        .prepare(
          `UPDATE users SET
            google_sub = ?, auth_uid = ?,
            photo_url = COALESCE(photo_url, ?),
            last_login = datetime('now'),
            updated_at = datetime('now')
           WHERE id = ?`,
        )
        .bind(sub, sub, photoUrl, id),
    );
  }

  async touchLogin(id: string): Promise<void> {
    await this.db.run(
      this.db
        .prepare(
          `UPDATE users SET last_login = datetime('now'), updated_at = datetime('now') WHERE id = ?`,
        )
        .bind(id),
    );
  }

  async updateUserPassword(id: string, passwordHash: string): Promise<void> {
    await this.db.run(
      this.db
        .prepare(`UPDATE users SET password_hash = ?, updated_at = datetime('now') WHERE id = ?`)
        .bind(passwordHash, id),
    );
  }

  async getUserAuthVersion(userId: string): Promise<number> {
    try {
      const row = await this.db.first<{ auth_version: number }>(
        this.db
          .prepare(`SELECT COALESCE(auth_version, 0) AS auth_version FROM users WHERE id = ?`)
          .bind(userId),
      );
      return row?.auth_version ?? 0;
    } catch {
      return 0;
    }
  }

  async updateUserPassword(userId: string, passwordHash: string): Promise<void> {
    await this.db.run(
      this.db
        .prepare(
          `UPDATE users SET
            password_hash = ?,
            auth_version = COALESCE(auth_version, 0) + 1,
            updated_at = datetime('now')
           WHERE id = ?`,
        )
        .bind(passwordHash, userId),
    );
  }

  async countRecentPasswordResetRequests(
    email: string,
    withinMinutes: number,
  ): Promise<number> {
    const row = await this.db.first<{ c: number }>(
      this.db
        .prepare(
          `SELECT COUNT(*) AS c FROM password_reset_audit
           WHERE email = ? AND event_type = 'otp_requested'
           AND created_at > datetime('now', ?)`,
        )
        .bind(email, `-${withinMinutes} minutes`),
    );
    return row?.c ?? 0;
  }

  async invalidateActivePasswordResetOtps(userId: string): Promise<void> {
    await this.db.run(
      this.db
        .prepare(
          `UPDATE password_reset_otps SET used = 1
           WHERE user_id = ? AND used = 0`,
        )
        .bind(userId),
    );
  }

  async insertPasswordResetOtp(params: {
    id: string;
    userId: string;
    email: string;
    otpHash: string;
    otpSalt: string;
    expiresAt: string;
    ipAddress: string | null;
    userAgent: string | null;
  }): Promise<void> {
    await this.db.run(
      this.db
        .prepare(
          `INSERT INTO password_reset_otps (
            id, user_id, email, otp_hash, otp_salt, expires_at,
            ip_address, user_agent
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        )
        .bind(
          params.id,
          params.userId,
          params.email,
          params.otpHash,
          params.otpSalt,
          params.expiresAt,
          params.ipAddress,
          params.userAgent,
        ),
    );
  }

  async getPasswordResetOtp(id: string) {
    return this.db.first<{
      id: string;
      user_id: string;
      email: string;
      otp_hash: string;
      otp_salt: string;
      created_at: string;
      expires_at: string;
      verified: number;
      attempts: number;
      used: number;
    }>(
      this.db
        .prepare(`SELECT * FROM password_reset_otps WHERE id = ?`)
        .bind(id),
    );
  }

  async incrementPasswordResetAttempts(id: string): Promise<void> {
    await this.db.run(
      this.db
        .prepare(
          `UPDATE password_reset_otps SET attempts = attempts + 1 WHERE id = ?`,
        )
        .bind(id),
    );
  }

  async markPasswordResetOtpVerified(id: string): Promise<void> {
    await this.db.run(
      this.db
        .prepare(`UPDATE password_reset_otps SET verified = 1 WHERE id = ?`)
        .bind(id),
    );
  }

  async markPasswordResetOtpUsed(id: string): Promise<void> {
    await this.db.run(
      this.db
        .prepare(`UPDATE password_reset_otps SET used = 1 WHERE id = ?`)
        .bind(id),
    );
  }

  async insertPasswordResetAudit(params: {
    id: string;
    userId: string | null;
    email: string;
    eventType: string;
    ipAddress: string | null;
    userAgent: string | null;
    metadata?: string;
  }): Promise<void> {
    await this.db.run(
      this.db
        .prepare(
          `INSERT INTO password_reset_audit (
            id, user_id, email, event_type, ip_address, user_agent, metadata
          ) VALUES (?, ?, ?, ?, ?, ?, ?)`,
        )
        .bind(
          params.id,
          params.userId,
          params.email,
          params.eventType,
          params.ipAddress,
          params.userAgent,
          params.metadata ?? null,
        ),
    );
  }

  /** Create or link a user from Google Sign-In (handles email/password → Google linking). */
  async upsertGoogleUser(params: {
    id: string;
    sub: string;
    email: string;
    name: string;
    photoUrl?: string;
  }): Promise<{
    id: string;
    email: string;
    name: string;
    college_name: string | null;
  }> {
    const email = params.email.trim().toLowerCase();
    let user = await this.findUserByGoogle(params.sub, email);

    if (!user) {
      const byEmail = await this.findUserByEmail(email);
      if (byEmail) {
        user = {
          id: byEmail.id,
          email: byEmail.email,
          name: byEmail.name,
          college_name: byEmail.college_name,
        };
      }
    }

    if (user) {
      await this.updateGoogleUser(user.id, params.sub, params.photoUrl ?? null);
      await this.ensureDefaultSettings(user.id);
      return user;
    }

    try {
      await this.createUser({
        id: params.id,
        email,
        name: params.name,
        googleSub: params.sub,
        photoUrl: params.photoUrl,
      });
    } catch {
      user = await this.findUserByGoogle(params.sub, email);
      if (!user) {
        const byEmail = await this.findUserByEmail(email);
        if (!byEmail) throw new Error('GOOGLE_USER_UPSERT_FAILED');
        user = {
          id: byEmail.id,
          email: byEmail.email,
          name: byEmail.name,
          college_name: byEmail.college_name,
        };
        await this.updateGoogleUser(user.id, params.sub, params.photoUrl ?? null);
        await this.ensureDefaultSettings(user.id);
        return user;
      }
    }

    return {
      id: params.id,
      email,
      name: params.name.trim(),
      college_name: null,
    };
  }

  // --- Settings ---
  async ensureDefaultSettings(userId: string): Promise<void> {
    const existing = await this.db.first<{ id: string }>(
      this.db
        .prepare(`SELECT id FROM user_settings WHERE user_id = ? LIMIT 1`)
        .bind(userId),
    );
    if (existing) return;
    await this.createDefaultSettings(userId);
  }

  async createDefaultSettings(userId: string): Promise<void> {
    await this.db.run(
      this.db
        .prepare(`INSERT INTO user_settings (id, user_id) VALUES (?, ?)`)
        .bind(uuid(), userId),
    );
  }

  async getSettings(userId: string) {
    const row = await this.db.first<Record<string, unknown>>(
      this.db.prepare(`SELECT * FROM user_settings WHERE user_id = ?`).bind(userId),
    );
    if (!row) return null;
    return {
      ...row,
      theme_mode: row.theme_mode ?? 'system',
      notifications_enabled: row.notifications_enabled === 1,
      dark_mode: row.dark_mode === 1,
    };
  }

  async patchSettings(
    userId: string,
    patch: { themeMode?: string; notificationsEnabled?: boolean; darkMode?: boolean },
  ): Promise<void> {
    await this.db.run(
      this.db
        .prepare(
          `UPDATE user_settings SET
            theme_mode = COALESCE(?, theme_mode),
            notifications_enabled = COALESCE(?, notifications_enabled),
            dark_mode = COALESCE(?, dark_mode),
            updated_at = datetime('now')
           WHERE user_id = ?`,
        )
        .bind(
          patch.themeMode ?? null,
          patch.notificationsEnabled !== undefined
            ? patch.notificationsEnabled
              ? 1
              : 0
            : null,
          patch.darkMode !== undefined ? (patch.darkMode ? 1 : 0) : null,
          userId,
        ),
    );
  }

  // --- Companies ---
  async ensureCompany(companyName: string): Promise<{
    id: string;
    company_name: string;
    normalized_name: string;
  }> {
    const normalized = normalizeCompany(companyName);
    const existing = await this.db.first<{
      id: string;
      company_name: string;
      normalized_name: string;
    }>(
      this.db
        .prepare(`SELECT id, company_name, normalized_name FROM companies WHERE normalized_name = ?`)
        .bind(normalized),
    );
    if (existing) return existing;

    const id = uuid();
    await this.db.run(
      this.db
        .prepare(
          `INSERT INTO companies (id, company_name, normalized_name) VALUES (?, ?, ?)`,
        )
        .bind(id, companyName.trim(), normalized),
    );
    return { id, company_name: companyName.trim(), normalized_name: normalized };
  }

  async searchCompanies(query: string, limit = 20) {
    const like = `%${normalizeCompany(query)}%`;
    return this.db.all(
      this.db
        .prepare(
          `SELECT id, company_name, normalized_name, danger_score, trust_score, total_reports
           FROM companies
           WHERE normalized_name LIKE ? AND deleted_at IS NULL
           ORDER BY total_reports DESC, company_name ASC
           LIMIT ?`,
        )
        .bind(like, limit),
    );
  }

  async searchBlacklistCompanies(query: string, limit = 20) {
    const like = `%${normalizeCompany(query)}%`;
    return this.db.all(
      this.db
        .prepare(
          `SELECT DISTINCT company_name, normalized_company AS normalized_company
           FROM blacklist_reports
           WHERE normalized_company LIKE ? AND deleted_at IS NULL
           ORDER BY created_at DESC LIMIT ?`,
        )
        .bind(like, limit),
    );
  }

  async getCompanyVerification(companyId: string) {
    return this.db.first(
      this.db
        .prepare(
          `SELECT * FROM verification_results
           WHERE company_id = ? ORDER BY created_at DESC LIMIT 1`,
        )
        .bind(companyId),
    );
  }

  // --- Files ---
  async insertUploadedFile(params: {
    id: string;
    userId: string;
    storageKey: string;
    fileName: string;
    mimeType: string;
    fileSize: number;
    uploadType: string;
    contentBase64?: string | null;
  }): Promise<void> {
    const ext = params.fileName.includes('.')
      ? params.fileName.split('.').pop()!
      : 'bin';
    await this.db.run(
      this.db
        .prepare(
          `INSERT INTO uploaded_files (
            id, user_id, file_name, original_name, file_type, mime_type,
            file_size, r2_key, r2_url, public_url, upload_type, upload_status, content_base64
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'completed', ?)`,
        )
        .bind(
          params.id,
          params.userId,
          params.fileName,
          params.fileName,
          ext,
          params.mimeType,
          params.fileSize,
          params.storageKey,
          null,
          null,
          params.uploadType,
          params.contentBase64 ?? null,
        ),
    );
  }

  async getFileContentBase64(userId: string, fileId: string): Promise<string | null> {
    const row = await this.db.first<{ content_base64: string | null }>(
      this.db
        .prepare(
          `SELECT content_base64 FROM uploaded_files
           WHERE id = ? AND user_id = ? AND deleted_at IS NULL`,
        )
        .bind(fileId, userId),
    );
    return row?.content_base64 ?? null;
  }

  async listUserFiles(userId: string, uploadType?: string) {
    let sql = `SELECT id, file_name, mime_type, file_size, upload_type, public_url, r2_url, created_at,
                      CASE WHEN content_base64 IS NOT NULL OR r2_key LIKE ? THEN 1 ELSE 0 END AS has_content
               FROM uploaded_files WHERE user_id = ? AND deleted_at IS NULL`;
    const binds: (string | number)[] = [`${userId}/%`, userId];
    if (uploadType) {
      sql += ' AND upload_type = ?';
      binds.push(uploadType);
    }
    sql += ' ORDER BY created_at DESC LIMIT 50';
    return this.db.all(this.db.prepare(sql).bind(...binds));
  }

  async getUserFile(userId: string, fileId: string) {
    return this.db.first(
      this.db
        .prepare(
          `SELECT id FROM uploaded_files WHERE id = ? AND user_id = ? AND deleted_at IS NULL`,
        )
        .bind(fileId, userId),
    );
  }

  async getUserFileMeta(userId: string, fileId: string) {
    return this.db.first<{
      id: string;
      r2_key: string;
      mime_type: string;
      file_name: string;
      original_name: string;
      upload_type: string;
    }>(
      this.db
        .prepare(
          `SELECT id, r2_key, mime_type, file_name, original_name, upload_type
           FROM uploaded_files WHERE id = ? AND user_id = ? AND deleted_at IS NULL`,
        )
        .bind(fileId, userId),
    );
  }

  async updateScanStatus(
    scanId: string,
    status: string,
    extra?: { resultJson?: string; riskLevel?: string; errorMessage?: string },
  ): Promise<void> {
    const sets = ['status = ?', "updated_at = datetime('now')"];
    const binds: (string | number | null)[] = [status];
    if (extra?.resultJson !== undefined) {
      sets.push('result_json = ?');
      binds.push(extra.resultJson);
    }
    if (extra?.riskLevel !== undefined) {
      sets.push('risk_level = ?');
      binds.push(extra.riskLevel);
    }
    if (extra?.errorMessage !== undefined) {
      sets.push('error_message = ?');
      binds.push(extra.errorMessage);
    }
    if (status === 'completed' || status === 'failed') {
      sets.push("completed_at = datetime('now')");
    }
    binds.push(scanId);
    await this.db.run(
      this.db.prepare(`UPDATE scans SET ${sets.join(', ')} WHERE id = ?`).bind(...binds),
    );
  }

  async completeResumeAnalysis(params: {
    resumeId: string;
    scanId: string;
    userId: string;
    extractedText: string | null;
    safetyScore: number | null;
    riskLevel: string;
    resultJson: string;
    aiRecommendationJson: string | null;
    ocrConfidence: number | null;
    findings: Array<{
      finding_type: string;
      finding_value: string;
      risk_level: string;
      recommendation?: string;
    }>;
  }): Promise<void> {
    const statements = [
      this.db
        .prepare(
          `UPDATE resumes SET
            extracted_text = ?, safety_score = ?, risk_level = ?,
            scan_status = 'completed', ai_recommendation_json = ?,
            extracted_text_confidence = ?, updated_at = datetime('now')
           WHERE id = ? AND user_id = ?`,
        )
        .bind(
          params.extractedText,
          params.safetyScore,
          params.riskLevel,
          params.aiRecommendationJson,
          params.ocrConfidence,
          params.resumeId,
          params.userId,
        ),
      this.db
        .prepare(
          `UPDATE scans SET status = 'completed', risk_level = ?, result_json = ?,
           completed_at = datetime('now'), updated_at = datetime('now')
           WHERE id = ?`,
        )
        .bind(params.riskLevel, params.resultJson, params.scanId),
    ];
    for (const f of params.findings) {
      statements.push(
        this.db
          .prepare(
            `INSERT INTO scan_findings (
              id, resume_id, scan_id, finding_type, finding_value,
              risk_level, recommendation
            ) VALUES (?, ?, ?, ?, ?, ?, ?)`,
          )
          .bind(
            uuid(),
            params.resumeId,
            params.scanId,
            f.finding_type,
            f.finding_value,
            f.risk_level,
            f.recommendation ?? null,
          ),
      );
    }
    await this.db.batch(statements);
  }

  async failResumeAnalysis(
    resumeId: string,
    scanId: string,
    userId: string,
    error: string,
  ): Promise<void> {
    await this.db.batch([
      this.db
        .prepare(
          `UPDATE resumes SET scan_status = 'failed', updated_at = datetime('now') WHERE id = ? AND user_id = ?`,
        )
        .bind(resumeId, userId),
      this.db
        .prepare(
          `UPDATE scans SET status = 'failed', error_message = ?, updated_at = datetime('now'),
           completed_at = datetime('now') WHERE id = ?`,
        )
        .bind(error, scanId),
    ]);
  }

  async completeOfferAnalysis(params: {
    offerCheckId: string;
    userId: string;
    result: string;
    status: string;
    riskLevel: string;
    confidenceScore: number | null;
    summary: string;
    reasonsJson: string;
    extractedText: string | null;
    aiRecommendationJson: string | null;
    embeddingJson: string | null;
  }): Promise<void> {
    await this.db.run(
      this.db
        .prepare(
          `UPDATE offer_checks SET
            result = ?, status = ?, risk_level = ?, confidence_score = ?,
            analysis_summary = ?, summary = ?, reasons_json = ?,
            extracted_text = ?, ai_recommendation_json = ?, embedding_json = ?,
            completed_at = datetime('now'), updated_at = datetime('now')
           WHERE id = ? AND user_id = ?`,
        )
        .bind(
          params.result,
          params.status,
          params.riskLevel,
          params.confidenceScore,
          params.summary,
          params.summary,
          params.reasonsJson,
          params.extractedText,
          params.aiRecommendationJson,
          params.embeddingJson,
          params.offerCheckId,
          params.userId,
        ),
    );
  }

  async failOfferAnalysis(offerCheckId: string, error: string): Promise<void> {
    await this.db.run(
      this.db
        .prepare(
          `UPDATE offer_checks SET status = 'failed', result = 'failed',
           analysis_summary = ?, updated_at = datetime('now') WHERE id = ?`,
        )
        .bind(error.slice(0, 500), offerCheckId),
    );
  }

  async insertAiJob(params: {
    id: string;
    userId: string;
    jobType: string;
    referenceId: string;
    scanId?: string;
    celeryTaskId?: string;
  }): Promise<void> {
    await this.db.run(
      this.db
        .prepare(
          `INSERT INTO ai_processing_jobs (
            id, user_id, job_type, reference_id, scan_id, status, celery_task_id
          ) VALUES (?, ?, ?, ?, ?, 'queued', ?)`,
        )
        .bind(
          params.id,
          params.userId,
          params.jobType,
          params.referenceId,
          params.scanId ?? null,
          params.celeryTaskId ?? null,
        ),
    );
  }

  async storeEmbedding(params: {
    id: string;
    sourceType: string;
    sourceId: string;
    userId: string | null;
    textSnippet: string;
    embeddingJson: string;
  }): Promise<void> {
    await this.db.run(
      this.db
        .prepare(
          `INSERT INTO content_embeddings (
            id, source_type, source_id, user_id, text_snippet, embedding_json
          ) VALUES (?, ?, ?, ?, ?, ?)`,
        )
        .bind(
          params.id,
          params.sourceType,
          params.sourceId,
          params.userId,
          params.textSnippet.slice(0, 500),
          params.embeddingJson,
        ),
    );
  }

  async createNotification(
    userId: string,
    title: string,
    message: string,
    type: string = 'scan',
  ): Promise<void> {
    await this.db.run(
      this.db
        .prepare(
          `INSERT INTO notifications (id, user_id, title, message, body, type)
           VALUES (?, ?, ?, ?, ?, ?)`,
        )
        .bind(uuid(), userId, title, message, message, type),
    );
  }

  async markScanProcessing(scanId: string, resumeId: string): Promise<void> {
    await this.db.batch([
      this.db
        .prepare(`UPDATE scans SET status = 'processing', updated_at = datetime('now') WHERE id = ?`)
        .bind(scanId),
      this.db
        .prepare(
          `UPDATE resumes SET scan_status = 'processing', updated_at = datetime('now') WHERE id = ?`,
        )
        .bind(resumeId),
    ]);
  }

  async markOfferProcessing(offerId: string): Promise<void> {
    await this.db.run(
      this.db
        .prepare(
          `UPDATE offer_checks SET status = 'processing', updated_at = datetime('now') WHERE id = ?`,
        )
        .bind(offerId),
    );
  }

  // --- Resumes & scans ---
  async createResumeScan(
    userId: string,
    fileId: string,
    resultJson: string,
  ): Promise<{ resumeId: string; scanId: string }> {
    const resumeId = uuid();
    const scanId = uuid();
    await this.db.batch([
      this.db
        .prepare(
          `INSERT INTO resumes (id, user_id, file_id, scan_status) VALUES (?, ?, ?, 'pending_analysis')`,
        )
        .bind(resumeId, userId, fileId),
      this.db
        .prepare(
          `INSERT INTO scans (id, user_id, scan_type, status, resume_id, result_json)
           VALUES (?, ?, 'resume', 'pending_analysis', ?, ?)`,
        )
        .bind(scanId, userId, resumeId, resultJson),
    ]);
    return { resumeId, scanId };
  }

  async getActivityLog(userId: string, activityId: string) {
    return this.db.first(
      this.db
        .prepare(
          `SELECT * FROM activity_logs
           WHERE id = ? AND user_id = ?
             AND (deleted_at IS NULL OR deleted_at = '')`,
        )
        .bind(activityId, userId),
    );
  }

  async getScanFindingsForScan(userId: string, scanId: string) {
    return this.db.all(
      this.db
        .prepare(
          `SELECT sf.* FROM scan_findings sf
           INNER JOIN scans s ON s.id = sf.scan_id
           WHERE sf.scan_id = ? AND s.user_id = ?
           ORDER BY sf.risk_level DESC, sf.created_at ASC`,
        )
        .bind(scanId, userId),
    );
  }

  async getScan(userId: string, scanId: string) {
    return this.db.first(
      this.db
        .prepare(
          `SELECT * FROM scans WHERE id = ? AND user_id = ? AND deleted_at IS NULL`,
        )
        .bind(scanId, userId),
    );
  }

  /** Resolve scan by scan id or legacy activity target (resume_id). */
  async getScanForShare(userId: string, scanOrResumeId: string) {
    const direct = await this.getScan(userId, scanOrResumeId);
    if (direct) return direct;
    return this.db.first(
      this.db
        .prepare(
          `SELECT * FROM scans WHERE resume_id = ? AND user_id = ? AND deleted_at IS NULL
           ORDER BY created_at DESC LIMIT 1`,
        )
        .bind(scanOrResumeId, userId),
    );
  }

  // --- Offers ---
  async createOfferCheck(
    userId: string,
    text: string | null,
    fileId: string | null,
    summary: string,
  ): Promise<string> {
    const id = uuid();
    await this.db.run(
      this.db
        .prepare(
          `INSERT INTO offer_checks (
            id, user_id, uploaded_file_id, file_id, offer_text, text_content,
            result, status, analysis_summary, summary, reasons_json
          ) VALUES (?, ?, ?, ?, ?, ?, 'pending_analysis', 'pending_analysis', ?, ?, '[]')`,
        )
        .bind(id, userId, fileId, fileId, text, text, summary, summary),
    );
    return id;
  }

  async getOfferCheck(userId: string, id: string) {
    return this.db.first(
      this.db
        .prepare(
          `SELECT * FROM offer_checks WHERE id = ? AND user_id = ? AND deleted_at IS NULL`,
        )
        .bind(id, userId),
    );
  }

  async getDataSafetyCheck(userId: string, id: string) {
    return this.db.first(
      this.db
        .prepare(
          `SELECT * FROM data_safety_checks WHERE id = ? AND user_id = ? AND deleted_at IS NULL`,
        )
        .bind(id, userId),
    );
  }

  // --- Blacklist ---
  async hasRecentDuplicateReport(userId: string, companyId: string): Promise<boolean> {
    const row = await this.db.first<{ c: number }>(
      this.db
        .prepare(
          `SELECT COUNT(*) AS c FROM blacklist_reports
           WHERE user_id = ? AND company_id = ?
             AND deleted_at IS NULL
             AND created_at > datetime('now', '-1 day')`,
        )
        .bind(userId, companyId),
    );
    return (row?.c ?? 0) > 0;
  }

  async createBlacklistReport(params: {
    userId: string;
    companyName: string;
    reportType: string;
    description: string;
    college?: string;
    evidenceFileId?: string;
    title?: string;
    amountLost?: number;
  }): Promise<string> {
    const company = await this.ensureCompany(params.companyName);
    const dup = await this.hasRecentDuplicateReport(params.userId, company.id);
    if (dup) {
      throw new Error('DUPLICATE_REPORT');
    }

    const id = uuid();
    const normalized = normalizeCompany(params.companyName);
    const reportType = params.reportType.trim();

    await this.db.run(
      this.db
        .prepare(
          `INSERT INTO blacklist_reports (
            id, user_id, company_id, company_name, normalized_company,
            report_type, fraud_type, title, description, college,
            evidence_file_id, severity, evidence_count, status
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 3, 0, 'pending')`,
        )
        .bind(
          id,
          params.userId,
          company.id,
          params.companyName.trim(),
          normalized,
          reportType,
          reportType,
          params.title ?? `${reportType} report`,
          params.description.trim(),
          params.college ?? null,
          params.evidenceFileId ?? null,
        ),
    );

    if (params.evidenceFileId) {
      await this.db.run(
        this.db
          .prepare(
            `INSERT INTO report_evidence (id, report_id, file_id, evidence_type)
             VALUES (?, ?, ?, 'document')`,
          )
          .bind(uuid(), id, params.evidenceFileId),
      );
    }

    return id;
  }

  async searchBlacklist(normalizedQuery: string) {
    const terms = [
      normalizedQuery,
      ...normalizedQuery.split(/\s+/).filter((t) => t.length >= 2),
    ];
    const uniqueTerms = [...new Set(terms)];
    const clauses = uniqueTerms
      .map(
        () =>
          `(normalized_company LIKE ? OR lower(company_name) LIKE ? OR lower(COALESCE(title, '')) LIKE ?)`,
      )
      .join(' OR ');
    const binds = uniqueTerms.flatMap((t) => {
      const like = `%${t}%`;
      return [like, like, like];
    });

    const reports = await this.db.all(
      this.db
        .prepare(
          `SELECT * FROM blacklist_reports
           WHERE deleted_at IS NULL AND (${clauses})
           ORDER BY severity DESC, created_at DESC LIMIT 50`,
        )
        .bind(...binds),
    );

    const risk = await aggregateCompanyRisk(this.db.db, normalizedQuery);
    const stats = await this.db.first<{
      company_name: string;
    }>(
      this.db
        .prepare(
          `SELECT MAX(company_name) AS company_name FROM blacklist_reports
           WHERE deleted_at IS NULL AND (${clauses})`,
        )
        .bind(...binds),
    );

    const fraudTypes = await this.db.all<{ fraud_type: string }>(
      this.db
        .prepare(
          `SELECT DISTINCT fraud_type FROM blacklist_reports
           WHERE deleted_at IS NULL AND (${clauses})`,
        )
        .bind(...binds),
    );

    const colleges = await this.db.all<{ college: string; c: number }>(
      this.db
        .prepare(
          `SELECT college, COUNT(*) AS c FROM blacklist_reports
           WHERE deleted_at IS NULL AND college IS NOT NULL AND (${clauses})
           GROUP BY college ORDER BY c DESC LIMIT 5`,
        )
        .bind(...binds),
    );

    return { reports, risk, stats, fraudTypes, colleges };
  }

  async logCompanySearch(userId: string, query: string, companyId?: string) {
    await this.db.run(
      this.db
        .prepare(
          `INSERT INTO company_searches (id, user_id, company_id, search_query, query)
           VALUES (?, ?, ?, ?, ?)`,
        )
        .bind(uuid(), userId, companyId ?? null, query, query),
    );
  }

  async verifyCompany(companyName: string) {
    const normalized = normalizeCompany(companyName);
    const company = await this.ensureCompany(companyName);
    const risk = await aggregateCompanyRisk(this.db.db, normalized);

    const dangerScore = risk.dangerScore;
    const trustScore = calcTrustScore(dangerScore);

    await this.db.run(
      this.db
        .prepare(
          `UPDATE companies
           SET danger_score = ?, trust_score = ?, total_reports = ?, updated_at = datetime('now')
           WHERE id = ?`,
        )
        .bind(dangerScore, trustScore, risk.reportCount, company.id),
    );

    return {
      company,
      reportCount: risk.reportCount,
      dangerScore,
      trustScore,
    };
  }

  // --- Activity / dashboard / history ---
  async logActivity(
    userId: string,
    actionType: string,
    title: string,
    subtitle?: string,
    resultLabel?: string,
    targetId?: string,
    targetType?: string,
    metadata?: Record<string, unknown>,
  ): Promise<void> {
    await this.db.run(
      this.db
        .prepare(
          `INSERT INTO activity_logs (
            id, user_id, action_type, activity_type, target_id, target_type,
            title, subtitle, result_label, metadata_json
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        )
        .bind(
          uuid(),
          userId,
          actionType,
          actionType,
          targetId ?? null,
          targetType ?? null,
          title,
          subtitle ?? null,
          resultLabel ?? null,
          metadata ? JSON.stringify(metadata) : null,
        ),
    );
  }

  async getDashboard(userId: string) {
    const weekAgo = `datetime('now', '-7 days')`;
    const scans = await this.db.first<{ c: number }>(
      this.db
        .prepare(
          `SELECT COUNT(*) AS c FROM scans WHERE user_id = ? AND created_at > ${weekAgo}`,
        )
        .bind(userId),
    );
    const threats = await this.db.first<{ c: number }>(
      this.db
        .prepare(
          `SELECT COUNT(*) AS c FROM blacklist_reports WHERE user_id = ? AND created_at > ${weekAgo}`,
        )
        .bind(userId),
    );
    const activities = await this.db.all(
      this.db
        .prepare(
          `SELECT * FROM activity_logs WHERE user_id = ? ORDER BY created_at DESC LIMIT 10`,
        )
        .bind(userId),
    );
    return { scans, threats, activities };
  }

  async getHistory(
    userId: string,
    filters: { type?: string; from?: string; to?: string; q?: string },
  ) {
    let sql = `SELECT * FROM activity_logs WHERE user_id = ?`;
    const binds: (string | number)[] = [userId];
    if (filters.type) {
      sql += ' AND action_type = ?';
      binds.push(filters.type);
    }
    if (filters.q) {
      sql += ' AND (title LIKE ? OR subtitle LIKE ? OR metadata_json LIKE ?)';
      const like = `%${filters.q}%`;
      binds.push(like, like, like);
    }
    if (filters.from) {
      sql += ' AND created_at >= ?';
      binds.push(filters.from);
    }
    if (filters.to) {
      sql += ' AND created_at <= ?';
      binds.push(filters.to);
    }
    sql += ' AND deleted_at IS NULL ORDER BY created_at DESC LIMIT 100';
    return this.db.all(this.db.prepare(sql).bind(...binds));
  }

  async softDeleteActivity(userId: string, activityId: string): Promise<boolean> {
    const res = await this.db.run(
      this.db
        .prepare(
          `UPDATE activity_logs SET deleted_at = datetime('now')
           WHERE id = ? AND user_id = ? AND deleted_at IS NULL`,
        )
        .bind(activityId, userId),
    );
    return (res.meta.changes ?? 0) > 0;
  }

  async softDeleteScan(userId: string, scanId: string): Promise<boolean> {
    const res = await this.db.run(
      this.db
        .prepare(
          `UPDATE scans SET deleted_at = datetime('now'), updated_at = datetime('now')
           WHERE id = ? AND user_id = ? AND deleted_at IS NULL`,
        )
        .bind(scanId, userId),
    );
    return (res.meta.changes ?? 0) > 0;
  }

  async softDeleteOffer(userId: string, offerId: string): Promise<boolean> {
    const res = await this.db.run(
      this.db
        .prepare(
          `UPDATE offer_checks SET deleted_at = datetime('now'), updated_at = datetime('now')
           WHERE id = ? AND user_id = ? AND deleted_at IS NULL`,
        )
        .bind(offerId, userId),
    );
    return (res.meta.changes ?? 0) > 0;
  }

  async softDeleteDataSafety(userId: string, id: string): Promise<boolean> {
    const res = await this.db.run(
      this.db
        .prepare(
          `UPDATE data_safety_checks SET deleted_at = datetime('now')
           WHERE id = ? AND user_id = ? AND deleted_at IS NULL`,
        )
        .bind(id, userId),
    );
    return (res.meta.changes ?? 0) > 0;
  }

  async softDeleteUploadedFile(userId: string, fileId: string): Promise<{
    ok: boolean;
    r2Key?: string;
  }> {
    const row = await this.getUserFileMeta(userId, fileId);
    if (!row) return { ok: false };
    const res = await this.db.run(
      this.db
        .prepare(
          `UPDATE uploaded_files SET deleted_at = datetime('now')
           WHERE id = ? AND user_id = ? AND deleted_at IS NULL`,
        )
        .bind(fileId, userId),
    );
    return {
      ok: (res.meta.changes ?? 0) > 0,
      r2Key: row.r2_key,
    };
  }

  async softDeleteBlacklistReport(userId: string, reportId: string): Promise<boolean> {
    const res = await this.db.run(
      this.db
        .prepare(
          `UPDATE blacklist_reports SET deleted_at = datetime('now')
           WHERE id = ? AND user_id = ? AND deleted_at IS NULL`,
        )
        .bind(reportId, userId),
    );
    return (res.meta.changes ?? 0) > 0;
  }

  // --- Data safety ---
  async createDataSafetyCheck(
    userId: string,
    stage: string,
    requestedJson: string,
    resultJson: string,
  ): Promise<string> {
    const id = uuid();
    await this.db.run(
      this.db
        .prepare(
          `INSERT INTO data_safety_checks (id, user_id, stage, requested_json, result_json)
           VALUES (?, ?, ?, ?, ?)`,
        )
        .bind(id, userId, stage, requestedJson, resultJson),
    );
    return id;
  }

  async updateDataSafetyCheck(id: string, resultJson: string): Promise<void> {
    await this.db.run(
      this.db
        .prepare(`UPDATE data_safety_checks SET result_json = ? WHERE id = ?`)
        .bind(resultJson, id),
    );
  }

  // --- Share links ---
  async createSharedLink(params: {
    id: string;
    token: string;
    resourceType: string;
    resourceId: string | null;
    createdBy: string;
    snapshotJson: string;
    expiresAt: string;
    visibility?: string;
  }): Promise<void> {
    const binds = [
      params.id,
      params.token,
      params.resourceType,
      params.resourceId,
      params.createdBy,
      params.snapshotJson,
      params.expiresAt,
    ];
    try {
      await this.db.run(
        this.db
          .prepare(
            `INSERT INTO shared_links (
              id, token, resource_type, resource_id, created_by,
              snapshot_json, expires_at, visibility, is_active
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1)`,
          )
          .bind(...binds, params.visibility ?? 'public'),
      );
    } catch {
      await this.db.run(
        this.db
          .prepare(
            `INSERT INTO shared_links (
              id, token, resource_type, resource_id, created_by,
              snapshot_json, expires_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?)`,
          )
          .bind(...binds),
      );
    }
  }

  async logShareAnalytics(params: {
    id: string;
    shareId: string;
    token: string;
    eventType: string;
    deviceType?: string;
    platform?: string;
    userAgent?: string;
  }): Promise<void> {
    try {
      await this.db.run(
        this.db
          .prepare(
            `INSERT INTO share_analytics (
              id, share_id, token, event_type, device_type, platform, user_agent
            ) VALUES (?, ?, ?, ?, ?, ?, ?)`,
          )
          .bind(
            params.id,
            params.shareId,
            params.token,
            params.eventType,
            params.deviceType ?? null,
            params.platform ?? null,
            params.userAgent ?? null,
          ),
      );
    } catch {
      // analytics table may not exist until migration 0006
    }
  }

  async revokeSharesForResource(
    userId: string,
    resourceType: string,
    resourceId: string,
  ): Promise<void> {
    await this.db.run(
      this.db
        .prepare(
          `UPDATE shared_links
           SET revoked_at = datetime('now'), is_active = 0
           WHERE created_by = ? AND resource_type = ? AND resource_id = ?
             AND revoked_at IS NULL`,
        )
        .bind(userId, resourceType, resourceId),
    );
  }

  async getSharedLinkByToken(token: string) {
    return this.getSharedLinkPublic(token);
  }

  /** Public share resolution — includes owner + resource for hydration / file preview. */
  async getSharedLinkPublic(token: string) {
    try {
      return await this.db.first<{
        id: string;
        token: string;
        resource_type: string;
        resource_id: string | null;
        created_by: string;
        snapshot_json: string;
        expires_at: string;
        revoked_at: string | null;
        view_count: number;
        created_at: string;
        is_active: number;
      }>(
        this.db
          .prepare(
            `SELECT id, token, resource_type, resource_id, created_by, snapshot_json,
                    expires_at, revoked_at, view_count, created_at, is_active
             FROM shared_links WHERE token = ? AND is_active = 1`,
          )
          .bind(token),
      );
    } catch {
      return await this.db.first<{
        id: string;
        token: string;
        resource_type: string;
        resource_id: string | null;
        created_by: string;
        snapshot_json: string;
        expires_at: string;
        revoked_at: string | null;
        view_count: number;
        created_at: string;
        is_active: number;
      }>(
        this.db
          .prepare(
            `SELECT id, token, resource_type, resource_id, created_by, snapshot_json,
                    expires_at, revoked_at, view_count, created_at, 1 AS is_active
             FROM shared_links WHERE token = ?`,
          )
          .bind(token),
      );
    }
  }

  async getLatestScanForFile(userId: string, fileId: string) {
    return this.db.first<{ id: string; result_json: string | null }>(
      this.db
        .prepare(
          `SELECT s.id, s.result_json FROM scans s
           INNER JOIN resumes r ON r.id = s.resume_id
           WHERE r.file_id = ? AND s.user_id = ? AND s.deleted_at IS NULL
           ORDER BY s.created_at DESC LIMIT 1`,
        )
        .bind(fileId, userId),
    );
  }

  async getLatestOfferCheckForFile(userId: string, fileId: string) {
    return this.db.first<{ id: string }>(
      this.db
        .prepare(
          `SELECT id FROM offer_checks
           WHERE user_id = ? AND deleted_at IS NULL
             AND (uploaded_file_id = ? OR file_id = ?)
           ORDER BY created_at DESC LIMIT 1`,
        )
        .bind(userId, fileId, fileId),
    );
  }

  async getResumeFileId(userId: string, resumeId: string): Promise<string | null> {
    const row = await this.db.first<{ file_id: string }>(
      this.db
        .prepare(
          `SELECT file_id FROM resumes WHERE id = ? AND user_id = ? AND deleted_at IS NULL`,
        )
        .bind(resumeId, userId),
    );
    return row?.file_id ?? null;
  }

  async getOfferCheckFileId(userId: string, offerId: string): Promise<string | null> {
    const row = await this.db.first<{
      uploaded_file_id: string | null;
      file_id: string | null;
    }>(
      this.db
        .prepare(
          `SELECT uploaded_file_id, file_id FROM offer_checks
           WHERE id = ? AND user_id = ? AND deleted_at IS NULL`,
        )
        .bind(offerId, userId),
    );
    return row?.uploaded_file_id ?? row?.file_id ?? null;
  }

  async getUploadedFilePreviewMeta(userId: string, fileId: string) {
    return this.db.first<{
      id: string;
      mime_type: string;
      file_name: string;
      original_name: string;
      upload_type: string;
      created_at: string;
      file_size: number | null;
      content_base64: string | null;
    }>(
      this.db
        .prepare(
          `SELECT id, mime_type, file_name, original_name, upload_type, created_at,
                  file_size, content_base64
           FROM uploaded_files WHERE id = ? AND user_id = ? AND deleted_at IS NULL`,
        )
        .bind(fileId, userId),
    );
  }

  async incrementShareViewCount(token: string): Promise<void> {
    await this.db.run(
      this.db
        .prepare(
          `UPDATE shared_links SET view_count = view_count + 1 WHERE token = ?`,
        )
        .bind(token),
    );
  }

  async revokeSharedLink(userId: string, token: string): Promise<boolean> {
    const row = await this.db.first<{ id: string }>(
      this.db
        .prepare(
          `SELECT id FROM shared_links
           WHERE token = ? AND created_by = ? AND revoked_at IS NULL`,
        )
        .bind(token, userId),
    );
    if (!row) return false;
    await this.db.run(
      this.db
        .prepare(
          `UPDATE shared_links SET revoked_at = datetime('now') WHERE token = ?`,
        )
        .bind(token),
    );
    return true;
  }
}

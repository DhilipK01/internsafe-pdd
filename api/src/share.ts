import type { DatabaseService } from './db/database-service';
import { renderPremiumSharePage } from './share-page';
import { formatIST } from './utils/ist';
import { normalizeCompany } from './utils';

export type ShareResourceType =
  | 'offer_check'
  | 'company_verify'
  | 'scan'
  | 'blacklist'
  | 'upload'
  | 'data_safety';

export type ShareVisibility = 'public' | 'private';
export type ShareExpiryOption = '24h' | '7d' | '14d' | 'never';

export type ShareEnv = {
  SHARE_HOST?: string;
  ANDROID_SHA256_FINGERPRINTS?: string;
  APPLE_TEAM_ID?: string;
  PLAY_STORE_URL?: string;
  APP_STORE_URL?: string;
  APK_DOWNLOAD_URL?: string;
};

const SENSITIVE_RESOURCE_TYPES = new Set<ShareResourceType>(['upload', 'scan']);

export function generateShareToken(): string {
  const bytes = new Uint8Array(24);
  crypto.getRandomValues(bytes);
  return [...bytes].map((b) => b.toString(16).padStart(2, '0')).join('');
}

export function shareHostFromRequest(request: Request, env: ShareEnv): string {
  if (env.SHARE_HOST?.trim()) return env.SHARE_HOST.trim();
  return new URL(request.url).host;
}

export function shareUrl(host: string, token: string): string {
  return `https://${host}/share/${token}`;
}

export function shareViewUrl(host: string, token: string): string {
  return shareUrl(host, token);
}

export function appDeepLink(token: string): string {
  return `internsafe://share/${token}`;
}

export function legacyAppDeepLink(token: string): string {
  return `internsafe://s/${token}`;
}

const SNAPSHOT_VERSION = 2;

export function maskEmail(email: string): string {
  const at = email.indexOf('@');
  if (at <= 1) return '•••@•••';
  const local = email.slice(0, at);
  const domain = email.slice(at + 1);
  const shown = local.slice(0, Math.min(2, local.length));
  return `${shown}•••@${domain}`;
}

export async function buildSharedBy(
  db: DatabaseService,
  userId: string,
): Promise<Record<string, unknown>> {
  const user = await db.findUserById(userId);
  if (!user) {
    return {
      name: 'INTERNSAFE user',
      emailMasked: null,
      college: null,
      verified: false,
      initials: 'IN',
    };
  }
  const parts = user.name.trim().split(/\s+/).filter(Boolean);
  const initials =
    parts.length >= 2
      ? `${parts[0][0] ?? ''}${parts[parts.length - 1][0] ?? ''}`.toUpperCase()
      : (parts[0]?.slice(0, 2) ?? 'IN').toUpperCase();
  return {
    name: user.name,
    emailMasked: maskEmail(user.email),
    college: user.college ?? null,
    verified: true,
    initials,
  };
}

function mapFindings(findings: unknown[]): Record<string, unknown>[] {
  return findings.slice(0, 40).map((raw) => {
    const f = raw as Record<string, unknown>;
    const message =
      f.message ??
      f.finding_value ??
      f.value ??
      f.description ??
      f.masked_value ??
      null;
    const severity = f.risk_level ?? f.risk ?? f.severity ?? 'medium';
    return {
      type: f.finding_type ?? f.type ?? 'finding',
      risk: severity,
      severity,
      message: message != null ? String(message) : 'Finding',
      confidence: f.confidence ?? f.confidence_score ?? null,
      value: message,
      recommendation: f.recommendation ?? f.suggestion ?? null,
      context: f.context ?? f.snippet ?? null,
      category: f.category ?? null,
    };
  });
}

function snapshotHasAnalysis(
  snapshot: Record<string, unknown>,
  type: string,
): boolean {
  if (type === 'scan') {
    return (
      snapshot.safetyScore != null ||
      snapshot.dangerScore != null ||
      (Array.isArray(snapshot.findings) && snapshot.findings.length > 0) ||
      snapshot.aiRecommendation != null
    );
  }
  if (type === 'offer_check') {
    const analysis = snapshot.analysis as Record<string, unknown> | undefined;
    return (
      analysis != null &&
      ((Array.isArray(analysis.reasons) && analysis.reasons.length > 0) ||
        analysis.fraudScore != null ||
        analysis.scamProbability != null)
    );
  }
  if (type === 'data_safety') {
    return snapshot.summary != null || snapshot.safeCount != null;
  }
  if (type === 'company_verify' || type === 'blacklist') {
    return snapshot.trustScore != null || snapshot.reportCount != null;
  }
  return false;
}

async function attachDocumentMeta(
  db: DatabaseService,
  userId: string,
  fileId: string | null,
): Promise<Record<string, unknown> | null> {
  if (!fileId) return null;
  const meta = await db.getUploadedFilePreviewMeta(userId, fileId);
  if (!meta) return null;
  const name = meta.original_name ?? meta.file_name ?? 'Document';
  const mime = meta.mime_type ?? 'application/octet-stream';
  const previewable =
    Boolean(meta.content_base64) &&
    (mime.startsWith('image/') ||
      mime === 'application/pdf' ||
      mime.startsWith('text/'));
  return {
    fileId: meta.id,
    fileName: name,
    mimeType: mime,
    uploadType: meta.upload_type,
    uploadedAt: meta.created_at,
    fileSize: meta.file_size,
    hasPreview: previewable,
  };
}

export function shareExpiresAt(option: ShareExpiryOption = '14d'): string {
  if (option === 'never') {
    const d = new Date();
    d.setUTCFullYear(d.getUTCFullYear() + 10);
    return d.toISOString();
  }
  const hours =
    option === '24h' ? 24 : option === '7d' ? 24 * 7 : 24 * 14;
  const d = new Date();
  d.setUTCHours(d.getUTCHours() + hours);
  return d.toISOString();
}

export function isShareExpired(expiresAt: string): boolean {
  return Date.parse(expiresAt) < Date.now();
}

function parseResultJson(raw: unknown): Record<string, unknown> | null {
  if (!raw) return null;
  if (typeof raw === 'object') return raw as Record<string, unknown>;
  if (typeof raw === 'string') {
    try {
      return JSON.parse(raw) as Record<string, unknown>;
    } catch {
      return null;
    }
  }
  return null;
}

function expandScanAnalysis(result: Record<string, unknown> | null) {
  if (!result) return {};
  const findings = (result.findings as unknown[]) ?? [];
  const aiRec = result.ai_recommendation as Record<string, unknown> | undefined;
  return {
    safetyScore: result.safety_score ?? null,
    dangerScore: result.danger_score ?? null,
    riskLevel: result.risk_level ?? 'unknown',
    verdict: result.verdict ?? aiRec?.verdict ?? null,
    findingCount: Array.isArray(findings) ? findings.length : 0,
    findings: Array.isArray(findings) ? mapFindings(findings) : [],
    recommendations: result.recommendations ?? result.action_items ?? [],
    aiRecommendation: aiRec
      ? {
          explanation: aiRec.explanation ?? aiRec.summary,
          verdict: aiRec.verdict,
          confidence: aiRec.confidence,
          actionItems: aiRec.action_items ?? aiRec.actions,
        }
      : null,
    explanation: aiRec?.explanation ?? result.message ?? null,
    entities: result.entities ?? result.detected_entities ?? [],
    scamIndicators: result.scam_indicators ?? result.red_flags ?? [],
  };
}

function expandOfferAnalysis(result: Record<string, unknown> | null) {
  if (!result) return {};
  const reasons = (result.reasons ?? result.red_flags ?? []) as unknown[];
  return {
    fraudScore: result.fraud_score ?? result.danger_score ?? result.scam_probability,
    scamProbability: result.scam_probability ?? result.fraud_score,
    riskLevel: result.risk_level ?? 'unknown',
    verdict: result.verdict ?? result.status,
    confidence: result.confidence ?? result.confidence_score,
    reasons: Array.isArray(reasons)
      ? reasons.slice(0, 30).map((r) => {
          const item = r as Record<string, unknown>;
          return {
            code: item.code ?? item.type,
            message: item.message ?? item.description ?? String(r),
            severity: item.severity ?? item.risk,
          };
        })
      : [],
    suspiciousPhrases: result.suspicious_phrases ?? result.flagged_phrases ?? [],
    paymentRequests: result.payment_requests ?? [],
    urgencySignals: result.urgency_signals ?? result.urgency_manipulation ?? [],
    recommendation: result.recommendation ?? result.summary,
    entities: result.entities ?? [],
  };
}

/** Rebuild full AI analysis from DB at view time (never serve metadata-only shares). */
export async function hydrateShareSnapshot(
  db: DatabaseService,
  createdBy: string,
  resourceType: string,
  resourceId: string | null,
  snapshot: Record<string, unknown>,
): Promise<Record<string, unknown>> {
  const type = String((snapshot.type as string) ?? resourceType);
  const rid =
    resourceId ??
    (snapshot.resourceId as string | undefined) ??
    (type === 'company_verify' || type === 'blacklist'
      ? (snapshot.companyName as string | undefined)
      : null) ??
    null;

  const complete =
    snapshot.version === SNAPSHOT_VERSION &&
    snapshot.sharedBy &&
    snapshotHasAnalysis(snapshot, type) &&
    type !== 'upload';

  if (complete) return snapshot;

  try {
    const shareType = type as ShareResourceType;
    const rebuilt = await buildShareSnapshot(db, createdBy, shareType, rid, {
      companyName:
        (snapshot.companyName as string) ??
        extrasCompanyName(resourceType, rid),
      query:
        (snapshot.query as string) ??
        (snapshot.companyName as string) ??
        rid ??
        undefined,
      confirmSensitive: true,
    });
    return {
      ...snapshot,
      ...rebuilt,
      version: SNAPSHOT_VERSION,
      sharedAt: (snapshot.sharedAt as string) ?? rebuilt.sharedAt,
      sharedAtIst: (snapshot.sharedAtIst as string) ?? rebuilt.sharedAtIst,
      sharedBy:
        (snapshot.sharedBy as Record<string, unknown> | undefined) ??
        rebuilt.sharedBy,
    };
  } catch {
    const sharedBy =
      (snapshot.sharedBy as Record<string, unknown> | undefined) ??
      (await buildSharedBy(db, createdBy));
    return { ...snapshot, version: snapshot.version ?? SNAPSHOT_VERSION, sharedBy };
  }
}

function extrasCompanyName(
  resourceType: string,
  resourceId: string | null,
): string | undefined {
  if (resourceType === 'company_verify' && resourceId) return resourceId;
  return undefined;
}

export async function buildShareSnapshot(
  db: DatabaseService,
  userId: string,
  resourceType: ShareResourceType,
  resourceId: string | null,
  extras?: {
    companyName?: string;
    query?: string;
    confirmSensitive?: boolean;
  },
): Promise<Record<string, unknown>> {
  if (SENSITIVE_RESOURCE_TYPES.has(resourceType) && !extras?.confirmSensitive) {
    throw new Error('SENSITIVE_CONFIRM_REQUIRED');
  }

  const sharedAt = new Date().toISOString();
  const sharedAtIst = formatIST(sharedAt);
  const sharedBy = await buildSharedBy(db, userId);
  const base = { version: SNAPSHOT_VERSION, sharedAt, sharedAtIst, sharedBy };

  switch (resourceType) {
    case 'offer_check': {
      if (!resourceId) throw new Error('RESOURCE_ID_REQUIRED');
      const row = await db.getOfferCheck(userId, resourceId);
      if (!row) throw new Error('NOT_FOUND');
      const r = row as Record<string, unknown>;
      const result = parseResultJson(r.result_json ?? r.result);
      const fileId = await db.getOfferCheckFileId(userId, resourceId);
      const document = await attachDocumentMeta(db, userId, fileId);
      const offerAnalysis = expandOfferAnalysis(result);
      return {
        ...base,
        type: 'offer_check',
        title: 'Offer letter fraud analysis',
        subtitle: 'AI internship offer intelligence',
        status: r.status ?? r.result ?? 'pending_analysis',
        riskLevel: r.risk_level ?? offerAnalysis.riskLevel ?? 'unknown',
        confidence: r.confidence_score ?? offerAnalysis.confidence ?? null,
        summary:
          (r.analysis_summary as string) ??
          (r.summary as string) ??
          (offerAnalysis.recommendation as string) ??
          (result?.summary as string) ??
          'Offer analysis result.',
        analysis: offerAnalysis,
        document,
        message:
          (offerAnalysis.recommendation as string) ??
          (r.analysis_summary as string) ??
          'Offer letter analysis shared securely.',
      };
    }
    case 'scan': {
      if (!resourceId) throw new Error('RESOURCE_ID_REQUIRED');
      const row = await db.getScanForShare(userId, resourceId);
      if (!row) throw new Error('NOT_FOUND');
      const r = row as Record<string, unknown>;
      const result = parseResultJson(r.result_json);
      let analysis = expandScanAnalysis(result);
      const scanId = r.id as string;
      const dbFindings = await db.getScanFindingsForScan(userId, scanId);
      if (dbFindings.length > 0 && !(analysis.findings as unknown[])?.length) {
        (analysis as Record<string, unknown>).findings = dbFindings.map((f) => {
          const row = f as Record<string, unknown>;
          return {
            type: row.finding_type,
            message: row.finding_value,
            severity: row.risk_level,
            recommendation: row.recommendation,
          };
        });
        (analysis as Record<string, unknown>).findingCount = dbFindings.length;
      }
      let fileId: string | null = null;
      const resumeId = r.resume_id as string | undefined;
      if (resumeId) fileId = await db.getResumeFileId(userId, resumeId);
      const document = await attachDocumentMeta(db, userId, fileId);
      return {
        ...base,
        type: 'scan',
        title:
          r.scan_type === 'offer'
            ? 'Offer document scan'
            : 'Resume safety intelligence',
        subtitle: 'AI document fraud detection',
        status: r.status ?? 'pending_analysis',
        scanType: r.scan_type ?? 'resume',
        ...analysis,
        document,
        message:
          (analysis.explanation as string) ??
          'Resume scan shared via INTERNSAFE.',
      };
    }
    case 'upload': {
      if (!resourceId) throw new Error('RESOURCE_ID_REQUIRED');
      const meta = await db.getUserFileMeta(userId, resourceId);
      if (!meta) throw new Error('NOT_FOUND');
      const document = await attachDocumentMeta(db, userId, resourceId);

      const offerRow = await db.getLatestOfferCheckForFile(userId, resourceId);
      if (offerRow?.id) {
        const offerSnap = await buildShareSnapshot(
          db,
          userId,
          'offer_check',
          offerRow.id,
          { confirmSensitive: true },
        );
        return {
          ...offerSnap,
          type: 'offer_check',
          document,
          title: 'Offer analysis & document',
          subtitle: 'AI internship offer intelligence',
        };
      }

      const scanRow = await db.getLatestScanForFile(userId, resourceId);
      if (scanRow?.id) {
        const scanSnap = await buildShareSnapshot(db, userId, 'scan', scanRow.id, {
          confirmSensitive: true,
        });
        const findings = await db.getScanFindingsForScan(userId, scanRow.id);
        if (findings.length > 0 && !(scanSnap.findings as unknown[])?.length) {
          (scanSnap as Record<string, unknown>).findings = findings.map((f) => {
            const row = f as Record<string, unknown>;
            return {
              type: row.finding_type,
              message: row.finding_value,
              severity: row.risk_level,
              recommendation: row.recommendation,
            };
          });
        }
        return {
          ...scanSnap,
          type: 'scan',
          document,
          title: 'Resume scan & document',
          subtitle: 'AI document fraud detection',
        };
      }

      return {
        ...base,
        type: 'upload',
        title: 'Shared document',
        subtitle: 'Secure document preview',
        fileName: meta.file_name ?? meta.original_name,
        mimeType: meta.mime_type,
        uploadType: meta.upload_type ?? 'general',
        document,
        message: 'Uploaded document shared securely via INTERNSAFE.',
      };
    }
    case 'data_safety': {
      if (!resourceId) throw new Error('RESOURCE_ID_REQUIRED');
      const row = await db.getDataSafetyCheck(userId, resourceId);
      if (!row) throw new Error('NOT_FOUND');
      const r = row as Record<string, unknown>;
      let result: Record<string, unknown> = {};
      try {
        result = JSON.parse((r.result_json as string) || '{}') as Record<
          string,
          unknown
        >;
      } catch {
        result = {};
      }
      const safeNow = (result.safe_now as unknown[]) ?? [];
      const shareLater = (result.share_later as unknown[]) ?? [];
      const neverShare = (result.never_share as unknown[]) ?? [];
      return {
        ...base,
        type: 'data_safety',
        title: 'Data safety intelligence',
        subtitle: 'What to share during internships',
        stage: r.stage,
        summary: result.recommendation_summary ?? 'Data safety analysis',
        safeCount: safeNow.length,
        laterCount: shareLater.length,
        neverCount: neverShare.length,
        safeNow,
        shareLater,
        neverShare,
        warnings: result.warnings ?? [],
        confidence: result.confidence ?? null,
        message: (result.recommendation_summary as string) ?? 'Data safety guidance',
      };
    }
    case 'company_verify': {
      const name = extras?.companyName?.trim() || resourceId;
      if (!name) throw new Error('COMPANY_NAME_REQUIRED');
      const { reportCount, dangerScore, trustScore } = await db.verifyCompany(name);
      const status =
        reportCount === 0
          ? 'no_data'
          : reportCount >= 5
            ? 'suspicious'
            : 'partial';
      return {
        ...base,
        type: 'company_verify',
        title: 'Company risk intelligence',
        subtitle: 'Community fraud intelligence',
        companyName: name,
        reportCount,
        trustScore,
        dangerScore,
        status,
        verdict:
          status === 'suspicious'
            ? 'Elevated community risk signals'
            : reportCount === 0
              ? 'No community reports on file'
              : 'Limited community intelligence',
        message:
          reportCount === 0
            ? 'No community reports in INTERNSAFE database.'
            : `Based on ${reportCount} community report(s) in INTERNSAFE.`,
      };
    }
    case 'blacklist': {
      const q = extras?.query?.trim() || resourceId;
      if (!q) throw new Error('QUERY_REQUIRED');
      const normalized = normalizeCompany(q);
      const { risk, stats } = await db.searchBlacklist(normalized);
      if (risk.reportCount === 0) throw new Error('NOT_FOUND');
      return {
        ...base,
        type: 'blacklist',
        title: 'Blacklist intelligence summary',
        subtitle: 'Community fraud reports',
        companyName:
          (stats as { company_name?: string } | undefined)?.company_name ?? q,
        dangerScore: risk.dangerScore,
        reportCount: risk.reportCount,
        verdict: 'Community fraud reports on file',
        message: `${risk.reportCount} community report(s) on file.`,
      };
    }
    default:
      throw new Error('INVALID_TYPE');
  }
}

export function sharePreviewHtml(
  host: string,
  token: string,
  snapshot: Record<string, unknown>,
  env: ShareEnv,
  options?: { documentPreviewUrl?: string },
): string {
  return renderPremiumSharePage(host, token, snapshot, env, options);
}


function escapeHtml(s: string): string {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

export function assetLinksJson(env: ShareEnv): string {
  const fingerprints = (env.ANDROID_SHA256_FINGERPRINTS ?? '')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);
  const payload =
    fingerprints.length === 0
      ? []
      : [
          {
            relation: ['delegate_permission/common.handle_all_urls'],
            target: {
              namespace: 'android_app',
              package_name: 'com.internsafe.internsfe',
              sha256_cert_fingerprints: fingerprints,
            },
          },
        ];
  return JSON.stringify(payload);
}

export function appleAppSiteAssociation(env: ShareEnv): string {
  const teamId = env.APPLE_TEAM_ID?.trim();
  if (!teamId) {
    return JSON.stringify({
      applinks: { apps: [], details: [] },
    });
  }
  return JSON.stringify({
    applinks: {
      apps: [],
      details: [
        {
          appID: `${teamId}.com.internsafe.internsfe`,
          paths: ['/share/*', '/s/*', '/view/*', '/report/*'],
        },
      ],
    },
  });
}

export function installPageHtml(host: string): string {
  return sharePreviewHtml(
    host,
    '',
    {
      title: 'Open in INTERNSAFE',
      message: 'Install the INTERNSAFE app to view shared internship safety results.',
    },
    {},
  );
}


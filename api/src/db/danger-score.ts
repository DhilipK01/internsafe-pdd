/**
 * Deterministic danger score from community signals (not random).
 * Used by API responses and kept in sync with SQL triggers on companies.
 */
export interface DangerScoreInput {
  reportCount: number;
  avgSeverity: number;
  recentReports: number;
  evidenceCount: number;
  complaintFrequency?: number;
}

export function calcDangerScore(input: DangerScoreInput): number {
  const {
    reportCount,
    avgSeverity,
    recentReports,
    evidenceCount,
    complaintFrequency = 0,
  } = input;

  if (reportCount <= 0) return 0;

  const severityFactor = Math.min(5, Math.max(1, avgSeverity)) * 12;
  const volumeFactor = Math.min(50, reportCount) * 8;
  const recencyFactor = Math.min(20, recentReports) * 5;
  const evidenceFactor = Math.min(15, evidenceCount) * 2;
  const frequencyFactor = Math.min(10, complaintFrequency) * 3;

  const raw =
    volumeFactor + severityFactor + recencyFactor + evidenceFactor + frequencyFactor;

  return Math.round(Math.min(100, Math.max(0, raw)));
}

export function calcTrustScore(dangerScore: number): number {
  return Math.max(0, 100 - dangerScore);
}

/** Dynamic trust when AI service is offline — never return static 50. */
export function computeCompanyTrustScore(input: {
  reportCount: number;
  dangerScore: number;
  webTrust?: number | null;
  webComplaints?: number;
  snippetCount?: number;
  positiveMentions?: number;
  hiringMentions?: number;
  activityStatus?: string;
}): { trustScore: number; dangerScore: number; confidence: number } {
  const reportCount = input.reportCount;
  const communityTrust = calcTrustScore(input.dangerScore);
  let trust = communityTrust;

  if (reportCount > 0) {
    if (input.webTrust != null) {
      trust = Math.round(communityTrust * 0.6 + input.webTrust * 0.4);
    }
    trust -= Math.min(15, (input.webComplaints ?? 0) * 3);
  } else if (input.webTrust != null) {
    trust = input.webTrust;
  } else if ((input.snippetCount ?? 0) >= 4) {
    trust = 68;
  } else if ((input.snippetCount ?? 0) >= 1) {
    trust = 62;
  } else {
    trust = 58;
  }

  const activity = (input.activityStatus ?? '').toLowerCase();
  if (activity === 'high_risk_signals') trust -= 18;
  else if (activity === 'some_complaints') trust -= 10;
  else if (activity === 'active_hiring' && reportCount === 0) trust += 6;

  trust += Math.min(8, (input.positiveMentions ?? 0) * 2);
  trust -= Math.min(20, (input.webComplaints ?? 0) * 5);

  trust = Math.max(0, Math.min(100, Math.round(trust)));
  const danger = Math.max(0, Math.min(100, 100 - trust));

  let confidence = 30;
  if (reportCount > 0) confidence += Math.min(40, reportCount * 8);
  if ((input.snippetCount ?? 0) > 0) confidence += Math.min(25, input.snippetCount! * 4);
  if (input.webTrust != null) confidence += 15;
  confidence = Math.max(15, Math.min(92, confidence));

  return { trustScore: trust, dangerScore: danger, confidence };
}

export async function aggregateCompanyRisk(
  db: D1Database,
  normalizedName: string,
): Promise<{
  reportCount: number;
  avgSeverity: number;
  recentReports: number;
  evidenceCount: number;
  dangerScore: number;
  trustScore: number;
}> {
  const stats = await db
    .prepare(
      `SELECT
         COUNT(*) AS cnt,
         COALESCE(AVG(severity), 3) AS avg_sev,
         COALESCE(SUM(CASE WHEN created_at > datetime('now', '-30 days') THEN 1 ELSE 0 END), 0) AS recent,
         COALESCE(SUM(evidence_count), 0) AS evidence
       FROM blacklist_reports
       WHERE normalized_company LIKE ? AND deleted_at IS NULL`,
    )
    .bind(`%${normalizedName}%`)
    .first<{
      cnt: number;
      avg_sev: number;
      recent: number;
      evidence: number;
    }>();

  const reportCount = stats?.cnt ?? 0;
  const dangerScore = calcDangerScore({
    reportCount,
    avgSeverity: stats?.avg_sev ?? 3,
    recentReports: stats?.recent ?? 0,
    evidenceCount: stats?.evidence ?? 0,
    complaintFrequency: reportCount > 0 ? Math.ceil(reportCount / 3) : 0,
  });

  return {
    reportCount,
    avgSeverity: stats?.avg_sev ?? 3,
    recentReports: stats?.recent ?? 0,
    evidenceCount: stats?.evidence ?? 0,
    dangerScore,
    trustScore: calcTrustScore(dangerScore),
  };
}

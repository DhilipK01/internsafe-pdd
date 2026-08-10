/**
 * Community intelligence shaping for /companies/verify (Worker-side, D1).
 */

export function buildCommunityIntelligencePayload(
  reports: Record<string, unknown>[],
  reportCount: number,
  dangerScore: number,
  fraudTypes: { fraud_type: string }[],
): Record<string, unknown> {
  const counter = new Map<string, number>();
  for (const r of reports) {
    const ft = String(r.fraud_type ?? r.report_type ?? 'report');
    counter.set(ft, (counter.get(ft) ?? 0) + 1);
  }
  for (const ft of fraudTypes) {
    if (ft.fraud_type) {
      counter.set(ft.fraud_type, (counter.get(ft.fraud_type) ?? 0) + 1);
    }
  }

  const fraudTypeBreakdown = [...counter.entries()]
    .sort((a, b) => b[1] - a[1])
    .slice(0, 6)
    .map(([type, count]) => ({ type, count }));

  const summaries = reports.slice(0, 8).map((r) => {
    const ft = String(r.fraud_type ?? r.report_type ?? 'report');
    const title = String(r.title ?? '').trim();
    const desc = String(r.description ?? '').trim();
    const line = title || (desc.length > 120 ? `${desc.slice(0, 120)}…` : desc);
    return line ? `[${ft}] ${line}` : `[${ft}] Community report`;
  });

  const riskIndicators: string[] = [];
  for (const r of reports) {
    const sev = Number(r.severity ?? 3);
    if (sev >= 4) {
      riskIndicators.push(
        `High-severity ${String(r.fraud_type ?? 'report')} report`,
      );
      if (riskIndicators.length >= 4) break;
    }
  }

  let aiSummary: string;
  if (reportCount <= 0) {
    aiSummary = 'No INTERNSAFE community reports matched this company name.';
  } else {
    const top = fraudTypeBreakdown
      .slice(0, 3)
      .map((x) => `${x.type} (${x.count})`)
      .join(', ');
    aiSummary =
      `INTERNSAFE community intelligence: ${reportCount} report(s) ` +
      `(danger index ${dangerScore}/100).` +
      (top ? ` Report types: ${top}.` : '') +
      ' Cross-check recruiter identity before sharing documents.';
  }

  return {
    totalReports: reportCount,
    dangerScore,
    summaries,
    fraudTypeBreakdown,
    riskIndicators,
    aiSummary,
    recentReportCount: reports.length,
  };
}

export function buildOfflineRecommendation(
  reportCount: number,
  community: Record<string, unknown>,
  intel: Record<string, unknown>,
): string {
  const webSummary = String(intel.internet_reputation_summary ?? '').trim();
  const commSummary = String(community.aiSummary ?? '').trim();
  const parts: string[] = [];
  if (webSummary) parts.push(webSummary);
  if (reportCount > 0 && commSummary) parts.push(commSummary);
  if (!parts.length) {
    return (
      'Analysis completed using INTERNSAFE community data. Limited public web ' +
      'signals were retrieved — verify employer domain and offer letter independently.'
    );
  }
  return parts.join(' ');
}

export function communityReportsForAi(
  reports: Record<string, unknown>[],
): Record<string, unknown>[] {
  return reports.slice(0, 12).map((r) => ({
    fraud_type: r.fraud_type,
    report_type: r.report_type,
    title: r.title,
    description:
      typeof r.description === 'string'
        ? r.description.slice(0, 400)
        : r.description,
    severity: r.severity,
    college: r.college,
    created_at: r.created_at,
  }));
}

"""Community report intelligence from INTERNSAFE DB context (passed by Worker)."""
from __future__ import annotations

from collections import Counter
from typing import Any


def build_community_intelligence(context: dict[str, Any]) -> dict[str, Any]:
    reports: list[dict[str, Any]] = list(context.get("community_reports") or [])
    report_count = int(context.get("report_count") or len(reports))
    danger_score = int(context.get("danger_score") or 0)

    fraud_counter: Counter[str] = Counter()
    summaries: list[str] = []
    risk_indicators: list[str] = []

    for r in reports[:12]:
        ft = (r.get("fraud_type") or r.get("report_type") or "report").strip()
        fraud_counter[ft] += 1
        desc = (r.get("description") or "").strip()
        title = (r.get("title") or "").strip()
        sev = int(r.get("severity") or 3)
        line = title or (desc[:120] + ("…" if len(desc) > 120 else ""))
        if line:
            summaries.append(f"[{ft}] {line}")
        if sev >= 4:
            risk_indicators.append(f"High-severity {ft} report")

    fraud_breakdown = [
        {"type": k, "count": v} for k, v in fraud_counter.most_common(6)
    ]

    ai_summary = _community_ai_summary(
        report_count, danger_score, fraud_counter, risk_indicators
    )

    return {
        "total_reports": report_count,
        "danger_score": danger_score,
        "summaries": summaries[:8],
        "fraud_type_breakdown": fraud_breakdown,
        "risk_indicators": risk_indicators[:6],
        "ai_summary": ai_summary,
        "recent_report_count": len(reports),
    }


def _community_ai_summary(
    report_count: int,
    danger_score: int,
    fraud_counter: Counter[str],
    risk_indicators: list[str],
) -> str:
    if report_count <= 0:
        return "No INTERNSAFE community reports matched this company name."

    parts = [
        f"INTERNSAFE community intelligence: {report_count} report(s) "
        f"(danger index {danger_score}/100)."
    ]
    if fraud_counter:
        top = ", ".join(f"{k} ({v})" for k, v in fraud_counter.most_common(3))
        parts.append(f"Report types: {top}.")
    if risk_indicators:
        parts.append(risk_indicators[0] + ".")
    parts.append(
        "Cross-check recruiter email/domain before sharing documents or paying fees."
    )
    return " ".join(parts)


def build_unified_recommendation(
    internet: dict[str, Any],
    community: dict[str, Any],
) -> str:
    """Evidence-based narrative combining web + community signals."""
    web_status = internet.get("internet_status") or "limited"
    web_summary = (internet.get("internet_reputation_summary") or "").strip()
    comm_summary = (community.get("ai_summary") or "").strip()
    web_rec = (internet.get("ai_recommendation") or "").strip()
    report_count = int(community.get("total_reports") or 0)
    complaints = int(internet.get("complaint_count") or 0)

    parts: list[str] = []

    if web_status == "completed" and web_summary:
        parts.append(web_summary)
    elif internet.get("partial_message"):
        parts.append(str(internet.get("partial_message")))
    elif web_rec:
        parts.append(web_rec)

    if report_count > 0 and comm_summary:
        parts.append(comm_summary)

    if not parts:
        return (
            "Limited public and community intelligence available. Verify the employer "
            "via official website, company email domain, and offer letter before "
            "sharing sensitive documents."
        )

    if (
        report_count == 0
        and complaints == 0
        and int(internet.get("snippet_count") or 0) >= 2
        and web_status in ("completed", "partial")
    ):
        parts.append(
            "No INTERNSAFE fraud reports and no scam keywords in public snippets — "
            "still verify internship offers and recruiter identity."
        )

    if complaints >= 2 and report_count >= 2:
        parts.append(
            "Both public web signals and community reports raise concerns — proceed with "
            "extreme caution."
        )
    elif complaints >= 1 or report_count >= 1:
        parts.append("Proceed cautiously and verify recruiter identity independently.")

    return " ".join(parts)

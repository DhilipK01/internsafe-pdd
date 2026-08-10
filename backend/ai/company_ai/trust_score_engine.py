"""Dynamic company trust scoring — evidence-based, never a static default of 50."""
from __future__ import annotations

from typing import Any


def compute_trust_score(context: dict[str, Any]) -> dict[str, Any]:
    """
    Weighted trust from community DB signals + optional web intelligence fields.
    """
    report_count = int(context.get("report_count") or 0)
    danger_score = int(context.get("danger_score") or 0)
    complaint_count = int(context.get("complaint_count") or report_count)
    web_trust = context.get("web_trust_score")
    web_complaints = int(context.get("web_complaint_count") or 0)
    snippet_count = int(context.get("snippet_count") or 0)
    positive_mentions = int(context.get("positive_mentions") or 0)
    hiring_mentions = int(context.get("hiring_mentions") or 0)
    activity_status = (context.get("activity_status") or "").lower()

    community_trust = max(0, min(100, 100 - danger_score))

    scores: list[tuple[int, float]] = []

    if report_count > 0:
        scores.append((community_trust, 0.55))
    elif web_trust is not None:
        scores.append((int(web_trust), 0.5))

    if web_trust is not None and report_count > 0:
        scores.append((int(web_trust), 0.35))

    if not scores:
        scores.append((_baseline_no_data(snippet_count, web_complaints), 1.0))

    trust = int(round(sum(s * w for s, w in scores) / sum(w for _, w in scores)))

    trust += min(8, positive_mentions * 2)
    trust += min(5, hiring_mentions)
    trust -= min(25, web_complaints * 5)
    trust -= min(20, complaint_count * 4 if report_count == 0 else 0)

    if activity_status == "high_risk_signals":
        trust -= 18
    elif activity_status == "some_complaints":
        trust -= 10
    elif activity_status == "active_hiring" and report_count == 0:
        trust += 6
    elif activity_status == "neutral_presence" and report_count == 0:
        trust += 4

    trust = max(0, min(100, trust))
    danger = max(0, min(100, 100 - trust))

    confidence = _confidence(
        report_count, snippet_count, web_trust is not None, complaint_count
    )

    risk_band = (
        "low"
        if trust >= 70
        else "medium"
        if trust >= 45
        else "high"
        if trust >= 25
        else "critical"
    )

    factors = _build_factors(context, report_count, danger_score, web_complaints)

    return {
        "trust_score": trust,
        "danger_score": danger,
        "risk_band": risk_band,
        "confidence": confidence,
        "confidence_score": confidence,
        "evidence_count": report_count + snippet_count,
        "factors": factors,
        "positive_indicators": _positive_indicators(
            positive_mentions, hiring_mentions, report_count, snippet_count
        ),
        "warning_indicators": _warning_indicators(
            web_complaints, snippet_count, activity_status
        ),
        "danger_indicators": _danger_indicators(
            report_count, danger_score, web_complaints, activity_status
        ),
        "status": "completed",
    }


def _baseline_no_data(snippet_count: int, web_complaints: int) -> int:
    """Unknown company — not the old hardcoded 50."""
    if web_complaints >= 2:
        return 28
    if snippet_count >= 5:
        return 68
    if snippet_count >= 2:
        return 62
    return 58


def _confidence(
    report_count: int, snippet_count: int, has_web: bool, complaints: int
) -> int:
    score = 30
    if report_count > 0:
        score += min(40, report_count * 8)
    if snippet_count >= 5:
        score += 35
    elif snippet_count >= 2:
        score += min(28, snippet_count * 5)
    elif snippet_count >= 1:
        score += 18
    if has_web:
        score += 12
    if complaints > 0:
        score += 8
    return max(20, min(95, score))


def _build_factors(
    ctx: dict[str, Any], report_count: int, danger: int, web_complaints: int
) -> list[str]:
    factors: list[str] = []
    if report_count:
        factors.append(f"{report_count} INTERNSAFE community report(s)")
    if danger > 0:
        factors.append(f"Community danger index {danger}/100")
    if web_complaints:
        factors.append(f"{web_complaints} public complaint signal(s) from web search")
    snip = int(ctx.get("snippet_count") or 0)
    if snip:
        factors.append(f"{snip} public web snippet(s) analyzed")
    if not factors:
        factors.append("Limited verified intelligence — treat as unverified")
    return factors


def _positive_indicators(
    positive: int, hiring: int, reports: int, snippets: int
) -> list[str]:
    out: list[str] = []
    if positive > 0:
        out.append(f"{positive} positive reputation mention(s) in public search")
    if hiring >= 2 and reports == 0:
        out.append("Active hiring/internship presence detected online")
    if snippets >= 4 and reports == 0:
        out.append("Established public online footprint")
    elif snippets >= 2 and reports == 0 and not out:
        out.append("Public company profile found via web intelligence")
    if reports == 0 and not out:
        out.append("No community fraud reports in INTERNSAFE database")
    return out[:6]


def _warning_indicators(
    web_complaints: int, snippets: int, activity: str
) -> list[str]:
    out: list[str] = []
    if snippets < 2 and activity not in ("unknown", "limited_activity"):
        out.append("Low public search visibility")
    elif snippets < 2 and activity == "limited_activity":
        out.append("Limited public footprint in automated search")
    if activity == "limited_activity":
        out.append("Company appears dormant or hard to verify online")
    if web_complaints == 1:
        out.append("Single public complaint-like mention found")
    return out[:6]


def _danger_indicators(
    reports: int, danger: int, web_complaints: int, activity: str
) -> list[str]:
    out: list[str] = []
    if reports >= 5 or danger >= 70:
        out.append("High volume of community fraud reports")
    elif reports >= 1:
        out.append("Community reports allege internship fraud or payment scams")
    if web_complaints >= 3:
        out.append("Multiple scam/fraud mentions in public web results")
    if activity == "high_risk_signals":
        out.append("Public sources flag serious fraud indicators")
    return out[:8]

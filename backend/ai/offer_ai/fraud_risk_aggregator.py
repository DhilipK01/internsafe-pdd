"""Strict offer fraud scoring — severity-weighted with hard rule overrides."""
from __future__ import annotations

from typing import Any

from backend.ai.offer_ai.scam_pattern_engine import ScamPatternHit, detect_scam_patterns

# Points added per finding by severity
SEVERITY_POINTS = {
    "critical": 28,
    "high": 16,
    "medium": 8,
    "low": 4,
}

# Rule-specific boosts (dominate over formatting/grammar)
RULE_BOOST = {
    "payment_request": 32,
    "upi_payment": 36,
    "aadhaar_before_interview": 30,
    "pan_before_onboarding": 24,
    "crypto_payment": 34,
    "bank_transfer_request": 28,
    "personal_email_domain": 12,
    "whatsapp_only": 14,
    "urgency_manipulation": 16,
    "suspicious_deadline": 12,
    "no_interview_process": 18,
    "unrealistic_compensation": 16,
    "unrealistic_stipend": 18,
    "manipulation_language": 14,
    "community_reports": 22,
}

VERDICT_ORDER = [
    "safe",
    "low_risk",
    "moderate_risk",
    "high_risk",
    "scam_likely",
    "critical_warning",
]


def _max_verdict(a: str, b: str) -> str:
    ia = VERDICT_ORDER.index(a) if a in VERDICT_ORDER else 0
    ib = VERDICT_ORDER.index(b) if b in VERDICT_ORDER else 0
    return VERDICT_ORDER[max(ia, ib)]


def _verdict_from_score(score: int) -> str:
    if score >= 85:
        return "critical_warning"
    if score >= 70:
        return "scam_likely"
    if score >= 55:
        return "high_risk"
    if score >= 35:
        return "moderate_risk"
    if score >= 18:
        return "low_risk"
    return "safe"


def _risk_level_from_verdict(verdict: str) -> str:
    mapping = {
        "safe": "low",
        "low_risk": "low",
        "moderate_risk": "medium",
        "high_risk": "high",
        "scam_likely": "critical",
        "critical_warning": "critical",
    }
    return mapping.get(verdict, "unknown")


def _result_label_from_verdict(verdict: str) -> str:
    if verdict in ("critical_warning", "scam_likely", "high_risk"):
        return "likely_fraud"
    if verdict == "moderate_risk":
        return "suspicious"
    if verdict == "low_risk":
        return "suspicious"
    return "likely_genuine"


def _verdict_label(verdict: str) -> str:
    return verdict.replace("_", " ").upper()


def _fraud_confidence(
    danger_score: int,
    finding_count: int,
    pattern_count: int,
) -> int:
    """Calculates overall confidence (0-100%) in the verdict."""
    if danger_score == 0 and finding_count == 0:
        return 95  # Clean document with zero scam findings is 95% confident genuine

    if danger_score < 18:
        return max(85, 95 - danger_score)  # High confidence in low risk verdict

    if danger_score >= 70:
        base = 85
    elif danger_score >= 45:
        base = 75
    elif danger_score >= 25:
        base = 65
    else:
        base = 55
    base += min(10, finding_count * 2)
    base += min(5, pattern_count * 3)
    return max(30, min(98, base))


def _build_strict_explanation(
    verdict: str,
    reasons: list[str],
    patterns: list[ScamPatternHit],
    danger_score: int,
) -> str:
    if verdict in ("critical_warning", "scam_likely", "high_risk"):
        parts = [
            "This offer shows multiple high-risk scam indicators. ",
        ]
        if patterns:
            parts.append(
                f"Matched scam patterns: {', '.join(p.label for p in patterns[:3])}. "
            )
        if reasons:
            parts.append(
                "Key concerns include: "
                + "; ".join(reasons[:6])
                + ". "
            )
        parts.append(
            "Legitimate employers rarely request verification fees, UPI transfers before "
            "interviews, or WhatsApp-only communication from personal Gmail addresses. "
            "Treat this offer as highly suspicious and verify independently."
        )
        return "".join(parts)

    if verdict == "moderate_risk":
        return (
            "Several caution signals were detected in this offer. "
            + ("Issues noted: " + "; ".join(reasons[:5]) + ". " if reasons else "")
            + "Verify the company domain, recruiter identity, and avoid upfront payments."
        )

    if verdict == "low_risk":
        return (
            "Minor risk signals were found but no critical scam combination. "
            "Still verify the employer through official channels before sharing documents."
        )

    return (
        "No strong fraud indicators were detected by automated rules. "
        "Independently verify company registration, offer letter domain, and recruiter identity."
    )


def aggregate_offer_fraud(
    rule_findings: list[dict[str, Any]],
    nlp_findings: list[dict[str, Any]],
) -> dict[str, Any]:
    patterns = detect_scam_patterns(rule_findings, nlp_findings)

    danger_score = 0
    for f in rule_findings + nlp_findings:
        sev = f.get("risk_level", "medium")
        danger_score += SEVERITY_POINTS.get(sev, 8)
        rid = f.get("rule_id") or f.get("nlp_signal")
        if rid in RULE_BOOST:
            danger_score += RULE_BOOST[rid] // 2

    for f in rule_findings:
        rid = f.get("rule_id")
        if rid in RULE_BOOST:
            danger_score += RULE_BOOST[rid] // 3

    # Critical count multiplier
    critical_count = sum(
        1
        for f in rule_findings + nlp_findings
        if f.get("risk_level") == "critical"
    )
    high_count = sum(
        1 for f in rule_findings + nlp_findings if f.get("risk_level") == "high"
    )
    if critical_count >= 2:
        danger_score += 20
    if critical_count >= 1 and high_count >= 2:
        danger_score += 15

    # Pattern floor
    min_verdict = "safe"
    for p in patterns:
        danger_score = max(danger_score, p.min_danger_score)
        min_verdict = _max_verdict(min_verdict, p.min_verdict)

    danger_score = min(100, danger_score)
    verdict = _max_verdict(_verdict_from_score(danger_score), min_verdict)

    # Hard signal overrides from rule IDs
    rule_ids = {f.get("rule_id") for f in rule_findings}
    if "payment_request" in rule_ids and "upi_payment" in rule_ids:
        verdict = _max_verdict(verdict, "critical_warning")
        danger_score = max(danger_score, 88)
    if (
        "personal_email_domain" in rule_ids
        and "whatsapp_only" in rule_ids
        and ("urgency_manipulation" in rule_ids or "suspicious_deadline" in rule_ids)
    ):
        verdict = _max_verdict(verdict, "scam_likely")
        danger_score = max(danger_score, 82)
    if "payment_request" in rule_ids and critical_count >= 1:
        verdict = _max_verdict(verdict, "high_risk")
        danger_score = max(danger_score, 72)

    risk_level = _risk_level_from_verdict(verdict)
    result_label = _result_label_from_verdict(verdict)
    finding_count = len(rule_findings) + len(nlp_findings)
    confidence = _fraud_confidence(danger_score, finding_count, len(patterns))

    reasons: list[str] = []
    for f in rule_findings:
        reasons.append(f["label"])
    for f in nlp_findings:
        reasons.append(f.get("label", f.get("nlp_signal", "NLP signal")))

    explanation = _build_strict_explanation(verdict, reasons, patterns, danger_score)

    return {
        "danger_score": danger_score,
        "risk_level": risk_level,
        "verdict": verdict,
        "verdict_label": _verdict_label(verdict),
        "result": result_label,
        "confidence_score": confidence,
        "scam_patterns": [
            {
                "pattern_id": p.pattern_id,
                "label": p.label,
                "severity": p.severity,
                "min_verdict": p.min_verdict,
            }
            for p in patterns
        ],
        "explanation": explanation,
        "reasons": reasons[:20],
    }

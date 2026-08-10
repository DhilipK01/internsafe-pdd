"""Combination scam patterns — escalate when multiple red flags align."""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any


@dataclass(frozen=True)
class ScamPatternHit:
    pattern_id: str
    label: str
    min_danger_score: int
    min_verdict: str
    severity: str


def _signals_from_findings(
    rule_findings: list[dict[str, Any]],
    nlp_findings: list[dict[str, Any]],
) -> dict[str, bool]:
    rule_ids = {f.get("rule_id") for f in rule_findings}
    labels = " ".join(
        (f.get("label") or "").lower() for f in rule_findings + nlp_findings
    )

    return {
        "payment_request": "payment_request" in rule_ids
        or "fee" in labels
        or "deposit" in labels,
        "upi_detected": "upi_payment" in rule_ids or "upi" in labels,
        "gmail_domain": "personal_email_domain" in rule_ids,
        "urgency_pressure": "urgency_manipulation" in rule_ids
        or "suspicious_deadline" in rule_ids
        or "urgency" in labels,
        "whatsapp_only": "whatsapp_only" in rule_ids,
        "aadhaar_early": "aadhaar_before_interview" in rule_ids
        or "aadhaar" in labels,
        "pan_early": "pan_before_onboarding" in rule_ids,
        "no_interview": "no_interview_process" in rule_ids,
        "unrealistic_salary": "unrealistic_compensation" in rule_ids
        or "unrealistic_stipend" in rule_ids,
        "crypto_payment": "crypto_payment" in rule_ids,
        "bank_transfer": "bank_transfer_request" in rule_ids,
    }


def detect_scam_patterns(
    rule_findings: list[dict[str, Any]],
    nlp_findings: list[dict[str, Any]],
) -> list[ScamPatternHit]:
    s = _signals_from_findings(rule_findings, nlp_findings)
    hits: list[ScamPatternHit] = []

    if s["payment_request"] and s["upi_detected"]:
        hits.append(
            ScamPatternHit(
                "payment_upi_combo",
                "Upfront fee demanded via UPI",
                88,
                "critical_warning",
                "critical",
            )
        )

    if s["payment_request"] and s["urgency_pressure"]:
        hits.append(
            ScamPatternHit(
                "payment_urgency_combo",
                "Payment demand combined with deadline pressure",
                82,
                "scam_likely",
                "critical",
            )
        )

    if s["gmail_domain"] and s["whatsapp_only"] and s["urgency_pressure"]:
        hits.append(
            ScamPatternHit(
                "gmail_whatsapp_urgency",
                "Personal Gmail + WhatsApp-only + urgency pressure",
                85,
                "scam_likely",
                "critical",
            )
        )

    if s["gmail_domain"] and s["payment_request"]:
        hits.append(
            ScamPatternHit(
                "gmail_payment",
                "Personal email domain with payment request",
                80,
                "scam_likely",
                "high",
            )
        )

    if s["whatsapp_only"] and s["aadhaar_early"]:
        hits.append(
            ScamPatternHit(
                "whatsapp_aadhaar",
                "WhatsApp-only contact requesting Aadhaar early",
                86,
                "critical_warning",
                "critical",
            )
        )

    if s["unrealistic_salary"] and s["no_interview"]:
        hits.append(
            ScamPatternHit(
                "high_pay_no_interview",
                "Unrealistic compensation with no interview process",
                78,
                "high_risk",
                "high",
            )
        )

    if s["upi_detected"] and s["urgency_pressure"]:
        hits.append(
            ScamPatternHit(
                "upi_urgency",
                "UPI payment identifier with same-day urgency",
                84,
                "scam_likely",
                "critical",
            )
        )

    if s["aadhaar_early"] and s["payment_request"]:
        hits.append(
            ScamPatternHit(
                "aadhaar_payment",
                "Aadhaar requested before interview with payment demand",
                90,
                "critical_warning",
                "critical",
            )
        )

    if (
        s["gmail_domain"]
        and s["whatsapp_only"]
        and s["payment_request"]
        and s["urgency_pressure"]
    ):
        hits.append(
            ScamPatternHit(
                "full_internship_scam_kit",
                "Classic internship scam pattern (Gmail + WhatsApp + fee + urgency)",
                95,
                "critical_warning",
                "critical",
            )
        )

    return hits

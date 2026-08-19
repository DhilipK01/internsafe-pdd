"""Offer fraud detection — strict rules + NLP + severity aggregator."""
from __future__ import annotations

import json
from typing import Any

from backend.ai.offer_ai.fraud_risk_aggregator import aggregate_offer_fraud
from backend.ai.offer_ai.nlp_classifier import classify_offer_text
from backend.ai.offer_ai.rules_engine import analyze_rules
from backend.ai.utils.scoring import classify_offer_document
from backend.ai.utils.text_normalize import normalize_text, truncate


def analyze_offer_text(
    text: str,
    blacklist_context: dict[str, Any] | None = None,
) -> dict[str, Any]:
    normalized = normalize_text(text)

    if len(normalized.strip()) < 20:
        return {
            "result": "insufficient_evidence",
            "status": "completed",
            "risk_level": "unknown",
            "verdict": "unknown",
            "confidence_score": 0,
            "reasons": [],
            "rule_findings": [],
            "nlp_findings": [],
            "scam_patterns": [],
            "summary": "Insufficient evidence for reliable analysis.",
            "message": "Insufficient evidence for reliable analysis.",
        }

    is_offer, offer_checks, reasoning = classify_offer_document(normalized)
    if not is_offer:
        return {
            "result": "invalid_document_type",
            "status": "invalid_document_type",
            "is_offer": False,
            "risk_level": "unknown",
            "verdict": "invalid_document_type",
            "verdict_label": "Invalid Document Type",
            "danger_score": 0,
            "confidence_score": 0,
            "reasons": [reasoning],
            "rule_findings": [],
            "nlp_findings": [],
            "scam_patterns": [],
            "offer_checks": offer_checks,
            "summary": f"Uploaded document is not an Offer Letter/Appointment Letter. {reasoning}",
            "message": f"Uploaded document is not an Offer Letter/Appointment Letter. {reasoning}",
            "ai_recommendation": {
                "explanation": f"The uploaded file was recognized as a non-offer document type. {reasoning}",
                "action_items": [
                    "Please upload a valid internship or job offer letter (PDF, Image, or DOCX).",
                    "Do not upload resumes, college assignments, mark sheets, or general notes into the offer fraud detector."
                ],
            },
        }

    rule_findings = analyze_rules(normalized)
    nlp_findings = classify_offer_text(normalized)

    if blacklist_context and blacklist_context.get("report_count", 0) > 0:
        rc = int(blacklist_context["report_count"])
        rule_findings.append(
            {
                "rule_id": "community_reports",
                "label": f"Company has {rc} community fraud report(s)",
                "risk_level": "critical" if rc >= 3 else "high",
                "confidence": min(0.95, 0.6 + rc * 0.05),
                "evidence": blacklist_context.get("company_name", ""),
            }
        )

    agg = aggregate_offer_fraud(rule_findings, nlp_findings)

    summary = truncate(agg["explanation"], 500)

    return {
        "result": agg["result"],
        "status": "completed",
        "risk_level": agg["risk_level"],
        "verdict": agg["verdict"],
        "verdict_label": agg["verdict_label"],
        "danger_score": agg["danger_score"],
        "confidence_score": agg["confidence_score"],
        "reasons": agg["reasons"],
        "rule_findings": rule_findings,
        "nlp_findings": nlp_findings,
        "scam_patterns": agg["scam_patterns"],
        "summary": summary,
        "message": summary,
        "reasons_json": json.dumps(
            {
                "rules": rule_findings,
                "nlp": nlp_findings,
                "danger_score": agg["danger_score"],
                "verdict": agg["verdict"],
                "scam_patterns": agg["scam_patterns"],
            }
        ),
        "ai_recommendation": {
            "explanation": agg["explanation"],
            "action_items": _action_items_for_verdict(agg["verdict"]),
        },
    }


def _action_items_for_verdict(verdict: str) -> list[str]:
    if verdict in ("critical_warning", "scam_likely", "high_risk"):
        return [
            "Do not pay any registration, verification, or UPI fee.",
            "Do not share Aadhaar, PAN, or bank details until employer is verified.",
            "Verify company domain and recruiter on official website and LinkedIn.",
            "Search the company on INTERNSAFE community reports.",
            "Report suspicious offers to help protect other students.",
        ]
    if verdict == "moderate_risk":
        return [
            "Verify offer letter and recruiter email domain independently.",
            "Decline upfront payment requests until onboarding is official.",
        ]
    return [
        "Confirm the offer email domain matches the official company website.",
        "Never pay registration or training fees for internships.",
    ]

"""Resume intelligence — entity detection, risk scoring, recommendations."""
from __future__ import annotations

from typing import Any

from backend.ai.resume_ai.entity_detector import detect_all
from backend.ai.utils.scoring import (
    classify_resume_document,
    evaluate_resume_quality,
    resume_safety_score,
)
from backend.ai.utils.text_normalize import normalize_text
from backend.config import get_settings


def analyze_resume_text(text: str, ocr_confidence: float = 1.0, file_name: str = "") -> dict[str, Any]:
    settings = get_settings()
    normalized = normalize_text(text)

    if len(normalized.strip()) < 15:
        return {
            "is_resume": False,
            "safety_score": None,
            "quality_score": 0,
            "risk_level": "unknown",
            "findings": [],
            "detected_entities": [],
            "confidence_scores": {"overall": 0.0},
            "recommendations": [
                "Insufficient evidence for reliable analysis. "
                "Upload a clearer PDF/image or ensure text is selectable.",
            ],
            "status": "insufficient_evidence",
            "message": "Insufficient evidence for reliable analysis.",
        }

    # Document Classification Check (Resume vs Non-Resume Document)
    is_res, section_checks, reasoning = classify_resume_document(normalized, file_name=file_name)
    if not is_res:
        return {
            "is_resume": False,
            "safety_score": None,
            "quality_score": 0,
            "risk_level": "unknown",
            "findings": [],
            "detected_entities": [],
            "section_checks": section_checks,
            "recommendations": [
                "The uploaded document does not appear to be a Resume or CV. Please upload a valid resume containing standard sections like Experience, Education, or Skills."
            ],
            "status": "invalid_document_type",
            "message": "Uploaded document is not a Resume/CV. " + reasoning,
        }

    findings = detect_all(normalized)
    safety, risk_level, agg_conf = resume_safety_score(findings)
    quality_score, section_checks, quality_recs = evaluate_resume_quality(normalized, findings)
    overall_conf = min(agg_conf, ocr_confidence) if ocr_confidence > 0 else agg_conf

    if overall_conf < settings.ocr_min_confidence and len(findings) == 0:
        return {
            "is_resume": True,
            "safety_score": None,
            "quality_score": quality_score,
            "risk_level": "unknown",
            "findings": [],
            "detected_entities": [],
            "section_checks": section_checks,
            "confidence_scores": {"overall": round(overall_conf, 3)},
            "recommendations": [
                "Insufficient evidence for reliable analysis.",
            ],
            "status": "insufficient_evidence",
            "message": "Insufficient evidence for reliable analysis.",
        }

    recs = list({f.get("recommendation", "") for f in findings if f.get("recommendation")})
    recs.extend(quality_recs)
    if not recs and safety >= 85:
        recs = ["No critical PII patterns detected. Keep resumes minimal for internship applications."]

    return {
        "is_resume": True,
        "safety_score": safety,
        "quality_score": quality_score,
        "risk_level": risk_level,
        "findings": findings,
        "section_checks": section_checks,
        "detected_entities": [
            {"type": f["finding_type"], "value": f["finding_value"], "risk": f["risk_level"]}
            for f in findings
        ],
        "confidence_scores": {
            "overall": round(overall_conf, 3),
            "ocr": round(ocr_confidence, 3),
        },
        "recommendations": recs[:12],
        "status": "completed",
        "extracted_text_length": len(normalized),
    }


"""Resume intelligence — entity detection, risk scoring, recommendations."""
from __future__ import annotations

from typing import Any

from backend.ai.resume_ai.entity_detector import detect_all
from backend.ai.utils.scoring import resume_safety_score
from backend.ai.utils.text_normalize import normalize_text
from backend.config import get_settings


def analyze_resume_text(text: str, ocr_confidence: float = 1.0) -> dict[str, Any]:
    settings = get_settings()
    normalized = normalize_text(text)

    if len(normalized.strip()) < 15:
        return {
            "safety_score": None,
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

    findings = detect_all(normalized)
    safety, risk_level, agg_conf = resume_safety_score(findings)
    overall_conf = min(agg_conf, ocr_confidence) if ocr_confidence > 0 else agg_conf

    if overall_conf < settings.ocr_min_confidence and len(findings) == 0:
        return {
            "safety_score": None,
            "risk_level": "unknown",
            "findings": [],
            "detected_entities": [],
            "confidence_scores": {"overall": round(overall_conf, 3)},
            "recommendations": [
                "Insufficient evidence for reliable analysis.",
            ],
            "status": "insufficient_evidence",
            "message": "Insufficient evidence for reliable analysis.",
        }

    recs = list({f.get("recommendation", "") for f in findings if f.get("recommendation")})
    if not recs and safety >= 85:
        recs = ["No critical PII patterns detected. Keep resumes minimal for internship applications."]

    return {
        "safety_score": safety,
        "risk_level": risk_level,
        "findings": findings,
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

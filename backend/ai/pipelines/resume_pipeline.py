"""End-to-end resume processing pipeline."""
from __future__ import annotations

from typing import Any

from backend.ai.ocr.ocr_service import extract_from_file
from backend.ai.recommendation_ai.recommendation_service import explain_resume
from backend.ai.resume_ai.resume_engine import analyze_resume_text
from backend.ai.embedding_ai.embedding_service import embed_text


def run_resume_pipeline(
    file_bytes: bytes,
    mime_type: str,
    file_name: str = "",
) -> dict[str, Any]:
    ocr = extract_from_file(file_bytes, mime_type, file_name)
    text = ocr.text

    analysis = analyze_resume_text(text, ocr_confidence=ocr.confidence, file_name=file_name)
    if analysis.get("status") == "insufficient_evidence":
        return {
            **analysis,
            "ocr": ocr.to_dict(),
            "extracted_text": text[:5000] if text else "",
            "ai_recommendation": {
                "explanation": analysis["message"],
                "action_items": analysis.get("recommendations", []),
            },
        }

    rec = explain_resume(
        analysis.get("findings", []),
        analysis.get("safety_score"),
        analysis.get("risk_level", "unknown"),
    )
    embedding = embed_text(text) if text else None

    return {
        **analysis,
        "ocr": ocr.to_dict(),
        "extracted_text": text[:50_000],
        "ai_recommendation": rec,
        "embedding": embedding,
    }

"""End-to-end offer fraud pipeline."""
from __future__ import annotations

from typing import Any

from backend.ai.ocr.ocr_service import extract_from_file
from backend.ai.offer_ai.fraud_engine import analyze_offer_text
from backend.ai.recommendation_ai.recommendation_service import explain_offer
from backend.ai.embedding_ai.embedding_service import embed_text


def run_offer_pipeline(
    text: str | None = None,
    file_bytes: bytes | None = None,
    mime_type: str = "",
    file_name: str = "",
    blacklist_context: dict[str, Any] | None = None,
) -> dict[str, Any]:
    combined = (text or "").strip()
    ocr_meta = None

    if file_bytes:
        ocr = extract_from_file(file_bytes, mime_type, file_name)
        ocr_meta = ocr.to_dict()
        if ocr.text.strip():
            combined = f"{combined}\n\n{ocr.text}".strip() if combined else ocr.text

    analysis = analyze_offer_text(combined, blacklist_context=blacklist_context)
    if analysis.get("result") == "insufficient_evidence":
        return {
            **analysis,
            "ocr": ocr_meta,
            "extracted_text": combined[:5000],
            "ai_recommendation": {
                "explanation": analysis["summary"],
                "action_items": [],
            },
        }

    built_rec = analysis.get("ai_recommendation")
    if isinstance(built_rec, dict) and built_rec.get("explanation"):
        rec = built_rec
    else:
        rec = explain_offer(
            analysis.get("reasons", []),
            analysis.get("verdict") or analysis.get("risk_level", "unknown"),
            analysis.get("rule_findings", []),
            analysis.get("nlp_findings", []),
        )
    embedding = embed_text(combined) if combined else None

    return {
        **analysis,
        "ocr": ocr_meta,
        "extracted_text": combined[:50_000],
        "ai_recommendation": rec,
        "embedding": embedding,
    }

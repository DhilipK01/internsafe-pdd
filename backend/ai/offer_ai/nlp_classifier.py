"""NLP fraud signals — zero-shot / embeddings hybrid (no random scores)."""
from __future__ import annotations

import logging
from typing import Any

from backend.config import get_settings

logger = logging.getLogger(__name__)

_pipeline: Any = None
_embedder: Any = None

FRAUD_HYPOTHESES = [
    "This is an internship scam asking for money",
    "This is a legitimate internship offer",
    "This message uses urgency to pressure the reader",
    "This message requests personal banking information",
    "This is phishing or impersonation",
]

SCAM_PHRASES = [
    "pay registration fee",
    "security deposit",
    "training fee",
    "laptop deposit",
    "selected candidates must pay",
    "send aadhaar",
    "share otp",
    "work from home earn",
    "guaranteed internship certificate",
    "limited seats",
    "immediate payment",
    "refundable fee",
    "confirm slot now",
    "offer expires today",
    "direct selection",
    "no interview required",
    "verification payment",
    "paytm",
    "phonepe",
    "google pay",
]


def _get_zero_shot():
    global _pipeline
    settings = get_settings()
    if not settings.enable_transformers_nlp:
        return None
    if _pipeline is None:
        try:
            from transformers import pipeline

            _pipeline = pipeline(
                "zero-shot-classification",
                model="typeform/distilbert-base-uncased-mnli",
                device=-1,
            )
        except Exception as exc:
            logger.warning("Transformers pipeline unavailable: %s", exc)
            _pipeline = False
    return _pipeline if _pipeline is not False else None


def _phrase_hits(text: str) -> list[dict[str, Any]]:
    lower = text.lower()
    hits = []
    for phrase in SCAM_PHRASES:
        if phrase in lower:
            hits.append(
                {
                    "nlp_signal": "scam_phrase",
                    "label": phrase,
                    "risk_level": "critical"
                    if any(
                        w in phrase
                        for w in ("fee", "payment", "aadhaar", "otp", "paytm")
                    )
                    else "high",
                    "confidence": 0.9,
                }
            )
    return hits


def classify_offer_text(text: str) -> list[dict[str, Any]]:
    findings: list[dict[str, Any]] = []
    findings.extend(_phrase_hits(text))

    clf = _get_zero_shot()
    if clf and len(text) >= 40:
        try:
            snippet = text[:2000]
            result = clf(
                snippet,
                candidate_labels=FRAUD_HYPOTHESES,
                multi_label=True,
            )
            labels = result["labels"]
            scores = result["scores"]
            for label, score in zip(labels, scores):
                if "scam" in label.lower() or "phishing" in label.lower():
                    if score >= 0.55:
                        findings.append(
                            {
                                "nlp_signal": "zero_shot",
                                "label": label,
                                "risk_level": "high" if score >= 0.7 else "medium",
                                "confidence": round(float(score), 3),
                            }
                        )
                if "urgency" in label.lower() and score >= 0.6:
                    findings.append(
                        {
                            "nlp_signal": "zero_shot",
                            "label": label,
                            "risk_level": "medium",
                            "confidence": round(float(score), 3),
                        }
                    )
                if "banking" in label.lower() and score >= 0.55:
                    findings.append(
                        {
                            "nlp_signal": "zero_shot",
                            "label": label,
                            "risk_level": "critical",
                            "confidence": round(float(score), 3),
                        }
                    )
        except Exception as exc:
            logger.warning("NLP classification failed: %s", exc)

    return findings

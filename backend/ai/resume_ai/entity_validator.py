"""Context-aware validation for Indian PII entities — reduces false positives."""
from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Any

from backend.ai.resume_ai.context_filters import (
    has_phone_label_nearby,
    is_in_safe_context,
)
from backend.ai.utils.patterns import PatternDef

BANK_KEYWORDS = re.compile(
    r"\b(?:bank|account\s*(?:no|number|#)?|ifsc|branch|beneficiary|"
    r"transfer|neft|rtgs|imps|upi|payment|salary\s*account|"
    r"current\s*account|savings)\b",
    re.I,
)

AADHAAR_LABEL = re.compile(r"\b(?:aadhaar|aadhar|uid)\b", re.I)
PAN_LABEL = re.compile(r"\b(?:pan|permanent\s*account\s*number)\b", re.I)


@dataclass
class ValidatedEntity:
    finding_type: str
    finding_value: str
    risk_level: str
    confidence: float
    detector: str
    recommendation: str
    reason: str


def _digits_only(value: str) -> str:
    return re.sub(r"\D", "", value)


def is_indian_mobile(value: str) -> bool:
    d = _digits_only(value)
    if len(d) == 12 and d.startswith("91"):
        d = d[2:]
    if len(d) != 10:
        return False
    return d[0] in "6789"


def is_valid_pan(value: str) -> bool:
    return bool(re.fullmatch(r"[A-Z]{5}[0-9]{4}[A-Z]", value.strip().upper()))


def is_valid_aadhaar_digits(value: str) -> bool:
    d = _digits_only(value)
    return len(d) == 12 and not is_indian_mobile(value)


def validate_match(
    text: str,
    match: re.Match[str],
    pat: PatternDef,
    *,
    mask_fn,
    recommend_fn,
) -> ValidatedEntity | None:
    has_group = match.lastindex is not None and match.lastindex >= 1
    raw = (match.group(1) if has_group else match.group(0)).strip()
    start = match.start(1) if has_group else match.start(0)
    end = match.end(1) if has_group else match.end(0)

    if is_in_safe_context(text, start, end):
        return None

    entity_type = pat.entity_type

    if entity_type == "bank_account":
        window_start = max(0, start - 60)
        window_end = min(len(text), end + 60)
        window = text[window_start:window_end]
        if not BANK_KEYWORDS.search(window):
            return None
        d = _digits_only(raw)
        if len(d) < 9 or len(d) > 18:
            return None
        if is_indian_mobile(raw):
            return None
        confidence = min(0.98, pat.confidence + 0.15)
        reason = "Digits near bank/account/IFSC keywords"
    elif entity_type == "phone":
        if not is_indian_mobile(raw) and not raw.startswith("+"):
            return None
        confidence = pat.confidence
        if has_phone_label_nearby(text, start, end):
            confidence = min(0.98, confidence + 0.1)
            reason = "Valid Indian mobile number"
        else:
            reason = "10-digit mobile pattern (6–9 prefix)"
    elif entity_type == "aadhaar":
        if not is_valid_aadhaar_digits(raw):
            return None
        window = text[max(0, start - 40) : min(len(text), end + 40)]
        if BANK_KEYWORDS.search(window) and not AADHAAR_LABEL.search(window):
            return None
        confidence = pat.confidence
        if AADHAAR_LABEL.search(window):
            confidence = min(0.97, confidence + 0.08)
            reason = "12-digit Aadhaar with label context"
        else:
            reason = "12-digit Aadhaar pattern"
    elif entity_type == "pan":
        if not is_valid_pan(raw):
            return None
        confidence = pat.confidence
        reason = "Valid PAN format"
        window = text[max(0, start - 30) : min(len(text), end + 30)]
        if PAN_LABEL.search(window):
            confidence = min(0.98, confidence + 0.05)
    elif entity_type == "payment_card":
        d = _digits_only(raw)
        if len(d) == 10 and is_indian_mobile(raw):
            return None
        if len(d) < 13:
            return None
        confidence = pat.confidence
        reason = "Card number pattern (13–19 digits)"
    elif entity_type == "passport":
        if is_indian_mobile(raw) or len(_digits_only(raw)) == 10:
            return None
        confidence = pat.confidence
        reason = "Passport number pattern"
    else:
        confidence = pat.confidence
        reason = f"Pattern match: {pat.name}"

    return ValidatedEntity(
        finding_type=entity_type,
        finding_value=mask_fn(raw, entity_type),
        risk_level=pat.risk_level,
        confidence=round(confidence, 3),
        detector="regex_validated",
        recommendation=recommend_fn(pat),
        reason=reason,
    )


def to_finding_dict(entity: ValidatedEntity) -> dict[str, Any]:
    return {
        "finding_type": entity.finding_type,
        "finding_value": entity.finding_value,
        "risk_level": entity.risk_level,
        "confidence": entity.confidence,
        "detector": entity.detector,
        "recommendation": entity.recommendation,
        "reason": entity.reason,
    }

"""Resume PII detection — regex + validation + optional spaCy NER."""
from __future__ import annotations

import logging
import re
from typing import Any

from backend.ai.resume_ai.entity_validator import to_finding_dict, validate_match
from backend.ai.utils.patterns import RESUME_PATTERNS, PatternDef
from backend.ai.utils.text_normalize import normalize_text
from backend.config import get_settings

logger = logging.getLogger(__name__)
_nlp: Any = None

SIGNATURE_HINTS = re.compile(
    r"\b(signature|signed\s*by|father'?s?\s*name|mother'?s?\s*name|"
    r"parent|guardian)\b",
    re.I,
)
ADDRESS_HINT = re.compile(
    r"\b(?:permanent\s*address|correspondence\s*address|"
    r"flat\s*no|pin\s*code|pincode)\b",
    re.I,
)

# Run higher-specificity patterns first (phone before generic digit patterns).
PATTERN_ORDER = [
    "aadhaar",
    "pan",
    "ifsc",
    "phone",
    "payment_card",
    "bank_account",
    "passport",
    "email",
    "date_of_birth",
]


def _pattern_sort_key(p: PatternDef) -> int:
    try:
        return PATTERN_ORDER.index(p.entity_type)
    except ValueError:
        return len(PATTERN_ORDER)


def _load_spacy():
    global _nlp
    settings = get_settings()
    if not settings.enable_spacy_ner:
        return None
    if _nlp is None:
        try:
            import spacy

            _nlp = spacy.load(settings.spacy_model)
        except Exception as exc:
            logger.warning("spaCy unavailable: %s", exc)
            _nlp = False
    return _nlp if _nlp is not False else None


def _mask_value(value: str, entity_type: str) -> str:
    if entity_type in ("aadhaar", "pan", "bank_account", "payment_card"):
        if len(value) > 4:
            return value[:2] + "*" * (len(value) - 4) + value[-2:]
    if entity_type == "email" and "@" in value:
        local, domain = value.split("@", 1)
        return (local[:2] + "***@" + domain) if len(local) > 2 else "***@" + domain
    if entity_type == "phone" and len(value) > 4:
        return value[:2] + "******" + value[-2:]
    return value[:3] + "…" if len(value) > 6 else "***"


def _recommendation_for(pat: PatternDef) -> str:
    tips = {
        "aadhaar": "Never include Aadhaar on internship resumes — high identity theft risk.",
        "pan": "Remove PAN unless explicitly required after offer acceptance.",
        "ifsc": "Bank/IFSC details should not appear on resumes shared with recruiters.",
        "bank_account": "Remove bank account numbers from all public application documents.",
        "passport": "Passport numbers should only be shared after verified employment.",
        "phone": "A phone number is normal on resumes; use a dedicated contact if concerned.",
        "email": "Prefer a professional email; avoid personal addresses on public uploads.",
        "payment_card": "Remove any card or payment identifiers immediately.",
        "date_of_birth": "Use graduation year only, or remove full date of birth.",
    }
    return tips.get(pat.entity_type, "Review and redact sensitive personal data.")


def detect_regex_entities(text: str) -> list[dict[str, Any]]:
    findings: list[dict[str, Any]] = []
    seen_spans: list[tuple[int, int]] = []

    def overlaps(start: int, end: int) -> bool:
        for s, e in seen_spans:
            if start < e and end > s:
                return True
        return False

    sorted_patterns = sorted(RESUME_PATTERNS, key=_pattern_sort_key)

    for pat in sorted_patterns:
        for m in pat.regex.finditer(text):
            has_group = m.lastindex is not None and m.lastindex >= 1
            start = m.start(1) if has_group else m.start(0)
            end = m.end(1) if has_group else m.end(0)
            if overlaps(start, end):
                continue
            entity = validate_match(
                text,
                m,
                pat,
                mask_fn=_mask_value,
                recommend_fn=_recommendation_for,
            )
            if not entity:
                continue
            seen_spans.append((start, end))
            findings.append(to_finding_dict(entity))

    if SIGNATURE_HINTS.search(text):
        findings.append(
            {
                "finding_type": "signature",
                "finding_value": "signature_or_parent_block",
                "risk_level": "high",
                "confidence": 0.75,
                "detector": "heuristic",
                "recommendation": "Remove scanned signatures and parent/guardian details from internship resumes.",
                "reason": "Signature or parent/guardian keywords detected",
            }
        )
    if ADDRESS_HINT.search(text):
        findings.append(
            {
                "finding_type": "full_address",
                "finding_value": "address_block_detected",
                "risk_level": "high",
                "confidence": 0.72,
                "detector": "heuristic",
                "recommendation": "Use city/state only; avoid full street addresses on public resumes.",
                "reason": "Full address block keywords detected",
            }
        )
    return findings


def detect_ner_entities(text: str) -> list[dict[str, Any]]:
    """spaCy NER — PERSON only; skip DATE to avoid experience-year false positives."""
    nlp = _load_spacy()
    if not nlp or len(text) < 10:
        return []
    findings: list[dict[str, Any]] = []
    doc = nlp(text[:100_000])
    for ent in doc.ents:
        if ent.label_ == "PERSON" and len(ent.text) > 2:
            findings.append(
                {
                    "finding_type": "person_name",
                    "finding_value": ent.text[:40],
                    "risk_level": "low",
                    "confidence": 0.45,
                    "detector": "spacy_ner",
                    "recommendation": "Name on resume is expected; ensure other PII is minimized.",
                    "reason": "spaCy PERSON entity (informational)",
                }
            )
    return findings[:5]


def detect_all(text: str) -> list[dict[str, Any]]:
    normalized = normalize_text(text)
    regex_findings = detect_regex_entities(normalized)
    ner_findings = detect_ner_entities(normalized)
    merged: dict[str, dict] = {}
    for f in regex_findings + ner_findings:
        if f.get("finding_type") == "person_name":
            continue
        key = f"{f['finding_type']}:{f['finding_value']}"
        if key not in merged or f.get("confidence", 0) > merged[key].get("confidence", 0):
            merged[key] = f
    return list(merged.values())

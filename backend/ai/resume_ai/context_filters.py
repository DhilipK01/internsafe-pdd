"""Exclude benign resume contexts from PII/risk detection (experience, CGPA, etc.)."""
from __future__ import annotations

import re

# Numeric spans in these contexts must NOT be classified as bank/PII risks.
SAFE_CONTEXT_PATTERNS: list[re.Pattern[str]] = [
    re.compile(
        r"\b\d+\+?\s*(?:years?|yrs?|months?|mos?)\s*(?:of\s+)?(?:experience|exp\.?)\b",
        re.I,
    ),
    re.compile(r"\b(?:experience|exp\.?)\s*[:\-]?\s*\d+\+?\s*(?:years?|yrs?|months?)?\b", re.I),
    re.compile(r"\b\d+(?:\.\d+)?\s*(?:years?|yrs?)\s*(?:in|of|at)\b", re.I),
    re.compile(r"\b(?:cgpa|gpa)\s*[:\-]?\s*\d+(?:\.\d+)?\s*(?:/\s*\d+)?\b", re.I),
    re.compile(r"\b\d+(?:\.\d+)?\s*%\b"),
    re.compile(r"\b(?:scored?|marks?|percentage)\s*[:\-]?\s*\d+(?:\.\d+)?\s*%?\b", re.I),
    re.compile(r"\b(?:class|grade)\s*(?:x|xii|12|10)\b", re.I),
    re.compile(r"\b(?:batch|graduat(?:ed|ing)|passing\s*year)\s*[:\-]?\s*\d{4}\b", re.I),
    re.compile(r"\b\d{4}\s*[-–]\s*\d{4}\b"),  # 2020-2024 education
    re.compile(r"\b(?:project|internship|certification)s?\s+(?:completed|duration)\b", re.I),
    re.compile(r"\b(?:achieved|completed|led|built|developed)\s+\d+\+?\b", re.I),
    re.compile(r"\b(?:team\s*size|users?|clients?|projects?)\s*[:\-]?\s*\d+\+?\b", re.I),
]

PHONE_LABEL = re.compile(
    r"\b(?:phone|mobile|mob|contact|whatsapp|tel|cell)\s*[:\-#]?\s*",
    re.I,
)


def is_in_safe_context(text: str, start: int, end: int, *, padding: int = 40) -> bool:
    window_start = max(0, start - padding)
    window_end = min(len(text), end + padding)
    window = text[window_start:window_end]
    rel_start = start - window_start
    rel_end = end - window_start
    for pat in SAFE_CONTEXT_PATTERNS:
        for m in pat.finditer(window):
            if m.start() <= rel_start and m.end() >= rel_end:
                return True
            if m.start() <= rel_end and m.end() >= rel_start:
                return True
    return False


def has_phone_label_nearby(text: str, start: int, end: int, *, padding: int = 30) -> bool:
    window_start = max(0, start - padding)
    window = text[window_start:end]
    return bool(PHONE_LABEL.search(window))

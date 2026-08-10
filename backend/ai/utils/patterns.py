"""India-specific PII / fraud regex patterns — deterministic detection."""
import re
from dataclasses import dataclass


@dataclass(frozen=True)
class PatternDef:
    name: str
    regex: re.Pattern[str]
    risk_level: str
    entity_type: str
    confidence: float = 0.92


def _compile(pattern: str, flags: int = re.IGNORECASE) -> re.Pattern[str]:
    return re.compile(pattern, flags)


# Aadhaar: 12 digits, optional spaces; Verhoeff not enforced (OCR noise)
AADHAAR = PatternDef(
    "aadhaar",
    _compile(r"\b(?:\d{4}[\s-]?){2}\d{4}\b"),
    "critical",
    "aadhaar",
    0.88,
)

PAN = PatternDef(
    "pan",
    _compile(r"\b[A-Z]{5}[0-9]{4}[A-Z]\b"),
    "high",
    "pan",
    0.95,
)

IFSC = PatternDef(
    "ifsc",
    _compile(r"\b[A-Z]{4}0[A-Z0-9]{6}\b"),
    "critical",
    "ifsc",
    0.93,
)

BANK_ACCOUNT = PatternDef(
    "bank_account",
    _compile(
        r"\b(?:bank\s*)?(?:account|a/c|acct)\s*(?:no|number|#)?[:\s]*(\d{9,18})\b"
    ),
    "critical",
    "bank_account",
    0.75,
)

PASSPORT = PatternDef(
    "passport",
    _compile(r"\b[A-Z][0-9]{7}\b"),
    "critical",
    "passport",
    0.7,
)

PHONE_IN = PatternDef(
    "phone",
    _compile(r"\b(?:\+91[\s-]?)?[6-9]\d{9}\b"),
    "medium",
    "phone",
    0.85,
)

EMAIL = PatternDef(
    "email",
    _compile(r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b"),
    "medium",
    "email",
    0.9,
)

CARD = PatternDef(
    "card",
    _compile(r"\b(?:\d{4}[\s-]?){3}\d{4}\b"),
    "critical",
    "payment_card",
    0.8,
)

DOB_FULL = PatternDef(
    "dob",
    _compile(
        r"\b(?:dob|date\s*of\s*birth)[:\s]*(\d{1,2}[/\-.]\d{1,2}[/\-.]\d{2,4})\b"
    ),
    "high",
    "date_of_birth",
    0.85,
)

RESUME_PATTERNS: list[PatternDef] = [
    AADHAAR,
    PAN,
    IFSC,
    BANK_ACCOUNT,
    PASSPORT,
    PHONE_IN,
    EMAIL,
    CARD,
    DOB_FULL,
]

# Offer fraud indicators
SUSPICIOUS_EMAIL = _compile(
    r"\b[\w.+-]+@(gmail|yahoo|hotmail|outlook|protonmail|rediffmail)\.com\b",
    re.I,
)
PAYMENT_REQUEST = _compile(
    r"\b(registration\s*fee|processing\s*fee|security\s*deposit|"
    r"verification\s*(?:fee|payment)|refundable\s*fee|training\s*fee|"
    r"laptop\s*deposit|slot\s*confirmation\s*fee|"
    r"pay\s*(?:rs|inr|₹)|payment\s*link|wire\s*transfer|bank\s*transfer)\b",
    re.I,
)
URGENCY = _compile(
    r"\b(urgent|immediately|last\s*chance|limited\s*slots|act\s*now|"
    r"within\s*24\s*hours?|hurry|offer\s*expires|confirm\s*slot\s*now|"
    r"direct\s*selection|no\s*interview\s*required|immediate\s*payment)\b",
    re.I,
)
UNREALISTIC_PAY = _compile(
    r"\b(?:₹|rs\.?|inr)\s*(\d{1,3}(?:,\d{3})+|\d{4,})\s*"
    r"(?:per\s*month|/month|pm|stipend|monthly)\b",
    re.I,
)
NO_INTERVIEW = _compile(
    r"\b(no\s*interview|without\s*interview|direct\s*selection|"
    r"instant\s*offer|selected\s*candidates\s*must|skip\s*interview)\b",
    re.I,
)
AADHAAR_EARLY = _compile(
    r"\b(send\s*(?:your\s*)?aadhaar|share\s*aadhaar|aadhaar\s*copy|"
    r"aadhaar\s*before\s*interview|upload\s*aadhaar)\b",
    re.I,
)
PAN_EARLY = _compile(
    r"\b(share\s*pan|send\s*pan\s*card|pan\s*before|upload\s*pan)\b",
    re.I,
)
CRYPTO_PAY = _compile(r"\b(bitcoin|usdt|crypto\s*wallet|ethereum)\b", re.I)
MANIPULATION = _compile(
    r"\b(limited\s*seats|confirm\s*slot|offer\s*expires\s*today|"
    r"refundable\s*payment|guaranteed\s*internship|100%\s*placement)\b",
    re.I,
)
WHATSAPP_ONLY = _compile(r"\b(whatsapp|wa\.me|contact\s*on\s*whatsapp)\b", re.I)
FAKE_AUTHORITY = _compile(
    r"\b(ceo\s*personally|government\s*approved\s*scheme|"
    r"guaranteed\s*placement|100%\s*job\s*guarantee)\b",
    re.I,
)

# Offer / fraud clustering only — NOT in RESUME_PATTERNS (avoids email false positives)
UPI = PatternDef(
    "upi",
    _compile(
        r"\b[\w][\w.-]{1,}@(?:ybl|oksbi|okaxis|okicici|paytm|axl|ibl|okhdfc|upi)\b",
        re.I,
    ),
    "high",
    "upi_id",
    0.85,
)

"""Deterministic offer fraud rules — never randomized."""
from __future__ import annotations

import re
from typing import Any
from urllib.parse import urlparse

from backend.ai.utils.patterns import (
    AADHAAR_EARLY,
    CRYPTO_PAY,
    FAKE_AUTHORITY,
    MANIPULATION,
    NO_INTERVIEW,
    PAN_EARLY,
    PAYMENT_REQUEST,
    SUSPICIOUS_EMAIL,
    UNREALISTIC_PAY,
    URGENCY,
    WHATSAPP_ONLY,
    UPI,
)

SUSPICIOUS_LINK = re.compile(
    r"https?://[^\s<>\"']+",
    re.I,
)
SHORTENER = re.compile(r"\b(bit\.ly|tinyurl|t\.co|goo\.gl|rb\.gy|cutt\.ly)\b", re.I)
FAKE_DEADLINE = re.compile(
    r"\b(offer\s*expires|last\s*date|deadline)\s*(?:today|tonight|in\s*\d+\s*hours?)\b",
    re.I,
)
BANK_TRANSFER = re.compile(
    r"\b(neft|rtgs|imps|account\s*transfer|transfer\s*to\s*account)\b",
    re.I,
)
GPay_PHONEPE = re.compile(
    r"\b(google\s*pay|gpay|phonepe|paytm|bhim)\b",
    re.I,
)


def analyze_rules(text: str) -> list[dict[str, Any]]:
    findings: list[dict[str, Any]] = []
    lower = text.lower()
    has_payment = bool(PAYMENT_REQUEST.search(text))
    has_gmail = bool(SUSPICIOUS_EMAIL.search(text))

    if has_gmail:
        findings.append(
            {
                "rule_id": "personal_email_domain",
                "label": "Personal email domain used (Gmail/Yahoo/etc.)",
                "risk_level": "high" if has_payment else "medium",
                "confidence": 0.9,
                "evidence": SUSPICIOUS_EMAIL.search(text).group(0)[:80],
            }
        )

    if has_payment:
        findings.append(
            {
                "rule_id": "payment_request",
                "label": "Payment or fee demand detected",
                "risk_level": "critical",
                "confidence": 0.96,
                "evidence": PAYMENT_REQUEST.search(text).group(0)[:80],
            }
        )

    upi_match = UPI.regex.search(text)
    if upi_match:
        findings.append(
            {
                "rule_id": "upi_payment",
                "label": "UPI/payment identifier detected",
                "risk_level": "critical",
                "confidence": 0.94,
                "evidence": upi_match.group(0)[:60],
            }
        )
    elif GPay_PHONEPE.search(text) and has_payment:
        findings.append(
            {
                "rule_id": "upi_payment",
                "label": "UPI app payment (GPay/PhonePe/Paytm) with fee context",
                "risk_level": "critical",
                "confidence": 0.9,
                "evidence": GPay_PHONEPE.search(text).group(0)[:60],
            }
        )

    if URGENCY.search(text):
        findings.append(
            {
                "rule_id": "urgency_manipulation",
                "label": "Urgency / pressure language",
                "risk_level": "high",
                "confidence": 0.88,
                "evidence": URGENCY.search(text).group(0)[:60],
            }
        )

    if MANIPULATION.search(text):
        findings.append(
            {
                "rule_id": "manipulation_language",
                "label": "Manipulation or pressure tactics detected",
                "risk_level": "high",
                "confidence": 0.86,
                "evidence": MANIPULATION.search(text).group(0)[:80],
            }
        )

    m_pay = UNREALISTIC_PAY.search(text)
    if m_pay:
        amount_str = m_pay.group(1).replace(",", "")
        try:
            amount = int(amount_str)
            is_intern = any(
                w in lower
                for w in ("intern", "internship", "trainee", "fresher", "student")
            )
            threshold = 45_000 if is_intern else 100_000
            if amount >= threshold:
                findings.append(
                    {
                        "rule_id": "unrealistic_stipend"
                        if is_intern
                        else "unrealistic_compensation",
                        "label": (
                            "Unusually high stipend for internship"
                            if is_intern
                            else "Unusually high stated compensation"
                        ),
                        "risk_level": "high",
                        "confidence": 0.85,
                        "evidence": m_pay.group(0)[:80],
                    }
                )
        except ValueError:
            pass

    if WHATSAPP_ONLY.search(text):
        findings.append(
            {
                "rule_id": "whatsapp_only",
                "label": "WhatsApp-only communication channel",
                "risk_level": "high" if has_gmail or has_payment else "medium",
                "confidence": 0.88,
                "evidence": WHATSAPP_ONLY.search(text).group(0)[:60],
            }
        )

    if NO_INTERVIEW.search(text):
        findings.append(
            {
                "rule_id": "no_interview_process",
                "label": "No interview / direct selection claimed",
                "risk_level": "high",
                "confidence": 0.87,
                "evidence": NO_INTERVIEW.search(text).group(0)[:80],
            }
        )

    if AADHAAR_EARLY.search(text):
        findings.append(
            {
                "rule_id": "aadhaar_before_interview",
                "label": "Aadhaar requested before interview/onboarding",
                "risk_level": "critical",
                "confidence": 0.93,
                "evidence": AADHAAR_EARLY.search(text).group(0)[:80],
            }
        )

    if PAN_EARLY.search(text):
        findings.append(
            {
                "rule_id": "pan_before_onboarding",
                "label": "PAN requested unusually early",
                "risk_level": "high",
                "confidence": 0.88,
                "evidence": PAN_EARLY.search(text).group(0)[:80],
            }
        )

    if CRYPTO_PAY.search(text):
        findings.append(
            {
                "rule_id": "crypto_payment",
                "label": "Cryptocurrency payment mentioned",
                "risk_level": "critical",
                "confidence": 0.95,
                "evidence": CRYPTO_PAY.search(text).group(0)[:60],
            }
        )

    if BANK_TRANSFER.search(text) and has_payment:
        findings.append(
            {
                "rule_id": "bank_transfer_request",
                "label": "Bank transfer requested with fee/payment context",
                "risk_level": "critical",
                "confidence": 0.9,
                "evidence": BANK_TRANSFER.search(text).group(0)[:60],
            }
        )

    if FAKE_AUTHORITY.search(text):
        findings.append(
            {
                "rule_id": "fake_authority",
                "label": "Misleading authority or guarantee claims",
                "risk_level": "high",
                "confidence": 0.87,
                "evidence": FAKE_AUTHORITY.search(text).group(0)[:80],
            }
        )

    if FAKE_DEADLINE.search(text):
        findings.append(
            {
                "rule_id": "suspicious_deadline",
                "label": "Artificial deadline pressure",
                "risk_level": "high",
                "confidence": 0.84,
                "evidence": FAKE_DEADLINE.search(text).group(0)[:80],
            }
        )

    for url in SUSPICIOUS_LINK.findall(text)[:10]:
        try:
            host = urlparse(url).netloc.lower()
        except Exception:
            continue
        if SHORTENER.search(url):
            findings.append(
                {
                    "rule_id": "url_shortener",
                    "label": "URL shortener link detected",
                    "risk_level": "high",
                    "confidence": 0.86,
                    "evidence": url[:120],
                }
            )
        if host and not any(
            t in host for t in (".com", ".in", ".org", ".io", ".co")
        ):
            findings.append(
                {
                    "rule_id": "unusual_domain",
                    "label": f"Unusual link domain: {host}",
                    "risk_level": "medium",
                    "confidence": 0.7,
                    "evidence": url[:120],
                }
            )

    return findings

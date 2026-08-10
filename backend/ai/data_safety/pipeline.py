"""Data Safety Advisor — stage-aware document risk classification."""
from __future__ import annotations

from typing import Any

STAGES = {
    "initial application",
    "after shortlisting",
    "after interview",
    "after offer letter",
    "after joining",
}

# User-facing labels from Flutter → canonical keys
LABEL_MAP: dict[str, str] = {
    "full aadhaar number": "aadhaar",
    "pan card": "pan",
    "bank account details": "bank_account",
    "passport copy": "passport",
    "college id": "college_id",
    "resume / cv": "resume",
    "resume": "resume",
    "linkedin profile": "linkedin",
    "phone number": "phone",
    "email address": "email",
    "home address": "address",
    "parent contact": "parent_contact",
    "processing fee payment": "payment_fee",
    "social media passwords": "passwords",
    "biometric data": "biometric",
}

ITEM_META: dict[str, dict[str, str]] = {
    "resume": {
        "default": "share_later",
        "safe_now_initial": "safe_now",
        "explanation": "A tailored resume/CV is required for applications.",
        "when_safe": "Share a version without Aadhaar, PAN, or bank details.",
        "alternative": "PDF resume with name, email, phone, education, projects only.",
    },
    "linkedin": {
        "default": "safe_now",
        "explanation": "Public professional profile is standard for recruiting.",
        "when_safe": "Now — keep profile professional and public.",
        "alternative": "Share profile URL only; hide phone until interview stage.",
    },
    "email": {
        "default": "safe_now",
        "explanation": "Recruiters need a contact email.",
        "when_safe": "Use a professional email address.",
        "alternative": "Dedicated internship email separate from personal inbox.",
    },
    "phone": {
        "default": "safe_now",
        "explanation": "Phone contact is normal after initial screening.",
        "when_safe": "After shortlisting or interview scheduling.",
        "alternative": "Google Voice / secondary number until offer stage.",
    },
    "college_id": {
        "default": "share_later",
        "explanation": "College ID verifies student status.",
        "when_safe": "After shortlisting or HR onboarding — not in first message.",
        "alternative": "Bonafide letter from college instead of ID scan.",
    },
    "aadhaar": {
        "default": "never_share",
        "explanation": "Aadhaar is government ID — high identity theft risk if leaked.",
        "when_safe": "Only after verified offer + official HR onboarding.",
        "alternative": "Never over email/WhatsApp; use secure employer portal.",
    },
    "pan": {
        "default": "never_share",
        "explanation": "PAN enables tax/financial identity abuse.",
        "when_safe": "After signed offer letter and verified company HR.",
        "alternative": "Masked PAN preview only if legally required.",
    },
    "bank_account": {
        "default": "never_share",
        "explanation": "Bank details enable direct financial fraud.",
        "when_safe": "After joining and payroll setup via official channel.",
        "alternative": "Never for 'registration fees' — legitimate jobs don't ask upfront.",
    },
    "passport": {
        "default": "never_share",
        "explanation": "Passport is critical identity document.",
        "when_safe": "International roles only, after verified offer.",
        "alternative": "Not required for domestic internships.",
    },
    "address": {
        "default": "share_later",
        "explanation": "Full home address increases stalking/doxxing risk.",
        "when_safe": "City/state is enough initially; full address after offer.",
        "alternative": "List city + state only on applications.",
    },
    "parent_contact": {
        "default": "never_share",
        "explanation": "Parent/guardian contacts are not required by legitimate recruiters early.",
        "when_safe": "Rarely needed; only if official background verification after joining.",
        "alternative": "Decline unless verified HR from known company.",
    },
    "payment_fee": {
        "default": "never_share",
        "explanation": "Upfront payment requests are a top internship scam signal.",
        "when_safe": "Never — legitimate employers do not charge application fees.",
        "alternative": "Report and block if payment is demanded before joining.",
    },
    "passwords": {
        "default": "never_share",
        "explanation": "Passwords must never be shared with anyone.",
        "when_safe": "Never.",
        "alternative": "Use official SSO; never send credentials over chat.",
    },
    "biometric": {
        "default": "never_share",
        "explanation": "Biometric data cannot be rotated if compromised.",
        "when_safe": "Only in-person at verified office if legally required.",
        "alternative": "Refuse remote biometric collection.",
    },
}

STAGE_ADJUSTMENTS: dict[str, dict[str, str]] = {
    "initial application": {
        "phone": "share_later",
        "email": "safe_now",
        "college_id": "never_share",
    },
    "after shortlisting": {
        "phone": "safe_now",
        "college_id": "share_later",
    },
    "after interview": {
        "college_id": "share_later",
        "address": "share_later",
    },
    "after offer letter": {
        "pan": "share_later",
        "bank_account": "share_later",
    },
    "after joining": {
        "aadhaar": "share_later",
        "pan": "share_later",
        "bank_account": "share_later",
    },
}


def _normalize_stage(stage: str) -> str:
    return stage.strip().lower()


def _normalize_label(label: str) -> str:
    key = label.strip().lower()
    return LABEL_MAP.get(key, key.replace(" ", "_"))


def _category_for(item_key: str, stage: str) -> str:
    meta = ITEM_META.get(item_key, {"default": "share_later"})
    stage_key = _normalize_stage(stage)
    stage_rules = STAGE_ADJUSTMENTS.get(stage_key, {})
    if item_key in stage_rules:
        return stage_rules[item_key]
    if stage_key == "initial application" and meta.get("safe_now_initial"):
        return meta["safe_now_initial"]
    return meta.get("default", "share_later")


def analyze_data_safety(stage: str, requested_labels: list[str]) -> dict[str, Any]:
    stage_norm = _normalize_stage(stage)
    safe_now: list[dict[str, str]] = []
    share_later: list[dict[str, str]] = []
    never_share: list[dict[str, str]] = []
    warnings: list[str] = []

    for label in requested_labels:
        item_key = _normalize_label(label)
        meta = ITEM_META.get(
            item_key,
            {
                "default": "share_later",
                "explanation": "Review whether this data is necessary at your current stage.",
                "when_safe": "When the employer is verified and the stage requires it.",
                "alternative": "Ask for written policy from HR.",
            },
        )
        category = _category_for(item_key, stage_norm)
        entry = {
            "label": label,
            "item_key": item_key,
            "category": category,
            "why_risky": meta.get("explanation", ""),
            "when_safe": meta.get("when_safe", ""),
            "safer_alternative": meta.get("alternative", ""),
        }
        if category == "safe_now":
            safe_now.append(entry)
        elif category == "never_share":
            never_share.append(entry)
            if item_key in ("payment_fee", "passwords", "aadhaar"):
                warnings.append(f"Never share '{label}' — common scam indicator.")
        else:
            share_later.append(entry)

    if "payment_fee" in [_normalize_label(x) for x in requested_labels]:
        warnings.append(
            "Legitimate companies do not ask for registration or processing fees before joining."
        )

    summary_parts = [
        f"Guidance for stage: {stage}.",
        f"{len(safe_now)} safe now, {len(share_later)} share later, {len(never_share)} never share early.",
    ]
    if never_share:
        summary_parts.append(
            "Withhold identity and financial documents until the employer is verified and the stage requires it."
        )

    return {
        "status": "completed",
        "stage": stage,
        "safe_now": safe_now,
        "share_later": share_later,
        "never_share": never_share,
        "warnings": warnings,
        "recommendation_summary": " ".join(summary_parts),
        "next_action": _next_action(stage_norm, never_share, warnings),
    }


def _next_action(stage: str, never_share: list, warnings: list) -> str:
    if warnings:
        return "Do not pay any fee or share passwords. Verify the company via INTERNSAFE Company Verifier."
    if never_share and stage == "initial application":
        return "Reply with resume/LinkedIn only. Politely decline Aadhaar, PAN, bank, or fee requests."
    if stage == "after offer letter":
        return "Verify offer letter and company domain before sharing PAN/bank details with HR."
    return "Share only what matches your current application stage."

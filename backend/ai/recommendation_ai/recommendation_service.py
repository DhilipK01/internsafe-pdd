"""LLM recommendation layer — explains findings only, never fabricates scores."""
from __future__ import annotations

import json
import logging
from pathlib import Path
from typing import Any

from backend.config import get_settings

logger = logging.getLogger(__name__)
PROMPTS_DIR = Path(__file__).resolve().parent.parent / "prompts"


def _load_prompt(name: str) -> str:
    path = PROMPTS_DIR / name
    return path.read_text(encoding="utf-8") if path.exists() else ""


def _call_openai(system: str, user_payload: dict) -> dict[str, Any] | None:
    settings = get_settings()
    if not settings.openai_api_key:
        return None
    try:
        from openai import OpenAI

        client = OpenAI(api_key=settings.openai_api_key)
        resp = client.chat.completions.create(
            model=settings.openai_model,
            messages=[
                {"role": "system", "content": system},
                {"role": "user", "content": json.dumps(user_payload, ensure_ascii=False)},
            ],
            temperature=0.2,
            response_format={"type": "json_object"},
        )
        content = resp.choices[0].message.content or "{}"
        return json.loads(content)
    except Exception as exc:
        logger.warning("OpenAI recommendation failed: %s", exc)
        return None


def _call_gemini(system: str, user_payload: dict) -> dict[str, Any] | None:
    settings = get_settings()
    if not settings.gemini_api_key:
        return None
    try:
        import google.generativeai as genai

        genai.configure(api_key=settings.gemini_api_key)
        model = genai.GenerativeModel(settings.gemini_model)
        prompt = f"{system}\n\nUser data:\n{json.dumps(user_payload, ensure_ascii=False)}"
        resp = model.generate_content(
            prompt,
            generation_config={"temperature": 0.2, "response_mime_type": "application/json"},
        )
        return json.loads(resp.text or "{}")
    except Exception as exc:
        logger.warning("Gemini recommendation failed: %s", exc)
        return None


def _fallback_resume(findings: list[dict], safety_score: int | None) -> dict[str, Any]:
    if not findings:
        return {
            "explanation": (
                "Automated scan did not detect common sensitive ID patterns. "
                "Still avoid sharing Aadhaar, full bank details, or signatures unless required after verification."
            ),
            "action_items": [
                "Use a professional email and minimal contact details.",
                "Re-scan after redacting any IDs before sharing publicly.",
            ],
        }
    items = [f.get("recommendation", "") for f in findings if f.get("recommendation")]
    return {
        "explanation": (
            f"Detected {len(findings)} sensitive pattern(s). "
            f"Estimated safety score from rules: {safety_score if safety_score is not None else 'N/A'}/100. "
            + " ".join(items[:3])
        ),
        "action_items": items[:8] or ["Redact detected fields and upload again."],
    }


def _fallback_offer(reasons: list[str], risk_level: str) -> dict[str, Any]:
    if not reasons:
        return {
            "explanation": (
                "No strong rule-based fraud indicators were found in the submitted text. "
                "Independently verify the company, domain, and recruiter before sharing documents."
            ),
            "action_items": [
                "Confirm the offer email domain matches the official company website.",
                "Never pay registration or training fees for internships.",
            ],
        }
    rl = str(risk_level).replace("_", " ").upper()
    return {
        "explanation": (
            f"Automated verdict: {rl}. "
            f"Triggered checks include: {'; '.join(reasons[:6])}. "
            "Legitimate employers rarely demand upfront payments, UPI transfers before interviews, "
            "or WhatsApp-only contact from personal email addresses."
        ),
        "action_items": [
            "Do not pay any fee until the employer is independently verified.",
            "Avoid sharing Aadhaar, PAN, or bank details at application stage.",
            "Search the company on INTERNSAFE blacklist and official MCA records.",
        ],
    }


def explain_resume(findings: list[dict], safety_score: int | None, risk_level: str) -> dict[str, Any]:
    payload = {
        "findings": findings,
        "safety_score": safety_score,
        "risk_level": risk_level,
    }
    system = _load_prompt("resume_analysis.txt")
    settings = get_settings()
    if settings.llm_provider == "gemini":
        result = _call_gemini(system, payload)
    elif settings.llm_provider == "openai":
        result = _call_openai(system, payload)
    else:
        result = None
    return result or _fallback_resume(findings, safety_score)


def explain_offer(
    reasons: list[str],
    risk_level: str,
    rule_findings: list[dict],
    nlp_findings: list[dict],
) -> dict[str, Any]:
    payload = {
        "reasons": reasons,
        "risk_level": risk_level,
        "rule_findings": rule_findings,
        "nlp_findings": nlp_findings,
    }
    system = _load_prompt("fraud_explanation.txt")
    settings = get_settings()
    if settings.llm_provider == "gemini":
        result = _call_gemini(system, payload)
    elif settings.llm_provider == "openai":
        result = _call_openai(system, payload)
    else:
        result = None
    return result or _fallback_offer(reasons, risk_level)

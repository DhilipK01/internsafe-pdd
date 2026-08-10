"""Context-aware assistant — uses scan/blacklist context, no hallucinated scores."""
from __future__ import annotations

import json
import logging
from typing import Any

from backend.ai.recommendation_ai.recommendation_service import _call_gemini, _call_openai
from backend.config import get_settings

logger = logging.getLogger(__name__)

SYSTEM_PROMPT = """You are INTERNSAFE AI Assistant — internship fraud & data safety advisor for Indian students.

Rules:
- Use ONLY facts from the provided context (scan results, blacklist, company intel).
- Never invent fraud reports, trust scores, or detection results.
- If context is empty, give general safety guidance without claiming specific scan results.
- Refuse to help with bypassing security or sharing others' private data.
- Be concise (under 200 words unless listing action items).

Context JSON is authoritative for what was detected."""


def build_context_block(context: dict[str, Any]) -> str:
    return json.dumps(context, ensure_ascii=False, indent=0)[:12_000]


def reply(
    user_message: str,
    context: dict[str, Any],
    history: list[dict[str, str]] | None = None,
) -> dict[str, Any]:
    settings = get_settings()
    payload = {
        "context": context,
        "history": (history or [])[-10:],
        "user_message": user_message,
    }

    messages_user = json.dumps(payload, ensure_ascii=False)

    if settings.llm_provider == "openai" and settings.openai_api_key:
        try:
            from openai import OpenAI

            client = OpenAI(api_key=settings.openai_api_key)
            msgs = [{"role": "system", "content": SYSTEM_PROMPT}]
            for h in history or []:
                msgs.append({"role": h.get("role", "user"), "content": h.get("content", "")})
            msgs.append(
                {
                    "role": "user",
                    "content": f"Context:\n{build_context_block(context)}\n\nQuestion: {user_message}",
                }
            )
            resp = client.chat.completions.create(
                model=settings.openai_model,
                messages=msgs,
                temperature=0.3,
                max_tokens=600,
            )
            text = resp.choices[0].message.content or ""
            return {"reply": text.strip(), "source": "openai"}
        except Exception as exc:
            logger.warning("Assistant OpenAI error: %s", exc)

    if settings.llm_provider == "gemini" and settings.gemini_api_key:
        try:
            import google.generativeai as genai

            genai.configure(api_key=settings.gemini_api_key)
            model = genai.GenerativeModel(settings.gemini_model)
            prompt = f"{SYSTEM_PROMPT}\n\nContext:\n{build_context_block(context)}\n\nUser: {user_message}"
            resp = model.generate_content(prompt)
            return {"reply": (resp.text or "").strip(), "source": "gemini"}
        except Exception as exc:
            logger.warning("Assistant Gemini error: %s", exc)

    # Deterministic fallback from context
    scan = context.get("latest_scan") or {}
    if scan.get("risk_level") in ("high", "critical"):
        return {
            "reply": (
                f"Your latest scan shows {scan.get('risk_level')} risk. "
                f"Key signals: {', '.join((scan.get('reasons') or scan.get('findings') or [])[:3])}. "
                "Do not pay fees or share Aadhaar until you verify the employer independently."
            ),
            "source": "rules_fallback",
        }
    return {
        "reply": (
            "I can help interpret your INTERNSAFE scan results and internship safety steps. "
            "Upload an offer or resume for analysis, or ask about a specific red flag you've seen."
        ),
        "source": "default",
    }

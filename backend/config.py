"""Application configuration — loaded from environment."""
from __future__ import annotations

import logging
from functools import lru_cache
from typing import Any

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

logger = logging.getLogger(__name__)


def parse_env_bool(value: Any, *, default: bool = False) -> bool:
    """Parse Render/dashboard env strings into bool (true/false/1/0)."""
    if isinstance(value, bool):
        return value
    if value is None:
        return default
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        return bool(value)
    if isinstance(value, str):
        token = value.strip().lower().split()[0] if value.strip() else ""
        if token in ("true", "1", "yes", "on"):
            return True
        if token in ("false", "0", "no", "off"):
            return False
        if token:
            logger.warning(
                "Invalid boolean env value %r — using default %s",
                value,
                default,
            )
    return default


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_name: str = "internsafe-ai"
    debug: bool = False
    host: str = "0.0.0.0"
    port: int = 8000

    # Worker callback (Cloudflare API)
    worker_base_url: str = "http://127.0.0.1:8787"
    ai_service_secret: str = "change-me-in-production"

    # Redis / Celery
    redis_url: str = "redis://localhost:6379/0"
    celery_broker_url: str = "redis://localhost:6379/0"
    celery_result_backend: str = "redis://localhost:6379/1"

    # LLM — recommendations only (never generates scores)
    openai_api_key: str | None = None
    openai_model: str = "gpt-4o-mini"
    gemini_api_key: str | None = None
    gemini_model: str = "gemini-2.0-flash"
    llm_provider: str = "openai"  # openai | gemini | none

    # Model toggles (disable heavy models in constrained environments)
    enable_paddle_ocr: bool = True
    enable_spacy_ner: bool = True
    enable_transformers_nlp: bool = True
    enable_sentence_embeddings: bool = True
    spacy_model: str = "en_core_web_sm"

    # OCR
    ocr_min_confidence: float = 0.45
    max_file_bytes: int = 10 * 1024 * 1024

    # Embeddings
    embedding_model: str = "all-MiniLM-L6-v2"
    similarity_threshold: float = 0.82

    @field_validator(
        "debug",
        "enable_paddle_ocr",
        "enable_spacy_ner",
        "enable_transformers_nlp",
        "enable_sentence_embeddings",
        mode="before",
    )
    @classmethod
    def _coerce_bool_fields(cls, value: Any) -> bool:
        return parse_env_bool(value, default=False)


@lru_cache
def get_settings() -> Settings:
    return Settings()

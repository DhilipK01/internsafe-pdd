"""Embedding & similarity — sentence-transformers."""
from __future__ import annotations

import logging
from typing import Any

import numpy as np

from backend.config import get_settings

logger = logging.getLogger(__name__)
_model: Any = None


def _get_model():
    global _model
    settings = get_settings()
    if not settings.enable_sentence_embeddings:
        return None
    if _model is None:
        try:
            from sentence_transformers import SentenceTransformer

            _model = SentenceTransformer(settings.embedding_model)
        except Exception as exc:
            logger.warning("Embedding model unavailable: %s", exc)
            _model = False
    return _model if _model is not False else None


def embed_text(text: str) -> list[float] | None:
    model = _get_model()
    if not model or not text.strip():
        return None
    vec = model.encode(text[:8000], normalize_embeddings=True)
    return vec.tolist()


def cosine_similarity(a: list[float], b: list[float]) -> float:
    va = np.array(a, dtype=np.float32)
    vb = np.array(b, dtype=np.float32)
    return float(np.dot(va, vb))


def find_similar(
    query_embedding: list[float],
    corpus: list[dict[str, Any]],
    threshold: float | None = None,
    top_k: int = 5,
) -> list[dict[str, Any]]:
    settings = get_settings()
    th = threshold if threshold is not None else settings.similarity_threshold
    results = []
    for item in corpus:
        emb = item.get("embedding")
        if not emb:
            continue
        sim = cosine_similarity(query_embedding, emb)
        if sim >= th:
            results.append(
                {
                    "id": item.get("id"),
                    "similarity": round(sim, 4),
                    "source_type": item.get("source_type"),
                    "snippet": (item.get("text") or "")[:200],
                }
            )
    results.sort(key=lambda x: x["similarity"], reverse=True)
    return results[:top_k]

"""Backward-compatible entry — use trust_score_engine."""
from backend.ai.company_ai.trust_score_engine import compute_trust_score

__all__ = ["compute_trust_score"]

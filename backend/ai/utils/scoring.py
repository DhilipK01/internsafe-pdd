"""Deterministic risk aggregation — scores are never random."""
from __future__ import annotations

from typing import Literal

RiskLevel = Literal["low", "medium", "high", "critical", "unknown"]

SEVERITY_WEIGHT = {"low": 1, "medium": 2, "high": 4, "critical": 8}


def aggregate_risk(findings: list[dict]) -> tuple[int, RiskLevel, float]:
    """
    Returns (score 0-100, risk_level, confidence 0-1).
    Higher score = more dangerous for offers; for resumes lower safety_score = worse.
    """
    if not findings:
        return 0, "low", 0.5

    total_weight = 0.0
    weighted_sum = 0.0
    confidences: list[float] = []

    for f in findings:
        sev = f.get("risk_level", "medium")
        w = SEVERITY_WEIGHT.get(sev, 2)
        conf = float(f.get("confidence", 0.7))
        confidences.append(conf)
        weighted_sum += w * conf
        total_weight += w

    if total_weight <= 0:
        return 0, "unknown", 0.0

    raw = (weighted_sum / total_weight) * 12.5  # scale to ~0-100
    score = min(100, max(0, int(round(raw))))

    if score >= 75:
        level: RiskLevel = "critical"
    elif score >= 50:
        level = "high"
    elif score >= 25:
        level = "medium"
    else:
        level = "low"

    confidence = sum(confidences) / len(confidences) if confidences else 0.0
    return score, level, min(1.0, confidence)


def resume_safety_score(findings: list[dict]) -> tuple[int, RiskLevel, float]:
    """Resume: 100 = safe, 0 = critical exposure."""
    danger, level, conf = aggregate_risk(findings)
    safety = max(0, min(100, 100 - danger))
    if safety >= 85:
        rl: RiskLevel = "low"
    elif safety >= 65:
        rl = "medium"
    elif safety >= 40:
        rl = "high"
    else:
        rl = "critical"
    return safety, rl, conf

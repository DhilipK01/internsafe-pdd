"""AI Orchestrator — routes jobs to engines."""
from __future__ import annotations

import logging
from typing import Any

from backend.ai.pipelines.offer_pipeline import run_offer_pipeline
from backend.ai.pipelines.resume_pipeline import run_resume_pipeline
from backend.ai.company_ai.trust_engine import compute_trust_score
from backend.ai.company_ai.internet_intelligence import (
    gather_internet_intelligence,
    merge_company_intelligence,
)
from backend.ai.company_ai.community_intelligence import (
    build_community_intelligence,
    build_unified_recommendation,
)
from backend.ai.data_safety.pipeline import analyze_data_safety
from backend.ai.fraud_intelligence.clustering_engine import cluster_reports
from backend.ai.assistant_ai.assistant_service import reply

logger = logging.getLogger(__name__)


class AIOrchestrator:
    def process_resume(self, file_bytes: bytes, mime_type: str, file_name: str = "") -> dict[str, Any]:
        return run_resume_pipeline(file_bytes, mime_type, file_name)

    def process_offer(
        self,
        text: str | None = None,
        file_bytes: bytes | None = None,
        mime_type: str = "",
        file_name: str = "",
        blacklist_context: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        return run_offer_pipeline(text, file_bytes, mime_type, file_name, blacklist_context)

    def process_company_trust(self, context: dict[str, Any]) -> dict[str, Any]:
        company_name = (context.get("company_name") or "").strip()
        community = build_community_intelligence(context)
        logger.info(
            "process_company_trust company=%r reports=%d",
            company_name,
            community.get("total_reports"),
        )

        if not company_name:
            empty_intel = gather_internet_intelligence("")
            return {
                **compute_trust_score(context),
                "community_intelligence": community,
                "internet_intelligence": empty_intel,
                "recommendation": build_unified_recommendation(empty_intel, community),
            }

        internet = gather_internet_intelligence(company_name)
        base = compute_trust_score({**context, **community})
        merged = merge_company_intelligence({**context, **base}, internet)
        merged["community_intelligence"] = community
        merged["recommendation"] = build_unified_recommendation(
            internet, community
        )
        return merged

    def process_data_safety(self, stage: str, requested_labels: list[str]) -> dict[str, Any]:
        return analyze_data_safety(stage, requested_labels)

    def cluster_fraud_reports(self, reports: list[dict[str, Any]]) -> dict[str, Any]:
        return {"campaigns": cluster_reports(reports)}

    def assistant_chat(
        self,
        message: str,
        context: dict[str, Any],
        history: list[dict[str, str]] | None = None,
    ) -> dict[str, Any]:
        return reply(message, context, history)


orchestrator = AIOrchestrator()

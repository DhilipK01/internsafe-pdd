"""Posts AI results back to Cloudflare Worker internal API."""
from __future__ import annotations

import logging
from typing import Any

import httpx

from backend.config import get_settings

logger = logging.getLogger(__name__)


class WorkerCallbackClient:
    def __init__(self) -> None:
        self.settings = get_settings()
        self.base = self.settings.worker_base_url.rstrip("/")
        self.headers = {
            "Content-Type": "application/json",
            "X-AI-Service-Secret": self.settings.ai_service_secret,
        }

    def _post(self, path: str, body: dict[str, Any]) -> None:
        url = f"{self.base}{path}"
        try:
            with httpx.Client(timeout=60.0) as client:
                r = client.post(url, json=body, headers=self.headers)
                r.raise_for_status()
        except Exception as exc:
            logger.error("Callback to Worker failed %s: %s", path, exc)
            raise

    def post_resume_results(
        self,
        scan_id: str,
        resume_id: str,
        user_id: str,
        result: dict[str, Any],
    ) -> None:
        self._post(
            "/internal/ai/resume-complete",
            {
                "scanId": scan_id,
                "resumeId": resume_id,
                "userId": user_id,
                "result": result,
            },
        )

    def post_failure(
        self,
        scan_id: str,
        resume_id: str,
        error: str,
        job_type: str = "resume",
        user_id: str | None = None,
    ) -> None:
        self._post(
            "/internal/ai/job-failed",
            {
                "scanId": scan_id,
                "resumeId": resume_id,
                "userId": user_id,
                "jobType": job_type,
                "error": error[:500],
            },
        )

    def post_offer_results(
        self,
        offer_check_id: str,
        user_id: str,
        result: dict[str, Any],
    ) -> None:
        self._post(
            "/internal/ai/offer-complete",
            {
                "offerCheckId": offer_check_id,
                "userId": user_id,
                "result": result,
            },
        )

    def post_offer_failure(self, offer_check_id: str, error: str) -> None:
        self._post(
            "/internal/ai/offer-failed",
            {"offerCheckId": offer_check_id, "error": error[:500]},
        )

    def post_company_results(
        self,
        company_name: str,
        user_id: str | None,
        result: dict[str, Any],
    ) -> None:
        self._post(
            "/internal/ai/company-complete",
            {"companyName": company_name, "userId": user_id, "result": result},
        )

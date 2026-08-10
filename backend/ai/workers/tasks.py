"""Celery background tasks — AI processing + Worker callback."""
from __future__ import annotations

import base64
import logging
from typing import Any

from backend.ai.orchestrator import orchestrator
from backend.ai.workers.celery_app import celery_app
from backend.services.callback_client import WorkerCallbackClient

logger = logging.getLogger(__name__)


@celery_app.task(bind=True, name="ai.process_resume", max_retries=2)
def process_resume_task(self, job: dict[str, Any]) -> dict[str, Any]:
    client = WorkerCallbackClient()
    scan_id = job["scan_id"]
    resume_id = job["resume_id"]
    try:
        file_b64 = job.get("file_base64")
        if not file_b64:
            raise ValueError("No file content in job")
        data = base64.b64decode(file_b64)
        result = orchestrator.process_resume(
            data,
            job.get("mime_type", "application/pdf"),
            job.get("file_name", ""),
        )
        client.post_resume_results(
            scan_id=scan_id,
            resume_id=resume_id,
            user_id=job["user_id"],
            result=result,
        )
        return {"ok": True, "scan_id": scan_id}
    except Exception as exc:
        logger.exception("Resume task failed: %s", exc)
        client.post_failure(
            scan_id, resume_id, str(exc), job_type="resume", user_id=job.get("user_id")
        )
        raise


@celery_app.task(bind=True, name="ai.process_offer", max_retries=2)
def process_offer_task(self, job: dict[str, Any]) -> dict[str, Any]:
    client = WorkerCallbackClient()
    offer_id = job["offer_check_id"]
    try:
        file_bytes = None
        if job.get("file_base64"):
            file_bytes = base64.b64decode(job["file_base64"])
        result = orchestrator.process_offer(
            text=job.get("text"),
            file_bytes=file_bytes,
            mime_type=job.get("mime_type", ""),
            file_name=job.get("file_name", ""),
            blacklist_context=job.get("blacklist_context"),
        )
        client.post_offer_results(
            offer_check_id=offer_id,
            user_id=job["user_id"],
            result=result,
        )
        return {"ok": True, "offer_check_id": offer_id}
    except Exception as exc:
        logger.exception("Offer task failed: %s", exc)
        client.post_offer_failure(offer_id, str(exc))
        raise


@celery_app.task(name="ai.process_company")
def process_company_task(job: dict[str, Any]) -> dict[str, Any]:
    client = WorkerCallbackClient()
    result = orchestrator.process_company_trust(job.get("context", {}))
    client.post_company_results(
        company_name=job["company_name"],
        user_id=job.get("user_id"),
        result=result,
    )
    return result

"""INTERNSAFE AI Service — FastAPI entrypoint."""
from __future__ import annotations

import base64
import logging
from typing import Any

from fastapi import Depends, FastAPI, Header, HTTPException
from pydantic import BaseModel, Field

from backend.ai.orchestrator import orchestrator
from backend.config import get_settings

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="INTERNSAFE AI",
    description="Production AI processing layer for internship fraud protection",
    version="1.0.0",
)


def verify_secret(x_ai_service_secret: str = Header(default="")) -> None:
    settings = get_settings()
    if not settings.ai_service_secret or x_ai_service_secret != settings.ai_service_secret:
        raise HTTPException(status_code=401, detail="Unauthorized")


class ResumeJobRequest(BaseModel):
    scan_id: str
    resume_id: str
    user_id: str
    mime_type: str = "application/pdf"
    file_name: str = ""
    file_base64: str = Field(..., description="Base64-encoded file bytes")
    async_mode: bool = True


class OfferJobRequest(BaseModel):
    offer_check_id: str
    user_id: str
    text: str | None = None
    mime_type: str = ""
    file_name: str = ""
    file_base64: str | None = None
    blacklist_context: dict[str, Any] | None = None
    async_mode: bool = True


class CompanyJobRequest(BaseModel):
    company_name: str
    user_id: str | None = None
    context: dict[str, Any] = Field(default_factory=dict)
    async_mode: bool = True


class AssistantRequest(BaseModel):
    message: str
    context: dict[str, Any] = Field(default_factory=dict)
    history: list[dict[str, str]] = Field(default_factory=list)


class ClusterRequest(BaseModel):
    reports: list[dict[str, Any]]


class DataSafetyRequest(BaseModel):
    stage: str
    requested_data: list[str] = Field(default_factory=list, alias="requestedData")

    model_config = {"populate_by_name": True}


class CompanyVerifyRequest(BaseModel):
    company_name: str = Field(..., alias="companyName")
    context: dict[str, Any] = Field(default_factory=dict)

    model_config = {"populate_by_name": True}


@app.get("/")
def root() -> dict[str, Any]:
    """Public landing — confirms the AI API is up (not used by the mobile app)."""
    s = get_settings()
    return {
        "ok": True,
        "service": s.app_name,
        "message": "INTERNSAFE AI service is running.",
        "docs": "/docs",
        "health": "/health",
        "note": "Mobile app uses Cloudflare Worker; Worker calls this service with X-AI-Service-Secret.",
    }


@app.get("/health")
def health() -> dict[str, Any]:
    s = get_settings()
    return {
        "ok": True,
        "service": s.app_name,
        "llm_provider": s.llm_provider,
        "paddle_ocr": s.enable_paddle_ocr,
        "spacy_ner": s.enable_spacy_ner,
        "transformers_nlp": s.enable_transformers_nlp,
        "sentence_embeddings": s.enable_sentence_embeddings,
    }


@app.post("/jobs/resume", dependencies=[Depends(verify_secret)])
def enqueue_resume(req: ResumeJobRequest) -> dict[str, Any]:
    job = req.model_dump()
    if req.async_mode:
        from backend.ai.workers.tasks import process_resume_task

        task = process_resume_task.delay(job)
        return {"queued": True, "task_id": task.id, "scan_id": req.scan_id}
    data = base64.b64decode(req.file_base64)
    result = orchestrator.process_resume(data, req.mime_type, req.file_name)
    return {"queued": False, "result": result}


@app.post("/jobs/offer", dependencies=[Depends(verify_secret)])
def enqueue_offer(req: OfferJobRequest) -> dict[str, Any]:
    job = req.model_dump()
    if req.async_mode:
        from backend.ai.workers.tasks import process_offer_task

        task = process_offer_task.delay(job)
        return {"queued": True, "task_id": task.id, "offer_check_id": req.offer_check_id}
    fb = base64.b64decode(req.file_base64) if req.file_base64 else None
    result = orchestrator.process_offer(
        req.text, fb, req.mime_type, req.file_name, req.blacklist_context
    )
    return {"queued": False, "result": result}


@app.post("/jobs/company", dependencies=[Depends(verify_secret)])
def enqueue_company(req: CompanyJobRequest) -> dict[str, Any]:
    if req.async_mode:
        from backend.ai.workers.tasks import process_company_task

        task = process_company_task.delay(req.model_dump())
        return {"queued": True, "task_id": task.id}
    return {"queued": False, "result": orchestrator.process_company_trust(req.context)}


@app.post("/analyze/resume/sync", dependencies=[Depends(verify_secret)])
def sync_resume(req: ResumeJobRequest) -> dict[str, Any]:
    data = base64.b64decode(req.file_base64)
    return orchestrator.process_resume(data, req.mime_type, req.file_name)


@app.post("/analyze/offer/sync", dependencies=[Depends(verify_secret)])
def sync_offer(req: OfferJobRequest) -> dict[str, Any]:
    fb = base64.b64decode(req.file_base64) if req.file_base64 else None
    return orchestrator.process_offer(
        req.text, fb, req.mime_type, req.file_name, req.blacklist_context
    )


@app.post("/assistant/chat", dependencies=[Depends(verify_secret)])
def assistant_chat(req: AssistantRequest) -> dict[str, Any]:
    return orchestrator.assistant_chat(req.message, req.context, req.history)


@app.post("/fraud/cluster", dependencies=[Depends(verify_secret)])
def fraud_cluster(req: ClusterRequest) -> dict[str, Any]:
    return orchestrator.cluster_fraud_reports(req.reports)


@app.post("/analyze/data-safety", dependencies=[Depends(verify_secret)])
def analyze_data_safety_endpoint(req: DataSafetyRequest) -> dict[str, Any]:
    if not req.requested_data:
        raise HTTPException(status_code=400, detail="requestedData required")
    if not req.stage.strip():
        raise HTTPException(status_code=400, detail="stage required")
    return orchestrator.process_data_safety(req.stage, req.requested_data)


@app.post("/analyze/company", dependencies=[Depends(verify_secret)])
def analyze_company_endpoint(req: CompanyVerifyRequest) -> dict[str, Any]:
    ctx = {**req.context, "company_name": req.company_name.strip()}
    return orchestrator.process_company_trust(ctx)


if __name__ == "__main__":
    import uvicorn

    s = get_settings()
    uvicorn.run("backend.main:app", host=s.host, port=s.port, reload=s.debug)

import {
  aiConfigured,
  enqueueOfferAiJob,
  enqueueResumeAiJob,
  runOfferSync,
  runResumeSync,
  type AiServiceEnv,
} from './ai-client';
import type { DatabaseService } from './db/database-service';
import {
  applyOfferAiResult,
  applyResumeAiResult,
  type OfferAiResult,
  type ResumeAiResult,
} from './ai-results';
import { uuid } from './utils';

export type AiProcessOutcome = {
  status: 'completed' | 'processing' | 'pending_analysis' | 'failed';
  message: string;
  resultJson?: string;
};

function buildResumeResultPayload(result: ResumeAiResult): string {
  const findings = (result.findings ?? []).map((f) => ({
    finding_type: f.finding_type,
    finding_value: f.finding_value,
    risk_level: f.risk_level,
    recommendation: f.recommendation,
  }));
  return JSON.stringify({
    status: 'completed',
    safety_score: result.safety_score,
    risk_level: result.risk_level ?? 'unknown',
    findings,
    ai_recommendation: result.ai_recommendation,
    ocr_confidence: result.ocr?.confidence,
  });
}

export async function processResumeWithAi(
  env: AiServiceEnv,
  db: DatabaseService,
  params: {
    scanId: string;
    resumeId: string;
    userId: string;
    mimeType: string;
    fileName: string;
    fileBase64: string;
  },
): Promise<AiProcessOutcome> {
  if (!aiConfigured(env)) {
    return {
      status: 'pending_analysis',
      message:
        'AI service is not configured on the server. Set AI_SERVICE_URL and AI_SERVICE_SECRET, then try again.',
    };
  }

  const sync = await runResumeSync(env, params);
  if (sync.ok && sync.result) {
    const result = sync.result as ResumeAiResult;
    await applyResumeAiResult(db, params, result);
    const resultJson = buildResumeResultPayload(result);
    return {
      status: 'completed',
      message: 'Analysis complete.',
      resultJson,
    };
  }

  await db.markScanProcessing(params.scanId, params.resumeId);
  const queued = await enqueueResumeAiJob(env, params);
  if (queued?.queued) {
    await db.insertAiJob({
      id: uuid(),
      userId: params.userId,
      jobType: 'resume',
      referenceId: params.resumeId,
      scanId: params.scanId,
      celeryTaskId: queued.taskId,
    });
    return {
      status: 'processing',
      message: 'AI analysis is running. Results will appear when processing completes.',
    };
  }

  const detail = sync.error ? ` ${sync.error}` : '';
  return {
    status: 'pending_analysis',
    message: `Could not reach the AI service.${detail} Check that it is running and AI_SERVICE_URL is correct.`,
  };
}

export async function processOfferWithAi(
  env: AiServiceEnv,
  db: DatabaseService,
  params: {
    offerCheckId: string;
    userId: string;
    text?: string | null;
    mimeType?: string;
    fileName?: string;
    fileBase64?: string | null;
    blacklistContext?: Record<string, unknown>;
  },
): Promise<AiProcessOutcome> {
  if (!aiConfigured(env)) {
    return {
      status: 'pending_analysis',
      message:
        'AI service is not configured on the server. Set AI_SERVICE_URL and AI_SERVICE_SECRET, then try again.',
    };
  }

  if (!params.text?.trim() && !params.fileBase64) {
    return {
      status: 'pending_analysis',
      message: 'No offer text or file content available for analysis.',
    };
  }

  const sync = await runOfferSync(env, params);
  if (sync.ok && sync.result) {
    const result = sync.result as OfferAiResult;
    await applyOfferAiResult(db, params, result);
    return {
      status: 'completed',
      message: result.summary ?? 'Analysis complete.',
    };
  }

  await db.markOfferProcessing(params.offerCheckId);
  const queued = await enqueueOfferAiJob(env, params);
  if (queued?.queued) {
    await db.insertAiJob({
      id: uuid(),
      userId: params.userId,
      jobType: 'offer',
      referenceId: params.offerCheckId,
      celeryTaskId: queued.taskId,
    });
    return {
      status: 'processing',
      message: 'AI analysis is running. Results will appear when processing completes.',
    };
  }

  const detail = sync.error ? ` ${sync.error}` : '';
  return {
    status: 'pending_analysis',
    message: `Could not reach the AI service.${detail} Check that it is running and AI_SERVICE_URL is correct.`,
  };
}

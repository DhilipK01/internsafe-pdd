import { DatabaseService } from './db/database-service';
import { uuid } from './utils';
import { verifyAiSecret, type AiServiceEnv } from './ai-client';

type ResumeResult = {
  safety_score?: number | null;
  risk_level?: string;
  findings?: Array<{
    finding_type: string;
    finding_value: string;
    risk_level: string;
    recommendation?: string;
  }>;
  extracted_text?: string;
  ai_recommendation?: { explanation?: string; action_items?: string[] };
  ocr?: { confidence?: number };
  status?: string;
  message?: string;
  embedding?: number[] | null;
};

type OfferResult = {
  result?: string;
  risk_level?: string;
  confidence_score?: number;
  summary?: string;
  reasons_json?: string;
  extracted_text?: string;
  ai_recommendation?: { explanation?: string; action_items?: string[] };
  embedding?: number[] | null;
};

export async function handleInternalAi(
  request: Request,
  env: AiServiceEnv & { DB: D1Database },
  path: string,
  db: DatabaseService,
): Promise<Response | null> {
  if (!path.startsWith('/internal/ai/')) return null;
  if (!verifyAiSecret(request, env)) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 });
  }

  const body = (await request.json()) as Record<string, unknown>;

  if (path === '/internal/ai/resume-complete' && request.method === 'POST') {
    const scanId = String(body.scanId ?? '');
    const resumeId = String(body.resumeId ?? '');
    const userId = String(body.userId ?? '');
    const result = body.result as ResumeResult;

    const findings = (result.findings ?? []).map((f) => ({
      finding_type: f.finding_type,
      finding_value: f.finding_value,
      risk_level: f.risk_level,
      recommendation: f.recommendation,
    }));

    const resultPayload = {
      status: 'completed',
      safety_score: result.safety_score,
      risk_level: result.risk_level ?? 'unknown',
      findings,
      ai_recommendation: result.ai_recommendation,
      ocr_confidence: result.ocr?.confidence,
    };

    await db.completeResumeAnalysis({
      resumeId,
      scanId,
      userId,
      extractedText: result.extracted_text ?? null,
      safetyScore: result.safety_score ?? null,
      riskLevel: result.risk_level ?? 'unknown',
      resultJson: JSON.stringify(resultPayload),
      aiRecommendationJson: JSON.stringify(result.ai_recommendation ?? {}),
      ocrConfidence: result.ocr?.confidence ?? null,
      findings,
    });

    if (result.embedding?.length) {
      await db.storeEmbedding({
        id: uuid(),
        sourceType: 'resume',
        sourceId: resumeId,
        userId,
        textSnippet: (result.extracted_text ?? '').slice(0, 500),
        embeddingJson: JSON.stringify(result.embedding),
      });
    }

    await db.createNotification(
      userId,
      'Resume scan complete',
      `Analysis finished — risk level: ${result.risk_level ?? 'unknown'}`,
    );
    await db.logActivity(
      userId,
      'resume',
      'Resume scan complete',
      `Risk: ${result.risk_level}`,
      result.risk_level ?? 'Done',
      resumeId,
      'resume',
    );

    return new Response(JSON.stringify({ ok: true }), {
      headers: { 'Content-Type': 'application/json' },
    });
  }

  if (path === '/internal/ai/job-failed' && request.method === 'POST') {
    const scanId = String(body.scanId ?? '');
    const resumeId = String(body.resumeId ?? '');
    const userId = String(body.userId ?? '');
    const error = String(body.error ?? 'Processing failed');
    if (resumeId && scanId) {
      await db.failResumeAnalysis(resumeId, scanId, userId, error);
    }
    return new Response(JSON.stringify({ ok: true }), {
      headers: { 'Content-Type': 'application/json' },
    });
  }

  if (path === '/internal/ai/offer-complete' && request.method === 'POST') {
    const offerCheckId = String(body.offerCheckId ?? '');
    const userId = String(body.userId ?? '');
    const result = body.result as OfferResult;

    await db.completeOfferAnalysis({
      offerCheckId,
      userId,
      result: result.result ?? 'suspicious',
      status: 'completed',
      riskLevel: result.risk_level ?? 'unknown',
      confidenceScore: result.confidence_score ?? null,
      summary: result.summary ?? '',
      reasonsJson: result.reasons_json ?? '[]',
      extractedText: result.extracted_text ?? null,
      aiRecommendationJson: JSON.stringify(result.ai_recommendation ?? {}),
      embeddingJson: result.embedding ? JSON.stringify(result.embedding) : null,
    });

    if (result.embedding?.length) {
      await db.storeEmbedding({
        id: uuid(),
        sourceType: 'offer',
        sourceId: offerCheckId,
        userId,
        textSnippet: (result.extracted_text ?? '').slice(0, 500),
        embeddingJson: JSON.stringify(result.embedding),
      });
    }

    await db.createNotification(
      userId,
      'Offer analysis complete',
      result.summary?.slice(0, 120) ?? 'Your offer check is ready.',
    );

    return new Response(JSON.stringify({ ok: true }), {
      headers: { 'Content-Type': 'application/json' },
    });
  }

  if (path === '/internal/ai/offer-failed' && request.method === 'POST') {
    const offerCheckId = String(body.offerCheckId ?? '');
    const error = String(body.error ?? 'Failed');
    await db.failOfferAnalysis(offerCheckId, error);
    return new Response(JSON.stringify({ ok: true }), {
      headers: { 'Content-Type': 'application/json' },
    });
  }

  return new Response(JSON.stringify({ error: 'Not found' }), { status: 404 });
}

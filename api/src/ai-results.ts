import { DatabaseService } from './db/database-service';
import { uuid } from './utils';

export type ResumeAiResult = {
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
  embedding?: number[] | null;
};

export type OfferAiResult = {
  result?: string;
  risk_level?: string;
  confidence_score?: number;
  summary?: string;
  reasons_json?: string;
  extracted_text?: string;
  ai_recommendation?: { explanation?: string; action_items?: string[] };
  embedding?: number[] | null;
};

export async function applyResumeAiResult(
  db: DatabaseService,
  params: {
    resumeId: string;
    scanId: string;
    userId: string;
  },
  result: ResumeAiResult,
): Promise<void> {
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
    resumeId: params.resumeId,
    scanId: params.scanId,
    userId: params.userId,
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
      sourceId: params.resumeId,
      userId: params.userId,
      textSnippet: (result.extracted_text ?? '').slice(0, 500),
      embeddingJson: JSON.stringify(result.embedding),
    });
  }

  await db.createNotification(
    params.userId,
    'Resume scan complete',
    `Analysis finished — risk level: ${result.risk_level ?? 'unknown'}`,
  );
}

export async function applyOfferAiResult(
  db: DatabaseService,
  params: { offerCheckId: string; userId: string },
  result: OfferAiResult,
): Promise<void> {
  await db.completeOfferAnalysis({
    offerCheckId: params.offerCheckId,
    userId: params.userId,
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
      sourceId: params.offerCheckId,
      userId: params.userId,
      textSnippet: (result.extracted_text ?? '').slice(0, 500),
      embeddingJson: JSON.stringify(result.embedding),
    });
  }

  await db.createNotification(
    params.userId,
    'Offer analysis complete',
    result.summary?.slice(0, 120) ?? 'Your offer check is ready.',
  );
}

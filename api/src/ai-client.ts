/**
 * INTERNSAFE AI service client (sync + async enqueue).
 */
export interface AiServiceEnv {
  AI_SERVICE_URL?: string;
  AI_SERVICE_SECRET?: string;
}

const AI_FETCH_TIMEOUT_MS = 120_000;
/** Company verify: parallel web search — cap below Flutter client budget */
const COMPANY_VERIFY_AI_TIMEOUT_MS = 50_000;

async function aiFetch(
  env: AiServiceEnv,
  path: string,
  body: Record<string, unknown>,
  timeoutMs: number = AI_FETCH_TIMEOUT_MS,
): Promise<Response> {
  const base = env.AI_SERVICE_URL!.trim().replace(/\/$/, '');
  const secret = env.AI_SERVICE_SECRET!.trim();
  return fetch(`${base}${path}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-AI-Service-Secret': secret,
    },
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(timeoutMs),
  });
}

export function aiConfigured(env: AiServiceEnv): boolean {
  return Boolean(env.AI_SERVICE_URL?.trim() && env.AI_SERVICE_SECRET?.trim());
}

export async function runResumeSync(
  env: AiServiceEnv,
  payload: {
    scanId: string;
    resumeId: string;
    userId: string;
    mimeType: string;
    fileName: string;
    fileBase64: string;
  },
): Promise<{ ok: boolean; result?: Record<string, unknown>; error?: string }> {
  if (!aiConfigured(env)) {
    return { ok: false, error: 'AI not configured' };
  }
  try {
    const res = await aiFetch(env, '/jobs/resume', {
      scan_id: payload.scanId,
      resume_id: payload.resumeId,
      user_id: payload.userId,
      mime_type: payload.mimeType,
      file_name: payload.fileName,
      file_base64: payload.fileBase64,
      async_mode: false,
    });
    if (!res.ok) {
      const text = await res.text();
      return { ok: false, error: `AI HTTP ${res.status}: ${text.slice(0, 200)}` };
    }
    const data = (await res.json()) as { result?: Record<string, unknown> };
    if (!data.result) return { ok: false, error: 'Empty AI result' };
    return { ok: true, result: data.result };
  } catch (e) {
    return { ok: false, error: e instanceof Error ? e.message : String(e) };
  }
}

export async function runOfferSync(
  env: AiServiceEnv,
  payload: {
    offerCheckId: string;
    userId: string;
    text?: string | null;
    mimeType?: string;
    fileName?: string;
    fileBase64?: string | null;
    blacklistContext?: Record<string, unknown>;
  },
): Promise<{ ok: boolean; result?: Record<string, unknown>; error?: string }> {
  if (!aiConfigured(env)) {
    return { ok: false, error: 'AI not configured' };
  }
  try {
    const res = await aiFetch(env, '/jobs/offer', {
      offer_check_id: payload.offerCheckId,
      user_id: payload.userId,
      text: payload.text ?? null,
      mime_type: payload.mimeType ?? '',
      file_name: payload.fileName ?? '',
      file_base64: payload.fileBase64 ?? null,
      blacklist_context: payload.blacklistContext ?? null,
      async_mode: false,
    });
    if (!res.ok) {
      const text = await res.text();
      return { ok: false, error: `AI HTTP ${res.status}: ${text.slice(0, 200)}` };
    }
    const data = (await res.json()) as { result?: Record<string, unknown> };
    if (!data.result) return { ok: false, error: 'Empty AI result' };
    return { ok: true, result: data.result };
  } catch (e) {
    return { ok: false, error: e instanceof Error ? e.message : String(e) };
  }
}

export async function enqueueResumeAiJob(
  env: AiServiceEnv,
  payload: {
    scanId: string;
    resumeId: string;
    userId: string;
    mimeType: string;
    fileName: string;
    fileBase64: string;
  },
): Promise<{ queued: boolean; taskId?: string } | null> {
  if (!aiConfigured(env)) return null;

  const res = await aiFetch(env, '/jobs/resume', {
    scan_id: payload.scanId,
    resume_id: payload.resumeId,
    user_id: payload.userId,
    mime_type: payload.mimeType,
    file_name: payload.fileName,
    file_base64: payload.fileBase64,
    async_mode: true,
  });
  if (!res.ok) {
    console.error('AI resume enqueue failed', res.status, await res.text());
    return null;
  }
  const data = (await res.json()) as { queued?: boolean; task_id?: string };
  return { queued: Boolean(data.queued), taskId: data.task_id };
}

export async function enqueueOfferAiJob(
  env: AiServiceEnv,
  payload: {
    offerCheckId: string;
    userId: string;
    text?: string | null;
    mimeType?: string;
    fileName?: string;
    fileBase64?: string | null;
    blacklistContext?: Record<string, unknown>;
  },
): Promise<{ queued: boolean; taskId?: string } | null> {
  if (!aiConfigured(env)) return null;

  const res = await aiFetch(env, '/jobs/offer', {
    offer_check_id: payload.offerCheckId,
    user_id: payload.userId,
    text: payload.text ?? null,
    mime_type: payload.mimeType ?? '',
    file_name: payload.fileName ?? '',
    file_base64: payload.fileBase64 ?? null,
    blacklist_context: payload.blacklistContext ?? null,
    async_mode: true,
  });
  if (!res.ok) {
    console.error('AI offer enqueue failed', res.status, await res.text());
    return null;
  }
  const data = (await res.json()) as { queued?: boolean; task_id?: string };
  return { queued: Boolean(data.queued), taskId: data.task_id };
}

export function arrayBufferToBase64(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer);
  let binary = '';
  const chunk = 0x8000;
  for (let i = 0; i < bytes.length; i += chunk) {
    binary += String.fromCharCode(...bytes.subarray(i, i + chunk));
  }
  return btoa(binary);
}

export async function runDataSafetySync(
  env: AiServiceEnv,
  payload: { stage: string; requestedData: string[] },
): Promise<{ ok: boolean; result?: Record<string, unknown>; error?: string }> {
  if (!aiConfigured(env)) {
    return { ok: false, error: 'AI not configured' };
  }
  try {
    const res = await aiFetch(env, '/analyze/data-safety', {
      stage: payload.stage,
      requestedData: payload.requestedData,
    });
    if (!res.ok) {
      const text = await res.text();
      return { ok: false, error: `AI HTTP ${res.status}: ${text.slice(0, 200)}` };
    }
    const data = (await res.json()) as Record<string, unknown>;
    return { ok: true, result: data };
  } catch (e) {
    return { ok: false, error: e instanceof Error ? e.message : String(e) };
  }
}

export async function runCompanyVerifySync(
  env: AiServiceEnv,
  payload: {
    companyName: string;
    context: Record<string, unknown>;
  },
): Promise<{ ok: boolean; result?: Record<string, unknown>; error?: string }> {
  if (!aiConfigured(env)) {
    return { ok: false, error: 'AI not configured' };
  }
  const started = Date.now();
  try {
    const res = await aiFetch(
      env,
      '/analyze/company',
      {
        companyName: payload.companyName,
        context: payload.context,
      },
      COMPANY_VERIFY_AI_TIMEOUT_MS,
    );
    if (!res.ok) {
      const text = await res.text();
      console.error(
        '[company-verify] AI HTTP',
        res.status,
        text.slice(0, 300),
      );
      return { ok: false, error: `AI HTTP ${res.status}: ${text.slice(0, 200)}` };
    }
    const data = (await res.json()) as Record<string, unknown>;
    console.info(
      '[company-verify] AI ok company=%s ms=%d',
      payload.companyName,
      Date.now() - started,
    );
    return { ok: true, result: data };
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    console.error(
      '[company-verify] AI failed company=%s ms=%d err=%s',
      payload.companyName,
      Date.now() - started,
      msg,
    );
    return { ok: false, error: msg };
  }
}

export function verifyAiSecret(request: Request, env: AiServiceEnv): boolean {
  const secret = env.AI_SERVICE_SECRET?.trim();
  if (!secret) return false;
  return request.headers.get('X-AI-Service-Secret') === secret;
}

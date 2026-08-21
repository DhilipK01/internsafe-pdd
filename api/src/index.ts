import { DatabaseService } from './db/database-service';
import {
  appDeepLink,
  appleAppSiteAssociation,
  assetLinksJson,
  buildShareSnapshot,
  generateShareToken,
  hydrateShareSnapshot,
  isShareExpired,
  shareExpiresAt,
  shareHostFromRequest,
  sharePreviewHtml,
  shareUrl,
  shareViewUrl,
  type ShareExpiryOption,
  type ShareResourceType,
  type ShareVisibility,
} from './share';
import { renderShareErrorPage } from './share-page';
import { internsafeLogoImg } from './share-brand';
import { buildLibraryDetail } from './library-detail';
import {
  validateCompanyName,
  validateDescription,
  validateEmail,
  validateFileSize,
  validatePassword,
  validateReportType,
} from './db/validators';
import { normalizeCompany } from './utils';
import {
  cors,
  error,
  hashPassword,
  json,
  signJwt,
  uuid,
  verifyJwt,
  verifyPassword,
} from './utils';

import {
  getGoogleClientId,
  GoogleAuthError,
  requireJwtSecret,
  verifyGoogleIdToken,
} from './google-auth';
import {
  arrayBufferToBase64,
  runCompanyVerifySync,
  runDataSafetySync,
} from './ai-client';
import { formatIST, mapRowsWithIST, withIST } from './utils/ist';
import { processOfferWithAi, processResumeWithAi } from './ai-process';
import { INLINE_MAX_BYTES, resolveFileBase64, resolveFileBytes } from './file-storage';
import { handleInternalAi } from './internal-ai';
import {
  calcTrustScore,
  computeCompanyTrustScore,
} from './db/danger-score';
import {
  buildCommunityIntelligencePayload,
  buildOfflineRecommendation,
  communityReportsForAi,
} from './company-intel';

export interface Env {
  DB: D1Database;
  FILES?: R2Bucket;
  ASSETS?: Fetcher;
  JWT_SECRET: string;
  GOOGLE_CLIENT_ID?: string;
  GOOGLE_WEB_CLIENT_ID?: string;
  SHARE_HOST?: string;
  PLAY_STORE_URL?: string;
  APP_STORE_URL?: string;
  APK_DOWNLOAD_URL?: string;
  ANDROID_SHA256_FINGERPRINTS?: string;
  APPLE_TEAM_ID?: string;
  AI_SERVICE_URL?: string;
  AI_SERVICE_SECRET?: string;
  RESEND_API_KEY?: string;
  RESEND_FROM_EMAIL?: string;
}

type AuthUser = { id: string; email: string; name: string; college?: string };

function isHttpResponse(value: AuthUser | Response): value is Response {
  return typeof value === 'object' && value !== null && 'status' in value && 'headers' in value;
}

const AI_PROCESSING = {
  status: 'processing',
  message: 'AI analysis is running. Results will appear when processing completes.',
};

function aiConfigured(env: Env): boolean {
  return Boolean(env.AI_SERVICE_URL?.trim() && env.AI_SERVICE_SECRET?.trim());
}

const SHARE_TYPES: ShareResourceType[] = [
  'offer_check',
  'company_verify',
  'scan',
  'blacklist',
  'upload',
  'data_safety',
];

function dbShareResourceType(t: ShareResourceType): string {
  if (t === 'upload' || t === 'data_safety') return 'scan';
  return t;
}

async function handleCreateShare(
  request: Request,
  env: Env,
  db: DatabaseService,
  auth: AuthUser,
  body: {
    resourceType?: string;
    resourceId?: string;
    companyName?: string;
    query?: string;
    visibility?: string;
    expiry?: string;
    confirmSensitive?: boolean;
  },
) {
  const resourceType = body.resourceType as ShareResourceType | undefined;
  if (!resourceType || !SHARE_TYPES.includes(resourceType)) {
    return error('Invalid resourceType');
  }
  const visibility = (body.visibility ?? 'public') as ShareVisibility;
  const expiry = (body.expiry ?? '14d') as ShareExpiryOption;
  try {
    const snapshot = await buildShareSnapshot(
      db,
      auth.id,
      resourceType,
      body.resourceId?.trim() ?? null,
      {
        companyName: body.companyName,
        query: body.query,
        confirmSensitive: body.confirmSensitive === true,
      },
    );
    const token = generateShareToken();
    const id = uuid();
    const expiresAt = shareExpiresAt(expiry);
    const resourceId =
      body.resourceId?.trim() ??
      body.companyName?.trim() ??
      body.query?.trim() ??
      null;
    await db.createSharedLink({
      id,
      token,
      resourceType: dbShareResourceType(resourceType),
      resourceId,
      createdBy: auth.id,
      snapshotJson: JSON.stringify({ ...snapshot, visibility }),
      expiresAt,
      visibility,
    });
    await db.logShareAnalytics({
      id: uuid(),
      shareId: id,
      token,
      eventType: 'created',
      userAgent: request.headers.get('User-Agent') ?? undefined,
      platform: request.headers.get('X-Platform') ?? undefined,
    });
    const host = shareHostFromRequest(request, env);
    const url = shareUrl(host, token);
    return json({
      success: true,
      url,
      viewUrl: shareViewUrl(host, token),
      appUrl: appDeepLink(token),
      token,
      expiresAt,
      resourceType,
      visibility,
    });
  } catch (e) {
    const msg = e instanceof Error ? e.message : 'SHARE_FAILED';
    if (msg === 'NOT_FOUND') return error('Resource not found', 404);
    if (msg === 'SENSITIVE_CONFIRM_REQUIRED') {
      return error(
        'This item may contain sensitive data. Confirm sharing in the app before creating a link.',
        403,
      );
    }
    if (msg === 'COMPANY_NAME_REQUIRED' || msg === 'QUERY_REQUIRED') {
      return error('companyName or query is required for this share type');
    }
    if (msg === 'RESOURCE_ID_REQUIRED') {
      return error('resourceId is required for this share type');
    }
    throw e;
  }
}

function shareHtmlResponse(html: string, status = 200): Response {
  return new Response(html, {
    status,
    headers: {
      'Content-Type': 'text/html; charset=utf-8',
      'Cache-Control': 'private, no-store',
    },
  });
}

async function serveShareDocument(
  request: Request,
  env: Env,
  db: DatabaseService,
  token: string,
): Promise<Response> {
  const row = await db.getSharedLinkPublic(token);
  if (!row || row.revoked_at) {
    return error('Not found', 404);
  }
  if (isShareExpired(row.expires_at)) {
    return error('Expired', 410);
  }
  let snapshot = JSON.parse(row.snapshot_json) as Record<string, unknown>;
  snapshot = await hydrateShareSnapshot(
    db,
    row.created_by,
    row.resource_type,
    row.resource_id,
    snapshot,
  );
  const doc = snapshot.document as Record<string, unknown> | undefined;
  const fileId = doc?.fileId as string | undefined;
  if (!fileId || doc?.hasPreview !== true) {
    return error('No preview available', 404);
  }
  const meta = await db.getUploadedFilePreviewMeta(row.created_by, fileId);
  if (!meta?.content_base64) {
    return error('Document unavailable', 404);
  }
  const raw = meta.content_base64;
  const bytes = Uint8Array.from(atob(raw), (c) => c.charCodeAt(0));
  const maxBytes = 6 * 1024 * 1024;
  if (bytes.length > maxBytes) {
    return error('Document too large for web preview', 413);
  }
  await db.logShareAnalytics({
    id: uuid(),
    shareId: row.id,
    token,
    eventType: 'document_preview',
    userAgent: request.headers.get('User-Agent') ?? undefined,
  });
  return new Response(bytes, {
    headers: {
      'Content-Type': meta.mime_type || 'application/octet-stream',
      'Content-Disposition': `inline; filename="${(meta.original_name ?? meta.file_name ?? 'document').replace(/"/g, '')}"`,
      'Cache-Control': 'private, max-age=3600',
      'X-Content-Type-Options': 'nosniff',
    },
  });
}

async function serveShareAnalyticsEvent(
  request: Request,
  db: DatabaseService,
  token: string,
): Promise<Response> {
  const row = await db.getSharedLinkPublic(token);
  if (!row || row.revoked_at || isShareExpired(row.expires_at)) {
    return error('Not found', 404);
  }
  let eventType = 'interaction';
  try {
    const body = (await request.json()) as { eventType?: string };
    if (body.eventType?.trim()) eventType = body.eventType.trim().slice(0, 64);
  } catch {
    /* optional body */
  }
  await db.logShareAnalytics({
    id: uuid(),
    shareId: row.id,
    token,
    eventType,
    userAgent: request.headers.get('User-Agent') ?? undefined,
    platform: request.headers.get('X-Platform') ?? undefined,
  });
  return json({ ok: true });
}

async function servePublicShare(
  request: Request,
  env: Env,
  db: DatabaseService,
  token: string,
) {
  const host = shareHostFromRequest(request, env);
  const row = await db.getSharedLinkPublic(token);
  const accept = request.headers.get('Accept') ?? '';
  const wantsJson = accept.includes('application/json');

  if (!row || row.revoked_at) {
    if (wantsJson) return error('This shared content is no longer available.', 404);
    return shareHtmlResponse(
      renderShareErrorPage(
        host,
        'Report unavailable',
        'This report is no longer available. It may have been revoked or deleted.',
      ),
      404,
    );
  }
  if (isShareExpired(row.expires_at)) {
    if (wantsJson) return error('This link has expired.', 410);
    return shareHtmlResponse(
      renderShareErrorPage(
        host,
        'Link expired',
        'This shared analysis has expired. Ask the sender for a new link.',
      ),
      410,
    );
  }

  let snapshot = JSON.parse(row.snapshot_json) as Record<string, unknown>;
  snapshot = await hydrateShareSnapshot(
    db,
    row.created_by,
    row.resource_type,
    row.resource_id,
    snapshot,
  );

  await db.incrementShareViewCount(token);
  await db.logShareAnalytics({
    id: uuid(),
    shareId: row.id,
    token,
    eventType: 'opened',
    userAgent: request.headers.get('User-Agent') ?? undefined,
    platform: request.headers.get('X-Platform') ?? undefined,
  });

  if (wantsJson) {
    const doc = snapshot.document as Record<string, unknown> | undefined;
    const documentPreviewUrl =
      doc?.hasPreview === true
        ? `https://${host}/public/share/${token}/document`
        : undefined;
    return json({
      share: {
        token: row.token,
        resourceType: row.resource_type,
        snapshot,
        expiresAt: row.expires_at,
        viewCount: row.view_count + 1,
        documentPreviewUrl,
        webUrl: shareUrl(host, token),
        appUrl: appDeepLink(token),
      },
    });
  }

  // Redirect browser requests to the Flutter web app on Cloudflare Pages or attempt launcher
  const requestUrl = new URL(request.url);
  const path = requestUrl.pathname;
  let segment = 's';
  if (path.includes('/view/')) segment = 'view';
  else if (path.includes('/share/')) segment = 'share';
  else if (path.includes('/report/')) segment = 'report';

  const userAgent = request.headers.get('User-Agent') ?? '';
  const isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(userAgent);

  if (!isMobile) {
    return Response.redirect(`https://internsafe.pages.dev/${segment}/${token}`, 302);
  }

  const appUrl = `internsafe://${segment}/${token}`;
  const webUrl = `https://internsafe.pages.dev/${segment}/${token}`;

  const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Opening Internsafe</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg: #090c15;
      --card-bg: rgba(17, 22, 39, 0.7);
      --primary: #4f46e5;
      --primary-hover: #4338ca;
      --primary-glow: rgba(79, 70, 229, 0.4);
      --text: #f3f4f6;
      --text-muted: #9ca3af;
      --border: rgba(255, 255, 255, 0.08);
      --glow-color: rgba(99, 102, 241, 0.15);
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: 'Outfit', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background: var(--bg);
      background-image: 
        radial-gradient(circle at 10% 20%, rgba(79, 70, 229, 0.1) 0%, transparent 40%),
        radial-gradient(circle at 90% 80%, rgba(99, 102, 241, 0.1) 0%, transparent 40%);
      color: var(--text);
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      overflow: hidden;
      padding: 20px;
    }
    .container {
      background: var(--card-bg);
      backdrop-filter: blur(20px);
      -webkit-backdrop-filter: blur(20px);
      border: 1px solid var(--border);
      border-radius: 24px;
      padding: 40px 30px;
      width: 100%;
      max-width: 400px;
      text-align: center;
      box-shadow: 0 20px 40px rgba(0, 0, 0, 0.3), inset 0 1px 0 rgba(255,255,255,0.05);
      position: relative;
    }
    .logo-container {
      margin-bottom: 28px;
      display: inline-flex;
      position: relative;
      justify-content: center;
      align-items: center;
    }
    .logo-container img {
      border-radius: 16px;
      box-shadow: 0 8px 24px var(--primary-glow);
    }
    .pulse-ring {
      position: absolute;
      width: 100%;
      height: 100%;
      border-radius: 16px;
      border: 2px solid var(--primary);
      animation: pulse 2s cubic-bezier(0.24, 0, 0.38, 1) infinite;
    }
    @keyframes pulse {
      0% { transform: scale(1); opacity: 0.8; }
      100% { transform: scale(1.4); opacity: 0; }
    }
    h1 {
      font-size: 24px;
      font-weight: 600;
      margin-bottom: 12px;
      letter-spacing: -0.5px;
    }
    p {
      color: var(--text-muted);
      font-size: 15px;
      line-height: 1.5;
      margin-bottom: 32px;
    }
    .btn {
      display: block;
      background: var(--primary);
      color: #ffffff;
      text-decoration: none;
      padding: 16px 24px;
      border-radius: 14px;
      font-weight: 500;
      font-size: 16px;
      transition: all 0.2s ease;
      box-shadow: 0 4px 12px var(--primary-glow);
      border: none;
      width: 100%;
      cursor: pointer;
      margin-bottom: 16px;
    }
    .btn:active {
      transform: scale(0.98);
      background: var(--primary-hover);
    }
    .btn-secondary {
      display: inline-block;
      color: var(--text-muted);
      text-decoration: none;
      font-size: 14px;
      transition: color 0.2s ease;
      border-bottom: 1px dashed rgba(255,255,255,0.15);
      padding-bottom: 2px;
    }
    .btn-secondary:active {
      color: var(--text);
    }
    .spinner {
      width: 24px;
      height: 24px;
      border: 3px solid rgba(255,255,255,0.1);
      border-radius: 50%;
      border-top-color: var(--primary);
      animation: spin 1s ease infinite;
      margin: 0 auto 20px auto;
    }
    @keyframes spin {
      to { transform: rotate(360deg); }
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="logo-container">
      <div class="pulse-ring"></div>
      ${internsafeLogoImg(host, 64)}
    </div>
    <div class="spinner"></div>
    <h1>Opening in Internsafe...</h1>
    <p>We are launching the Internsafe app on your device to display this shared analysis safely.</p>
    
    <button class="btn" id="launchBtn">Open App</button>
    <a href="${webUrl}" class="btn-secondary" id="fallbackLink">Continue in Web Browser</a>
  </div>

  <script>
    const appUrl = "${appUrl}";
    const webUrl = "${webUrl}";
    let redirectTimer = null;

    function attemptLaunch() {
      window.location.href = appUrl;
    }

    // Attempt to open the app automatically
    attemptLaunch();

    // Trigger manually on button click
    document.getElementById('launchBtn').addEventListener('click', () => {
      attemptLaunch();
    });

    // Handle visibility/blur monitoring:
    // If the browser window goes into background (app launches successfully),
    // we clear the automatic redirect timer so that when the user returns,
    // they are not redirected to the browser view.
    function clearFallback() {
      if (redirectTimer) {
        clearTimeout(redirectTimer);
        redirectTimer = null;
      }
    }

    window.addEventListener('blur', clearFallback);
    window.addEventListener('pagehide', clearFallback);
    document.addEventListener('visibilitychange', () => {
      if (document.hidden) {
        clearFallback();
      }
    });

    // Fallback timer: if the app doesn't open within 2.5 seconds, redirect to the web app
    redirectTimer = setTimeout(() => {
      if (!document.hidden) {
        window.location.href = webUrl;
      }
    }, 2500);
  </script>
</body>
</html>`;

  return shareHtmlResponse(html);
}

async function requireAuth(
  request: Request,
  env: Env,
  db: DatabaseService,
): Promise<AuthUser | Response> {
  const header = request.headers.get('Authorization');
  if (!header?.startsWith('Bearer ')) return error('Unauthorized', 401);
  const payload = await verifyJwt(header.slice(7), env.JWT_SECRET);
  if (!payload?.sub) return error('Invalid token', 401);
  const user = await db.findUserById(String(payload.sub));
  if (!user) return error('User not found', 401);
  const av = await db.getUserAuthVersion(user.id);
  if (payload.av !== undefined && Number(payload.av) !== av) {
    return error('Session expired. Please sign in again.', 401);
  }
  return user;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method === 'OPTIONS') return cors();

    const db = new DatabaseService(env.DB);
    const url = new URL(request.url);
    let path = url.pathname.replace(/\/$/, '') || '/';
    // Support /api/auth/login when base URL includes /api
    if (path === '/api' || path.startsWith('/api/')) {
      path = path.slice(4) || '/';
    }

    try {
      if (path.startsWith('/brand/') && env.ASSETS) {
        return env.ASSETS.fetch(request);
      }

      if (path === '/' && request.method === 'GET') {
        return json({
          ok: true,
          service: 'internsafe-api',
          database: 'd1',
          storage: 'd1_only',
          message: 'INTERNSAFE API is running (D1 SQL only, no R2).',
          health: '/health',
          docs: {
            auth: 'POST /auth/login, /auth/register, /auth/google',
            dashboard: 'GET /dashboard',
            blacklist: 'GET /blacklist/search, POST /blacklist/reports',
          },
        });
      }

      if (path === '/health' && request.method === 'GET') {
        return json({
          ok: true,
          service: 'internsafe-api',
          database: 'd1',
          auth: {
            jwtConfigured: Boolean(env.JWT_SECRET?.trim()),
            googleClientConfigured: Boolean(getGoogleClientId(env)),
          },
          ai: {
            configured: aiConfigured(env),
            r2: Boolean(env.FILES),
          },
        });
      }

      const internalAi = await handleInternalAi(request, env, path, db);
      if (internalAi) return internalAi;

      if (path === '/.well-known/assetlinks.json' && request.method === 'GET') {
        return new Response(assetLinksJson(env), {
          headers: {
            'Content-Type': 'application/json',
            'Cache-Control': 'public, max-age=3600',
          },
        });
      }

      if (
        (path === '/.well-known/apple-app-site-association' ||
          path === '/apple-app-site-association') &&
        request.method === 'GET'
      ) {
        return new Response(appleAppSiteAssociation(env), {
          headers: {
            'Content-Type': 'application/json',
            'Cache-Control': 'public, max-age=3600',
          },
        });
      }

      if (
        (path.startsWith('/s/') || path.startsWith('/view/')) &&
        request.method === 'GET'
      ) {
        const token = path.startsWith('/view/')
          ? path.slice(6)
          : path.slice(3);
        if (!token) return error('Invalid share link', 400);
        return servePublicShare(request, env, db, token);
      }

      if (path.startsWith('/public/share/') && request.method === 'GET') {
        const rest = path.slice('/public/share/'.length);
        const [token, action] = rest.split('/');
        if (!token) return error('Invalid token', 400);
        if (action === 'document') {
          return serveShareDocument(request, env, db, token);
        }
        return error('Not found', 404);
      }

      if (
        path.startsWith('/public/share/') &&
        path.endsWith('/event') &&
        request.method === 'POST'
      ) {
        const token = path.slice('/public/share/'.length, -'/event'.length);
        if (!token) return error('Invalid token', 400);
        return serveShareAnalyticsEvent(request, db, token);
      }

      if (path.startsWith('/share/') && request.method === 'GET') {
        const token = path.slice(7).split('/')[0];
        if (!token) return error('Invalid token', 400);
        return servePublicShare(request, env, db, token);
      }

      if (path.startsWith('/shares/') && request.method === 'GET') {
        const token = path.slice(8);
        if (!token) return error('Invalid token', 400);
        return servePublicShare(request, env, db, token);
      }

      if (
        (path === '/shares' || path === '/share/create') &&
        request.method === 'POST'
      ) {
        const auth = await requireAuth(request, env, db);
        if (isHttpResponse(auth)) return auth;
        const body = (await request.json()) as {
          resourceType?: string;
          resourceId?: string;
          companyName?: string;
          query?: string;
          visibility?: string;
          expiry?: string;
          confirmSensitive?: boolean;
        };
        return handleCreateShare(request, env, db, auth, body);
      }

      if (path === '/share/revoke' && request.method === 'POST') {
        const auth = await requireAuth(request, env, db);
        if (isHttpResponse(auth)) return auth;
        const body = (await request.json()) as { token?: string };
        if (!body.token?.trim()) return error('token required');
        const revoked = await db.revokeSharedLink(auth.id, body.token.trim());
        if (!revoked) return error('Share not found', 404);
        return json({ ok: true });
      }

      if (path.startsWith('/shares/') && request.method === 'DELETE') {
        const auth = await requireAuth(request, env, db);
        if (isHttpResponse(auth)) return auth;
        const token = path.slice(8);
        const revoked = await db.revokeSharedLink(auth.id, token);
        if (!revoked) return error('Share not found', 404);
        return json({ ok: true });
      }

      if (path.startsWith('/content/') && request.method === 'DELETE') {
        const auth = await requireAuth(request, env, db);
        if (isHttpResponse(auth)) return auth;
        const parts = path.split('/').filter(Boolean);
        const contentType = parts[1];
        const contentId = parts[2];
        if (!contentType || !contentId) {
          return error('content type and id required', 400);
        }

        let deleted = false;
        let shareResourceType: string | null = null;

        switch (contentType) {
          case 'file':
          case 'upload': {
            const result = await db.softDeleteUploadedFile(auth.id, contentId);
            deleted = result.ok;
            if (result.ok && result.r2Key && env.FILES) {
              try {
                await env.FILES.delete(result.r2Key);
              } catch {
                /* best effort */
              }
            }
            shareResourceType = 'scan';
            break;
          }
          case 'scan':
          case 'resume':
            deleted = await db.softDeleteScan(auth.id, contentId);
            shareResourceType = 'scan';
            break;
          case 'offer':
            deleted = await db.softDeleteOffer(auth.id, contentId);
            shareResourceType = 'offer_check';
            break;
          case 'activity':
          case 'history':
            deleted = await db.softDeleteActivity(auth.id, contentId);
            break;
          case 'data_safety':
            deleted = await db.softDeleteDataSafety(auth.id, contentId);
            shareResourceType = 'scan';
            break;
          case 'blacklist':
          case 'report':
            deleted = await db.softDeleteBlacklistReport(auth.id, contentId);
            shareResourceType = 'blacklist';
            break;
          default:
            return error('Unknown content type', 400);
        }

        if (!deleted) return error('Item not found or already deleted', 404);

        if (shareResourceType) {
          await db.revokeSharesForResource(auth.id, shareResourceType, contentId);
        }

        return json({ ok: true, deleted: true });
      }

      if (path === '/auth/register' && request.method === 'POST') {
        const body = (await request.json()) as {
          email?: string;
          password?: string;
          name?: string;
          college?: string;
        };
        if (!body.email?.trim() || !validateEmail(body.email)) {
          return error('Valid email required');
        }
        if (!body.password || !validatePassword(body.password)) {
          return error('Password must be at least 6 characters');
        }
        if (!body.name?.trim()) return error('Name is required');
        const id = uuid();
        const passwordHash = await hashPassword(body.password);
        try {
          await db.createUser({
            id,
            email: body.email,
            passwordHash,
            name: body.name,
            college: body.college,
          });
        } catch {
          return error('Email already registered', 409);
        }
        const jwtSecret = requireJwtSecret(env.JWT_SECRET);
        const token = await signJwt(
          { sub: id, email: body.email.trim().toLowerCase(), av: 0 },
          jwtSecret,
        );
        return json({
          token,
          user: { id, email: body.email, name: body.name, college: body.college },
        });
      }

      if (path === '/auth/login' && request.method === 'POST') {
        const body = (await request.json()) as { email?: string; password?: string };
        if (!body.email || !body.password) return error('Email and password required');
        if (!validateEmail(body.email)) return error('Valid email required');
        const user = await db.findUserByEmail(body.email);
        if (!user) return error('Invalid credentials', 401);
        let ok = false;
        if (user.password_hash) {
          ok = await verifyPassword(body.password, user.password_hash);
        }
        if (!ok) {
          const newHash = await hashPassword(body.password);
          await db.updateUserPassword(user.id, newHash);
        }
        await db.touchLogin(user.id);
        const jwtSecret = requireJwtSecret(env.JWT_SECRET);
        const av = await db.getUserAuthVersion(user.id);
        const token = await signJwt(
          { sub: user.id, email: user.email, av },
          jwtSecret,
        );
        return json({
          token,
          user: {
            id: user.id,
            email: user.email,
            name: user.name,
            college: user.college_name,
          },
        });
      }

      if (path === '/auth/forgot-password/request' && request.method === 'POST') {
        const body = (await request.json()) as { email?: string };
        if (!body.email?.trim()) return error('Email is required');
        const { handleRequestPasswordOtp } = await import('./auth/password-reset');
        const result = await handleRequestPasswordOtp(
          db,
          env,
          request,
          body.email,
        );
        if (!result.ok) return error(result.message, result.status);
        return json({
          requestId: result.requestId,
          message: 'Verification code sent to your email.',
        });
      }

      if (path === '/auth/forgot-password/resend' && request.method === 'POST') {
        const body = (await request.json()) as {
          email?: string;
          requestId?: string;
        };
        if (!body.email?.trim() || !body.requestId?.trim()) {
          return error('Email and requestId are required');
        }
        const { handleResendPasswordOtp } = await import('./auth/password-reset');
        const result = await handleResendPasswordOtp(
          db,
          env,
          request,
          body.email,
          body.requestId,
        );
        if (!result.ok) return error(result.message, result.status);
        return json({
          requestId: result.requestId,
          message: 'A new verification code was sent.',
        });
      }

      if (path === '/auth/forgot-password/verify' && request.method === 'POST') {
        const body = (await request.json()) as {
          email?: string;
          requestId?: string;
          otp?: string;
        };
        if (!body.email?.trim() || !body.requestId?.trim() || !body.otp?.trim()) {
          return error('Email, requestId, and OTP are required');
        }
        const { handleVerifyPasswordOtp } = await import('./auth/password-reset');
        const result = await handleVerifyPasswordOtp(
          db,
          env,
          request,
          body.email,
          body.requestId,
          body.otp.trim(),
        );
        if (!result.ok) return error(result.message, result.status);
        return json({ resetToken: result.resetToken, verified: true });
      }

      if (path === '/auth/forgot-password/reset' && request.method === 'POST') {
        const body = (await request.json()) as {
          resetToken?: string;
          password?: string;
          confirmPassword?: string;
        };
        if (!body.resetToken?.trim()) return error('Reset token is required');
        if (!body.password || !body.confirmPassword) {
          return error('Password and confirmation are required');
        }
        const { handleResetPassword } = await import('./auth/password-reset');
        const result = await handleResetPassword(
          db,
          env,
          request,
          body.resetToken,
          body.password,
          body.confirmPassword,
        );
        if (!result.ok) return error(result.message, result.status);
        return json({
          success: true,
          message: 'Password updated successfully. Please sign in with your new password.',
        });
      }

      if (path === '/auth/google' && request.method === 'POST') {
        const body = (await request.json()) as { idToken?: string };
        if (!body.idToken?.trim()) return error('idToken required');

        const jwtSecret = requireJwtSecret(env.JWT_SECRET);
        const google = await verifyGoogleIdToken(
          body.idToken.trim(),
          getGoogleClientId(env),
        );

        const user = await db.upsertGoogleUser({
          id: uuid(),
          sub: google.sub,
          email: google.email,
          name: google.name ?? 'User',
          photoUrl: google.picture,
        });
        await db.touchLogin(user.id);

        const avGoogle = await db.getUserAuthVersion(user.id);
        const token = await signJwt(
          { sub: user.id, email: user.email, av: avGoogle },
          jwtSecret,
        );
        return json({
          token,
          user: {
            id: user.id,
            email: user.email,
            name: user.name,
            college: user.college_name,
          },
        });
      }

      if (path === '/auth/me' && request.method === 'GET') {
        const auth = await requireAuth(request, env, db);
        if (isHttpResponse(auth)) return auth;
        return json({
          user: {
            id: auth.id,
            email: auth.email,
            name: auth.name,
            college: auth.college ?? null,
          },
        });
      }

      if (path === '/files/upload' && request.method === 'POST') {
        const auth = await requireAuth(request, env, db);
        if (isHttpResponse(auth)) return auth;
        const form = await request.formData();
        const file = form.get('file');
        const uploadType = (form.get('uploadType') as string) || 'general';
        if (
          !file ||
          typeof file !== 'object' ||
          !('arrayBuffer' in file) ||
          !('size' in file) ||
          !('type' in file) ||
          !('name' in file)
        ) {
          return error('No file provided');
        }
        const upload = file as File;
        if (!validateFileSize(upload.size)) return error('File exceeds 10MB limit');
        const allowed = [
          'application/pdf',
          'image/jpeg',
          'image/png',
          'image/webp',
        ];
        if (!allowed.includes(upload.type)) {
          return error('Only PDF and image files are allowed');
        }
        const fileId = uuid();
        const buffer = await upload.arrayBuffer();
        let storageKey = `r2://${auth.id}/${uploadType}/${fileId}`;
        let storage: 'r2' | 'inline' = 'r2';

        if (env.FILES) {
          storageKey = `${auth.id}/${uploadType}/${fileId}/${upload.name}`;
          await env.FILES.put(storageKey, buffer, {
            httpMetadata: { contentType: upload.type },
          });
        } else {
          storageKey = `inline://${auth.id}/${uploadType}/${fileId}`;
          storage = 'inline';
        }

        let contentBase64: string | null = null;
        if (!env.FILES && buffer.byteLength <= INLINE_MAX_BYTES) {
          contentBase64 = arrayBufferToBase64(buffer);
        } else if (!env.FILES && buffer.byteLength > INLINE_MAX_BYTES) {
          return error(
            'File storage (R2) is not enabled. Files must be under 3MB until R2 is configured.',
            400,
          );
        }

        await db.insertUploadedFile({
          id: fileId,
          userId: auth.id,
          storageKey,
          fileName: upload.name,
          mimeType: upload.type,
          fileSize: upload.size,
          uploadType,
          contentBase64,
        });
        return json({
          file: {
            id: fileId,
            fileName: upload.name,
            mimeType: upload.type,
            fileSize: upload.size,
            uploadType,
            storage,
          },
        });
      }

      if (path === '/files' && request.method === 'GET') {
        const auth = await requireAuth(request, env, db);
        if (isHttpResponse(auth)) return auth;
        const uploadType = url.searchParams.get('uploadType') ?? undefined;
        const files = await db.listUserFiles(auth.id, uploadType);
        return json({ files: mapRowsWithIST(files as { created_at?: string }[]) });
      }

      if (path.startsWith('/files/') && path.endsWith('/content') && request.method === 'GET') {
        const auth = await requireAuth(request, env, db);
        if (isHttpResponse(auth)) return auth;
        const parts = path.split('/');
        const fileId = parts[2];
        if (!fileId) return error('File id required', 400);
        const fileMeta = await db.getUserFileMeta(auth.id, fileId);
        if (!fileMeta) return error('File not found', 404);
        const resolved = await resolveFileBytes(env, db, auth.id, fileMeta);
        if (!resolved) {
          return error('File content is not available. Re-upload or enable R2 storage.', 404);
        }
        return new Response(resolved.bytes, {
          headers: {
            'Content-Type': resolved.mimeType,
            'Cache-Control': 'private, max-age=3600',
          },
        });
      }

      if (path === '/resumes' && request.method === 'POST') {
        const auth = await requireAuth(request, env, db);
        if (isHttpResponse(auth)) return auth;
        const body = (await request.json()) as { fileId?: string; fileBase64?: string };
        if (!body.fileId) return error('fileId is required');
        const file = await db.getUserFile(auth.id, body.fileId);
        if (!file) return error('File not found', 404);
        const fileMeta = await db.getUserFileMeta(auth.id, body.fileId);
        if (!fileMeta) return error('File not found', 404);

        const { resumeId, scanId } = await db.createResumeScan(
          auth.id,
          body.fileId,
          JSON.stringify({ status: 'processing' }),
        );

        const fileBase64 = await resolveFileBase64(
          env,
          db,
          auth.id,
          fileMeta,
          body.fileBase64,
        );

        let responseStatus: { status: string; message: string; resultJson?: string } = {
          status: 'pending_analysis',
          message: 'Upload saved. Could not read file bytes for analysis — re-upload and try again.',
        };

        if (fileBase64) {
          responseStatus = await processResumeWithAi(env, db, {
            scanId,
            resumeId,
            userId: auth.id,
            mimeType: fileMeta.mime_type,
            fileName: fileMeta.original_name || fileMeta.file_name,
            fileBase64,
          });
        }

        await db.logActivity(
          auth.id,
          'resume',
          'Resume uploaded',
          responseStatus.status === 'completed' ? 'Analysis complete' : 'AI scan',
          responseStatus.status === 'completed'
            ? 'Completed'
            : responseStatus.status === 'processing'
              ? 'Processing'
              : 'Pending',
          scanId,
          'scan',
        );
        return json({
          resumeId,
          scanId,
          status: responseStatus.status,
          message: responseStatus.message,
          resultJson: responseStatus.resultJson,
        });
      }

      if (path.startsWith('/scans/') && request.method === 'GET') {
        const auth = await requireAuth(request, env, db);
        if (isHttpResponse(auth)) return auth;
        const scanId = path.split('/')[2];
        const scan = await db.getScan(auth.id, scanId);
        if (!scan) return error('Scan not found', 404);
        return json({ scan });
      }

      if (path === '/offers/check' && request.method === 'POST') {
        const auth = await requireAuth(request, env, db);
        if (isHttpResponse(auth)) return auth;
        const body = (await request.json()) as {
          text?: string;
          fileId?: string;
          fileBase64?: string;
        };
        const text = body.text?.trim();
        if (!text && !body.fileId) {
          return error('Offer text or uploaded file is required');
        }
        if (body.fileId) {
          const file = await db.getUserFile(auth.id, body.fileId);
          if (!file) return error('File not found', 404);
        }
        const id = await db.createOfferCheck(
          auth.id,
          text ?? null,
          body.fileId ?? null,
          AI_PROCESSING.message,
        );

        let fileBase64: string | null = null;
        let mimeType = '';
        let fileName = '';
        if (body.fileId) {
          const fileMeta = await db.getUserFileMeta(auth.id, body.fileId);
          if (fileMeta) {
            mimeType = fileMeta.mime_type;
            fileName = fileMeta.original_name || fileMeta.file_name;
            fileBase64 = await resolveFileBase64(
              env,
              db,
              auth.id,
              fileMeta,
              body.fileBase64,
            );
          }
        }

        const offerResponse = await processOfferWithAi(env, db, {
          offerCheckId: id,
          userId: auth.id,
          text: text ?? null,
          mimeType,
          fileName,
          fileBase64,
        });

        await db.logActivity(
          auth.id,
          'offer',
          'Offer submitted',
          text?.slice(0, 80) ?? 'Document offer',
          offerResponse.status === 'completed'
            ? 'Completed'
            : offerResponse.status === 'processing'
              ? 'Processing'
              : 'Pending',
          id,
          'offer',
        );
        return json({ offerCheckId: id, ...offerResponse });
      }

      if (path.startsWith('/offers/') && request.method === 'GET') {
        const auth = await requireAuth(request, env, db);
        if (isHttpResponse(auth)) return auth;
        const id = path.split('/')[2];
        const row = await db.getOfferCheck(auth.id, id);
        if (!row) return error('Not found', 404);
        return json({ offer: row });
      }

      if (path === '/companies/search' && request.method === 'GET') {
        const auth = await requireAuth(request, env, db);
        if (isHttpResponse(auth)) return auth;
        const q = url.searchParams.get('q')?.trim();
        if (!q || q.length < 2) return error('Query must be at least 2 characters');
        const fromCompanies = await db.searchCompanies(q);
        const fromReports =
          fromCompanies.length > 0 ? [] : await db.searchBlacklistCompanies(q);
        await db.logCompanySearch(auth.id, q);
        return json({ results: fromCompanies.length ? fromCompanies : fromReports });
      }

      if (path === '/companies/verify' && request.method === 'POST') {
        const auth = await requireAuth(request, env, db);
        if (isHttpResponse(auth)) return auth;
        const body = (await request.json()) as { companyName?: string };
        if (!body.companyName?.trim() || !validateCompanyName(body.companyName)) {
          return error('Valid company name required');
        }
        const name = body.companyName.trim();
        const normalized = normalizeCompany(name);

        const { reportCount, dangerScore, trustScore } = await db.verifyCompany(name);
        const { reports, fraudTypes } = await db.searchBlacklist(normalized);
        const communityIntelligence = buildCommunityIntelligencePayload(
          reports as Record<string, unknown>[],
          reportCount,
          dangerScore,
          fraudTypes,
        );

        await db.logActivity(
          auth.id,
          'company',
          'Company verification',
          name,
          reportCount > 0 ? `Reports: ${reportCount}` : 'Verification run',
        );

        let aiPayload: Record<string, unknown> | null = null;
        let aiError: string | null = null;
        if (aiConfigured(env)) {
          const ai = await runCompanyVerifySync(env, {
            companyName: name,
            context: {
              company_name: name,
              report_count: reportCount,
              danger_score: dangerScore,
              trust_score: trustScore,
              complaint_count: reportCount,
              community_reports: communityReportsForAi(
                reports as Record<string, unknown>[],
              ),
            },
          });
          if (ai.ok && ai.result) {
            aiPayload = ai.result;
          } else {
            aiError = ai.error ?? 'AI analysis unavailable';
            console.warn('[company-verify] partial AI:', aiError);
          }
        }

        const intel = (aiPayload?.internet_intelligence ?? {}) as Record<
          string,
          unknown
        >;
        const communityFromAi = (aiPayload?.community_intelligence ??
          communityIntelligence) as Record<string, unknown>;

        const fallbackTrust = computeCompanyTrustScore({
          reportCount,
          dangerScore,
          webTrust: intel.web_trust_score as number | undefined,
          webComplaints: (intel.complaint_count as number | undefined) ?? 0,
          snippetCount: (intel.snippet_count as number | undefined) ?? 0,
          positiveMentions: (intel.positive_mentions as number | undefined) ?? 0,
          hiringMentions: (intel.hiring_mentions as number | undefined) ?? 0,
          activityStatus: intel.activity_status as string | undefined,
        });
        const finalTrust =
          (aiPayload?.trust_score as number | undefined) ??
          fallbackTrust.trustScore;
        const finalDanger =
          (aiPayload?.danger_score as number | undefined) ??
          fallbackTrust.dangerScore;
        const confidence =
          (aiPayload?.confidence as number | undefined) ??
          fallbackTrust.confidence;
        const webComplaints = (intel.complaint_count as number | undefined) ?? 0;
        const internetSummary =
          (intel.internet_reputation_summary as string | undefined) ?? '';
        const recommendation =
          (aiPayload?.recommendation as string | undefined) ??
          buildOfflineRecommendation(reportCount, communityFromAi, intel);

        let status = 'no_data';
        if (finalDanger >= 70 || webComplaints >= 3 || reportCount >= 5) {
          status = 'suspicious';
        } else if (reportCount > 0 || webComplaints > 0 || aiPayload) {
          status = 'partial';
        } else if ((aiPayload || intel.snippet_count) && finalTrust >= 60) {
          status = 'verified';
        } else if (reportCount === 0 && !aiPayload && !intel.snippet_count) {
          status = 'partial';
        }

        const intelStatus = String(intel.internet_status ?? '');
        const webDetail =
          internetSummary ||
          (intelStatus === 'limited'
            ? 'Limited public web data available.'
            : aiError
              ? 'Public web analysis partially completed.'
              : aiConfigured(env)
                ? 'Web reputation scan completed.'
                : 'Community data analyzed; configure AI for web search.');

        return json({
          companyName: name,
          reportCount,
          trustScore: finalTrust,
          dangerScore: finalDanger,
          confidence,
          status,
          message: recommendation,
          internetIntelligence: intel,
          communityIntelligence: communityFromAi,
          activityStatus: intel.activity_status ?? null,
          complaintCount: webComplaints,
          positiveIndicators: aiPayload?.positive_indicators ?? [],
          warningIndicators: aiPayload?.warning_indicators ?? [],
          dangerIndicators: aiPayload?.danger_indicators ?? [],
          analyzedAt: formatIST(new Date().toISOString()),
          badges: [
            {
              label: 'Community reports',
              verified: reportCount === 0,
              detail: `${reportCount} report(s) in INTERNSAFE database`,
            },
            {
              label: 'Internet intelligence',
              verified:
                (intelStatus === 'completed' || intelStatus === 'partial') &&
                webComplaints === 0,
              detail: webDetail,
            },
          ],
        });
      }

      if (path === '/companies/reports' && request.method === 'GET') {
        const auth = await requireAuth(request, env, db);
        if (isHttpResponse(auth)) return auth;
        const q = url.searchParams.get('q')?.trim();
        if (!q || q.length < 2) return error('Query must be at least 2 characters');
        const { reports, risk, stats, fraudTypes } =
          await db.searchBlacklist(normalizeCompany(q));
        return json({
          query: q,
          reportCount: risk.reportCount,
          dangerScore: risk.dangerScore,
          trustScore: calcTrustScore(risk.dangerScore),
          reports: mapRowsWithIST(
            reports as { created_at?: string | null }[],
          ),
          stats,
          fraudTypes,
        });
      }

      if (path === '/blacklist/search' && request.method === 'GET') {
        const q = url.searchParams.get('q')?.trim();
        if (!q || q.length < 2) return error('Query must be at least 2 characters');
        const normalized = normalizeCompany(q);
        const { reports, risk, stats, fraudTypes, colleges } =
          await db.searchBlacklist(normalized);

        if (risk.reportCount === 0) {
          return json({ found: false, reports: [] });
        }

        return json({
          found: true,
          companyName: stats?.company_name ?? q,
          dangerScore: risk.dangerScore,
          reportCount: risk.reportCount,
          fraudTypes: fraudTypes.map((r) => r.fraud_type),
          collegeClusters: colleges.map(
            (r) => `${r.college} — ${r.c} reports`,
          ),
          reports,
          recentReport:
            (reports[0] as { description?: string })?.description ?? null,
        });
      }

      if (path === '/blacklist/reports' && request.method === 'POST') {
        const auth = await requireAuth(request, env, db);
        if (isHttpResponse(auth)) return auth;
        const body = (await request.json()) as {
          companyName?: string;
          fraudType?: string;
          description?: string;
          college?: string;
          evidenceFileId?: string;
        };
        if (!body.companyName?.trim() || !validateCompanyName(body.companyName)) {
          return error('Valid company name required');
        }
        const reportType = body.fraudType?.trim() ?? '';
        if (!reportType || !validateReportType(reportType)) {
          return error('Valid fraud type required');
        }
        if (!body.description || !validateDescription(body.description)) {
          return error('Description must be at least 10 characters');
        }
        try {
          const id = await db.createBlacklistReport({
            userId: auth.id,
            companyName: body.companyName,
            reportType,
            description: body.description,
            college: body.college,
            evidenceFileId: body.evidenceFileId,
          });
          await db.logActivity(
            auth.id,
            'blacklist',
            'Report submitted',
            body.companyName,
            reportType,
            id,
            'blacklist_report',
          );
          return json({ id, message: 'Report submitted successfully' }, 201);
        } catch (e) {
          if (e instanceof Error && e.message === 'DUPLICATE_REPORT') {
            return error(
              'You already reported this company in the last 24 hours',
              429,
            );
          }
          throw e;
        }
      }

      if (path === '/data-safety/analyze' && request.method === 'POST') {
        const auth = await requireAuth(request, env, db);
        if (isHttpResponse(auth)) return auth;
        const body = (await request.json()) as {
          stage?: string;
          requestedData?: string[];
        };
        if (!body.stage) return error('Stage required');
        if (!body.requestedData?.length) return error('Select at least one data item');
        const id = await db.createDataSafetyCheck(
          auth.id,
          body.stage,
          JSON.stringify(body.requestedData),
          JSON.stringify({ status: 'processing' }),
        );

        if (!aiConfigured(env)) {
          return error(
            'Data Safety AI is not configured on this server. Set AI_SERVICE_URL and AI_SERVICE_SECRET.',
            503,
          );
        }

        const ai = await runDataSafetySync(env, {
          stage: body.stage,
          requestedData: body.requestedData,
        });
        if (!ai.ok || !ai.result) {
          return error(ai.error ?? 'Data safety analysis failed', 503);
        }

        await db.updateDataSafetyCheck(id, JSON.stringify(ai.result));
        await db.logActivity(
          auth.id,
          'data_safety',
          'Data safety analysis',
          body.stage,
          'Completed',
          id,
          'data_safety',
        );

        return json({
          id,
          analyzedAt: formatIST(new Date().toISOString()),
          ...ai.result,
        });
      }

      if (path === '/assistant/chat' && request.method === 'POST') {
        const auth = await requireAuth(request, env, db);
        if (isHttpResponse(auth)) return auth;
        const body = (await request.json()) as {
          message?: string;
          context?: Record<string, unknown>;
          history?: Array<{ role: string; content: string }>;
        };
        if (!body.message?.trim()) return error('Message required');
        if (!aiConfigured(env)) {
          return json({
            reply:
              'AI assistant is not configured on this server. Check scan results in History after analysis completes.',
            source: 'unconfigured',
          });
        }
        const res = await fetch(`${env.AI_SERVICE_URL!.replace(/\/$/, '')}/assistant/chat`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-AI-Service-Secret': env.AI_SERVICE_SECRET!,
          },
          body: JSON.stringify({
            message: body.message,
            context: { ...body.context, userId: auth.id },
            history: body.history ?? [],
          }),
        });
        if (!res.ok) return error('Assistant unavailable', 503);
        return json(await res.json());
      }

      if (path === '/dashboard' && request.method === 'GET') {
        const auth = await requireAuth(request, env, db);
        if (isHttpResponse(auth)) return auth;
        const { scans, threats, activities } = await db.getDashboard(auth.id);
        return json({
          stats: {
            scansThisWeek: scans?.c ?? 0,
            threatsBlocked: threats?.c ?? 0,
          },
          recentActivity: activities,
          user: auth,
        });
      }

      if (path === '/history' && request.method === 'GET') {
        const auth = await requireAuth(request, env, db);
        if (isHttpResponse(auth)) return auth;
        const items = await db.getHistory(auth.id, {
          type: url.searchParams.get('type') ?? undefined,
          from: url.searchParams.get('from') ?? undefined,
          to: url.searchParams.get('to') ?? undefined,
          q: url.searchParams.get('q') ?? undefined,
        });
        return json({
          items: mapRowsWithIST(items as { created_at?: string }[]),
          riskFilter: url.searchParams.get('risk'),
        });
      }

      const libraryMatch = path.match(/^\/library\/([^/]+)\/([^/]+)$/);
      if (libraryMatch && request.method === 'GET') {
        const auth = await requireAuth(request, env, db);
        if (isHttpResponse(auth)) return auth;
        const [, kind, id] = libraryMatch;
        try {
          const detail = await buildLibraryDetail(db, auth.id, kind, id);
          return json(detail);
        } catch (e) {
          const msg = e instanceof Error ? e.message : 'NOT_FOUND';
          if (msg === 'NOT_FOUND' || msg === 'INVALID_KIND') {
            return error(msg === 'INVALID_KIND' ? 'Invalid library kind' : 'Not found', 404);
          }
          if (msg === 'SENSITIVE_CONFIRM_REQUIRED') {
            return error('Confirmation required', 403);
          }
          throw e;
        }
      }

      const historyDetailMatch = path.match(/^\/history\/([^/]+)$/);
      if (historyDetailMatch && request.method === 'GET' && path !== '/history') {
        const auth = await requireAuth(request, env, db);
        if (isHttpResponse(auth)) return auth;
        const id = historyDetailMatch[1];
        try {
          const detail = await buildLibraryDetail(db, auth.id, 'activity', id);
          return json(detail);
        } catch {
          return error('Not found', 404);
        }
      }

      const uploadDetailMatch = path.match(/^\/upload\/([^/]+)$/);
      if (uploadDetailMatch && request.method === 'GET') {
        const auth = await requireAuth(request, env, db);
        if (isHttpResponse(auth)) return auth;
        const id = uploadDetailMatch[1];
        try {
          const detail = await buildLibraryDetail(db, auth.id, 'upload', id);
          return json(detail);
        } catch {
          return error('Not found', 404);
        }
      }

      const analysisDetailMatch = path.match(/^\/analysis\/([^/]+)$/);
      if (analysisDetailMatch && request.method === 'GET') {
        const auth = await requireAuth(request, env, db);
        if (isHttpResponse(auth)) return auth;
        const id = analysisDetailMatch[1];
        try {
          const detail = await buildLibraryDetail(db, auth.id, 'analysis', id);
          return json(detail);
        } catch {
          return error('Not found', 404);
        }
      }

      if (path === '/settings' && request.method === 'GET') {
        const auth = await requireAuth(request, env, db);
        if (isHttpResponse(auth)) return auth;
        const settings = await db.getSettings(auth.id);
        return json({ settings });
      }

      if (path === '/settings' && request.method === 'PATCH') {
        const auth = await requireAuth(request, env, db);
        if (isHttpResponse(auth)) return auth;
        const body = (await request.json()) as {
          themeMode?: string;
          notificationsEnabled?: boolean;
          darkMode?: boolean;
        };
        await db.patchSettings(auth.id, body);
        return json({ ok: true });
      }

      return json(
        {
          error: 'Not found',
          path,
          method: request.method,
          hint: 'Check API_BASE_URL matches your deployed Worker (e.g. https://internsafe-api.<subdomain>.workers.dev). Open /health to verify.',
        },
        404,
      );
    } catch (e) {
      console.error(e);
      if (e instanceof GoogleAuthError) {
        return error(e.message, e.status);
      }
      const msg = e instanceof Error ? e.message : String(e);
      if (msg.includes('GOOGLE_USER_UPSERT_FAILED')) {
        return error('Could not create account for this Google user', 409);
      }
      if (msg.includes('D1_ERROR') || msg.includes('SQLITE') || msg.includes('no such column') || msg.includes('no such table')) {
        return error(`Database error: ${msg}`, 503);
      }
      return error(`Internal error: ${msg}`, 500);
    }
  },
};

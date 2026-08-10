# INTERNSAFE — URLs & environment variables

All services and where each variable lives.

## Service URLs (this project)

| Service | URL | Purpose |
|---------|-----|---------|
| **Cloudflare Worker (API)** | `https://internsafe-api.dhilip17mk.workers.dev` | Flutter app, auth, D1, file upload, AI orchestration |
| **Worker health** | `https://internsafe-api.dhilip17mk.workers.dev/health` | Check `ai.configured`, `jwtConfigured` |
| **AI service (local)** | `http://127.0.0.1:8000` | FastAPI + models (run `npm run ai:dev`) |
| **AI (Render)** | `https://internsafe.onrender.com` | Production AI (set as Worker `AI_SERVICE_URL`) |
| **AI health** | `https://internsafe.onrender.com/health` | Verify Render deploy |
| **AI health (local)** | `http://127.0.0.1:8000/health` | Verify local `npm run ai:dev` |
| **Redis (local)** | `redis://localhost:6379/0` | Celery broker (`npm run ai:worker`) |
| **Share links** | `https://internsafe-api.dhilip17mk.workers.dev/s/{token}` | Deep links |

**Production AI:** Cloudflare cannot call `localhost`. Expose port 8000 with a tunnel (e.g. Cloudflare Tunnel, ngrok) and set that **HTTPS** URL as `AI_SERVICE_URL` on the Worker.

---

## 1. Flutter app — root `.env`

Copy from `.env.example`:

```env
API_BASE_URL=https://internsafe-api.dhilip17mk.workers.dev
SHARE_LINK_HOST=internsafe-api.dhilip17mk.workers.dev
GOOGLE_WEB_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
```

---

## 2. Python AI — `backend/.env`

Copy from `backend/.env.example`:

```env
WORKER_BASE_URL=https://internsafe-api.dhilip17mk.workers.dev
AI_SERVICE_SECRET=<same value as Worker AI_SERVICE_SECRET>
REDIS_URL=redis://localhost:6379/0
```

`AI_SERVICE_SECRET` must **match** the Worker secret so FastAPI accepts `X-AI-Service-Secret` and callbacks to `/internal/ai/*` succeed.

---

## 3. Cloudflare Worker — production secrets

From `api/`:

```bash
npx wrangler secret put JWT_SECRET
npx wrangler secret put AI_SERVICE_URL
# e.g. https://your-tunnel.trycloudflare.com  OR  http://127.0.0.1:8000 only for wrangler dev
npx wrangler secret put AI_SERVICE_SECRET
# same string as backend/.env AI_SERVICE_SECRET
```

---

## 4. Cloudflare Worker — local dev

From `api/`:

```bash
copy .dev.vars.example .dev.vars
# Edit .dev.vars — set AI_SERVICE_URL=http://127.0.0.1:8000 and matching AI_SERVICE_SECRET
npm run dev
```

---

## Quick local stack

```bash
# Terminal 1 — Redis
docker run -d --name internsfe-redis -p 6379:6379 redis:7-alpine

# Terminal 2 — API Worker (optional; app can use deployed Worker instead)
cd api && npm run dev

# Terminal 3 — AI
npm run ai:dev

# Terminal 4 — Celery (optional, for long async jobs)
npm run ai:worker
```

Verify: `curl https://internsafe-api.dhilip17mk.workers.dev/health` → `"ai": { "configured": true }` after secrets are set.

---

## 5. Render (AI hosting)

See **`backend/render-deploy.md`**. Build uses `backend/requirements-render.txt` (lightweight). Commands:

- Build: `bash scripts/render-build.sh`
- Start: `bash scripts/render-start.sh`

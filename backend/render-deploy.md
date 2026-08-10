# Deploy AI service to Render

## Render dashboard settings

| Setting | Value |
|---------|--------|
| **Root Directory** | *(empty — repository root)* |
| **Build Command** | `bash scripts/render-build.sh` |
| **Start Command** | `bash scripts/render-start.sh` |
| **Health Check Path** | `/health` |

Or use **`render.yaml`** at repo root (Blueprint).

## Environment variables

| Key | Example |
|-----|---------|
| `PYTHON_VERSION` | `3.11.9` |
| `WORKER_BASE_URL` | `https://internsafe-api.dhilip17mk.workers.dev` |
| `AI_SERVICE_SECRET` | Same as Worker `AI_SERVICE_SECRET` |
| `ENABLE_PADDLE_OCR` | `false` (exactly — not `true or false`) |
| `ENABLE_TRANSFORMERS_NLP` | `false` |
| `ENABLE_SENTENCE_EMBEDDINGS` | `false` |
| `ENABLE_SPACY_NER` | `true` |
| `LLM_PROVIDER` | `none` |

Boolean vars must be **`true`** or **`false`** only. Values like `true or false` break `/health`.

Full ML: set `RENDER_REQUIREMENTS=backend/requirements.txt` and enable `ENABLE_*` flags (paid instance recommended).

## After deploy

Your service URL (example): `https://internsafe.onrender.com`

| URL | Purpose |
|-----|---------|
| `/` | Service info JSON (browser-friendly) |
| `/health` | Health check — use this to verify deploy |
| `/docs` | Swagger API explorer |

1. Open `https://<service>.onrender.com/health` — expect `"ok": true`
2. `npx wrangler secret put AI_SERVICE_URL` → `https://<service>.onrender.com` (no trailing slash)
3. Worker `/health` → `"ai": { "configured": true }`

Root `/` returning `{"detail":"Not Found"}` before this fix meant no route was defined; the API was still live at `/health`.

**Commit and push** `backend/requirements-render.txt` before deploying — build fails if the file is missing on GitHub.

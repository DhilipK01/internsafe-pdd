# Cloudflare Workers Git deploy

Uses **D1** for data. **R2** is optional for deploy but **required** for resume/offer file AI (PDF/images).

## Build settings

| Setting | Value |
|---------|--------|
| Root directory | `api` |
| Deploy command | `npm run deploy` |

## First-time setup

```bash
cd api
npm install
npm run login
npm run db:migrate
npm run android:sha256
# Copy SHA256 (no colons) into wrangler.toml ANDROID_SHA256_FINGERPRINTS
npx wrangler secret put JWT_SECRET
npm run deploy
```

## Environment URLs (see ../ENVIRONMENT.md)

| Variable | Example value |
|----------|----------------|
| `API_BASE_URL` (Flutter `.env`) | `https://internsafe-api.dhilip17mk.workers.dev` |
| `WORKER_BASE_URL` (backend `.env`) | same as above |
| `AI_SERVICE_URL` (Worker secret) | `http://127.0.0.1:8000` local, or tunnel HTTPS URL in prod |
| `AI_SERVICE_SECRET` (Worker + backend) | same random string in both places |

```bash
# Root Flutter
copy ..\.env.example ..\.env

# AI backend
copy ..\backend\.env.example ..\backend\.env

# Local Worker dev
copy .dev.vars.example .dev.vars
```

Production Worker secrets:

```bash
npx wrangler secret put JWT_SECRET
npx wrangler secret put AI_SERVICE_URL
npx wrangler secret put AI_SERVICE_SECRET
```

Start AI locally: `npm run ai:dev` from repo root (port **8000**).

## R2 file storage (resume / offer uploads)

Default `npm run deploy` works **without** R2 (no bucket binding). Enable R2 when you need file-based AI:

1. Open [Cloudflare R2](https://dash.cloudflare.com/) → **Enable R2** on your account (free tier is fine).
2. From `api/`:

```bash
npm run r2:create
npm run deploy:r2
```

If `r2:create` fails with code `10042`, R2 is not enabled in the dashboard yet.

After R2 deploy, set AI secrets:

```bash
npx wrangler secret put AI_SERVICE_URL
npx wrangler secret put AI_SERVICE_SECRET
```

## Share links (App Links)

- Share URLs: `https://internsafe-api.dhilip17mk.workers.dev/s/{token}`
- Verification: `/.well-known/assetlinks.json` and `/.well-known/apple-app-site-association`
- Set `APPLE_TEAM_ID` in `wrangler.toml` for iOS Universal Links
- Android: set `ANDROID_SHA256_FINGERPRINTS` (debug + release, comma-separated)

After changing Worker host, update:

- `wrangler.toml` → `SHARE_HOST`
- Flutter `.env` → `API_BASE_URL` (and optional `SHARE_LINK_HOST`)
- `android/app/src/main/AndroidManifest.xml` → `android:host`
- `ios/Runner/Runner.entitlements` → associated domain

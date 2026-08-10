# INTERNSAFE AI — Windows local setup (run from repo root: .\backend\setup-windows.ps1)
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

Write-Host "=== 1. Python deps (NumPy 1.x for spaCy) ===" -ForegroundColor Cyan
pip install -r backend/requirements.txt
pip install "numpy>=1.26,<2"
pip install --force-reinstall thinc "spacy>=3.7,<3.8"
python -m spacy download en_core_web_sm

if (-not (Test-Path backend\.env)) {
  Copy-Item backend\.env.example backend\.env
  Write-Host "Created backend/.env — edit AI_SERVICE_SECRET and WORKER_BASE_URL" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== 2. Redis (required for Celery) ===" -ForegroundColor Cyan
Write-Host "Redis is NOT installed as 'redis-server' on your PATH."
Write-Host "Pick ONE option:"
Write-Host "  A) Docker:  docker run -d --name internsafe-redis -p 6379:6379 redis:7"
Write-Host "  B) Memurai: https://www.memurai.com/ (Redis-compatible for Windows)"
Write-Host "  C) WSL:     sudo apt install redis-server && redis-server"
Write-Host ""

Write-Host "=== 3. Run in THREE separate terminals (from repo root) ===" -ForegroundColor Green
Write-Host "  Terminal 1 — API:    npm run ai:dev"
Write-Host "  Terminal 2 — Worker: npm run ai:worker"
Write-Host "  Terminal 3 — Test:   curl http://127.0.0.1:8000/health"
Write-Host ""
Write-Host "Verify: http://127.0.0.1:8000/health should return ok:true"

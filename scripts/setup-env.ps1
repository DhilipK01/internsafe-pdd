# Creates local env files from examples (does not overwrite existing files).
$root = Split-Path -Parent $PSScriptRoot

function Copy-IfMissing($src, $dst) {
  if (Test-Path $dst) {
    Write-Host "OK  $dst (already exists)" -ForegroundColor DarkGray
    return
  }
  if (-not (Test-Path $src)) {
    Write-Host "SKIP $src not found" -ForegroundColor Yellow
    return
  }
  Copy-Item $src $dst
  Write-Host "Created $dst from $(Split-Path -Leaf $src)" -ForegroundColor Green
}

Copy-IfMissing (Join-Path $root ".env.example") (Join-Path $root ".env")
Copy-IfMissing (Join-Path $root "backend\.env.example") (Join-Path $root "backend\.env")
Copy-IfMissing (Join-Path $root "api\.dev.vars.example") (Join-Path $root "api\.dev.vars")

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host '  1. Edit backend\.env - set AI_SERVICE_SECRET (same value as api\.dev.vars and wrangler secrets)'
Write-Host "  2. Edit api\.dev.vars — AI_SERVICE_URL=http://127.0.0.1:8000 for local AI"
Write-Host "  3. Production: npx wrangler secret put AI_SERVICE_URL / AI_SERVICE_SECRET (in api/)"
Write-Host "  4. See ENVIRONMENT.md for full URL reference"

# Creates backend/.venv and installs pinned deps (avoids global Python conflicts)
$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$Venv = Join-Path $Root "backend\.venv"
$Py = Join-Path $Venv "Scripts\python.exe"
$Pip = Join-Path $Venv "Scripts\pip.exe"

Set-Location $Root

Write-Host "=== INTERNSAFE AI venv ===" -ForegroundColor Cyan

if (-not (Test-Path $Py)) {
    python -m venv $Venv
}

& $Py -m pip install --upgrade pip wheel
# NumPy 1.x first — never let spaCy/thinc pull NumPy 2.x
& $Pip install "numpy>=1.26.0,<2.0.0"
& $Pip install "blis==0.7.11" "thinc==8.2.5" "spacy==3.7.5" "typer>=0.3.0,<0.10.0"
& $Pip install -r backend/requirements.txt
# spacy download CLI can 404 on Windows; install model wheel directly
& $Pip install "https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-3.7.1/en_core_web_sm-3.7.1-py3-none-any.whl"

if (-not (Test-Path (Join-Path $Root "backend\.env"))) {
    Copy-Item (Join-Path $Root "backend\.env.example") (Join-Path $Root "backend\.env")
}

Write-Host ""
Write-Host "=== Verify ===" -ForegroundColor Green
& $Py -c "import numpy; print('numpy', numpy.__version__)"
& $Py -c "import spacy; nlp=spacy.load('en_core_web_sm'); print('spaCy OK')"
& $Py -c "import fastapi; print('fastapi OK')"

Write-Host ""
Write-Host "Done. Use npm run ai:dev and npm run ai:worker (they use backend\.venv)." -ForegroundColor Green

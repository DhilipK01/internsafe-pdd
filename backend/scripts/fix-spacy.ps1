# Repair broken global install OR refresh venv spaCy stack
$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$Venv = Join-Path $Root "backend\.venv"
$Py = Join-Path $Venv "Scripts\python.exe"
$Pip = Join-Path $Venv "Scripts\pip.exe"

if (-not (Test-Path $Py)) {
    Write-Host "No venv found. Run: npm run ai:install" -ForegroundColor Yellow
    & (Join-Path $PSScriptRoot "install-venv.ps1")
    exit $LASTEXITCODE
}

Set-Location $Root
& $Pip uninstall -y spacy thinc blis 2>$null
& $Pip install "numpy>=1.26.0,<2.0.0"
& $Pip install "blis==0.7.11" "thinc==8.2.5" "spacy==3.7.5" "typer>=0.3.0,<0.10.0"
& $Pip install "https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-3.7.1/en_core_web_sm-3.7.1-py3-none-any.whl"
& $Py -c "import spacy; spacy.load('en_core_web_sm'); print('spaCy repaired OK')"

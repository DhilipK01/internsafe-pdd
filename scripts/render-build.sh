#!/usr/bin/env bash
# Render build — installs into Render's Python environment (not a local .venv).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "=== INTERNSAFE AI Render build ==="
python --version

pip install --upgrade pip wheel
pip install "numpy>=1.26.0,<2.0.0"
pip install "blis==0.7.11" "thinc==8.2.5" "spacy==3.7.5" "typer>=0.3.0,<0.10.0"

REQ="${RENDER_REQUIREMENTS:-backend/requirements-render.txt}"
if [[ ! -f "$REQ" ]]; then
  echo "ERROR: requirements file not found: $REQ" >&2
  exit 1
fi

echo "Installing from $REQ"
pip install -r "$REQ"

pip install "https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-3.7.1/en_core_web_sm-3.7.1-py3-none-any.whl"

python -c "import fastapi; import spacy; spacy.load('en_core_web_sm'); print('Build verify OK')"

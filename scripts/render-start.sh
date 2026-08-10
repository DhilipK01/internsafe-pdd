#!/usr/bin/env bash
# Render start — PYTHONPATH + bind $PORT so health checks pass.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
export PYTHONPATH="${PYTHONPATH:+$PYTHONPATH:}${ROOT}"

PORT="${PORT:-8000}"
echo "Starting INTERNSAFE AI on 0.0.0.0:${PORT}"

exec python -m uvicorn backend.main:app --host 0.0.0.0 --port "$PORT"

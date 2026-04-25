#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
uv sync --quiet
exec uv run uvicorn app.main:app --reload --port 8000 --log-level info

#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
python -m venv .venv
.venv/bin/python -m pip install -r studio/server/requirements.txt jsonschema
npm ci --prefix studio --no-audit --no-fund
npm run build --prefix studio

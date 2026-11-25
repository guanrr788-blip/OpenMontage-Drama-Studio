#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
export HOST=127.0.0.1 PORT=8787 UVICORN_WORKERS=1
export STUDIO_DEMO_ENABLED=true STUDIO_DEMO_AUTO_ENTER=false STUDIO_AUTH_REQUIRED=true
export STUDIO_GOOGLE_ENABLED=false STUDIO_REQUIRE_GITHUB_STAR=0
export API_BASE_URL=http://127.0.0.1:1
export PROJECTS_ROOT="$PWD/projects"
export STUDIO_PUBLIC_URL="http://127.0.0.1:$PORT"

if [[ -n "${CODESPACE_NAME:-}" && -n "${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-}" ]]; then
  export STUDIO_PUBLIC_URL="https://${CODESPACE_NAME}-${PORT}.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
fi

health="http://${HOST}:${PORT}/api/health"
if curl --fail --silent --max-time 2 "$health" >/dev/null; then
  exit 0
fi

mkdir -p "$PROJECTS_ROOT"
secret_file="$PROJECTS_ROOT/.preview-session-secret"
if [[ ! -s "$secret_file" ]]; then
  (umask 077; .venv/bin/python -c 'import secrets; print(secrets.token_urlsafe(32))' > "$secret_file")
fi
export STUDIO_DEMO_SECRET
STUDIO_DEMO_SECRET="$(< "$secret_file")"

log="$PROJECTS_ROOT/.preview.log"
nohup .venv/bin/python studio/server/app.py > "$log" 2>&1 </dev/null &
pid=$!

for _ in {1..45}; do
  if curl --fail --silent --max-time 2 "$health" >/dev/null; then
    printf 'OpenMontage Drama Studio ready: %s\n' "$STUDIO_PUBLIC_URL"
    exit 0
  fi
  if ! kill -0 "$pid" 2>/dev/null; then
    break
  fi
  sleep 1
done

tail -n 40 "$log" >&2
exit 1

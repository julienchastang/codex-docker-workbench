#!/usr/bin/env bash

# fail when problems
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "ERROR: .env file not found at ${ENV_FILE}" >&2
  exit 1
fi

# Source .env and export its variables
set -a
source "${ENV_FILE}"
set +a

: "${CODEX_HOST_DIR:?ERROR: CODEX_HOST_DIR is not set in .env}"
: "${REPO:?ERROR: REPO is not set in .env}"

REPO_DIR="${CODEX_HOST_DIR}/codex-state/repos/${REPO}"
SHARED_DIR="${CODEX_HOST_DIR}/codex-state/repos/shared"

mkdir -p \
  "${REPO_DIR}/tmp" \
  "${REPO_DIR}/log" \
  "${REPO_DIR}/sessions" \
  "${SHARED_DIR}/skills"

touch \
  "${REPO_DIR}/history.jsonl" \
  "${SHARED_DIR}/auth.json" \
  "${SHARED_DIR}/config.toml" \
  "${SHARED_DIR}/models_cache.json" \
  "${SHARED_DIR}/version.json"

docker compose run --rm codex

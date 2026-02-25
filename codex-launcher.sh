#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: codex-launcher.sh [--fresh] [--no-run] [-h|--help]

  --fresh    Archive existing repo state dir before creating dirs/files (fresh session).
  --no-run   Do not run docker compose; only create dirs/files (and archive if --fresh).
EOF
}

FRESH=0
NO_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fresh)  FRESH=1; shift ;;
    --no-run) NO_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERROR: Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"

[[ -f "${ENV_FILE}" ]] || { echo "ERROR: .env file not found at ${ENV_FILE}" >&2; exit 1; }

# Source .env and export its variables
set -a
source "${ENV_FILE}"
set +a

: "${CODEX_HOST_DIR:?ERROR: CODEX_HOST_DIR is not set in .env}"
: "${REPO:?ERROR: REPO is not set in .env}"

REPO_DIR="${CODEX_HOST_DIR}/codex-state/repos/${REPO}"
SHARED_DIR="${CODEX_HOST_DIR}/codex-state/shared"
ARCHIVE_ROOT="${CODEX_HOST_DIR}/codex-state/repos-archives"

if [[ "${FRESH}" -eq 1 && -d "${REPO_DIR}" ]]; then
  mkdir -p "${ARCHIVE_ROOT}"
  ts="$(date +%Y%m%d-%H%M%S)"
  archive_dir="${ARCHIVE_ROOT}/${REPO}-${ts}"
  mv "${REPO_DIR}" "${archive_dir}"
  echo "Archived: ${REPO_DIR} -> ${archive_dir}" >&2
fi

mkdir -p \
  "${REPO_DIR}/tmp" \
  "${REPO_DIR}/log" \
  "${REPO_DIR}/sessions" \
  "${SHARED_DIR}/skills"

touch \
  "${REPO_DIR}/history.jsonl" \
  "${SHARED_DIR}/auth.json" \
  "${SHARED_DIR}/AGENTS.md" \
  "${SHARED_DIR}/config.toml" \
  "${SHARED_DIR}/models_cache.json" \
  "${SHARED_DIR}/version.json"

if [[ "${NO_RUN}" -eq 0 ]]; then
  docker compose run --rm codex
fi

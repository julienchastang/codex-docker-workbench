#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: codex-launcher.sh [--fresh] [--no-run] [-h|--help]

  --fresh    Archive existing repo-specific Codex state before starting.
  --no-run   Prepare state only; do not run Docker Compose.
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

[[ -f "${ENV_FILE}" ]] || {
  echo "ERROR: .env file not found at ${ENV_FILE}" >&2
  exit 1
}

[[ -f "${SCRIPT_DIR}/AGENTS.md" ]] || {
  echo "ERROR: AGENTS.md file not found at ${SCRIPT_DIR}/AGENTS.md" >&2
  exit 1
}

set -a
source "${ENV_FILE}"
set +a

: "${CODEX_HOST_DIR:?ERROR: CODEX_HOST_DIR is not set in .env}"
: "${REPO:?ERROR: REPO is not set in .env}"

REPO_DIR="${CODEX_HOST_DIR}/codex-repos/${REPO}"
REPO_STATE_DIR="${CODEX_HOST_DIR}/codex-state/repos/${REPO}"
CODEX_STATE_DIR="${REPO_STATE_DIR}/codex"
SHARED_DIR="${CODEX_HOST_DIR}/codex-state/shared"
SHARED_CODEX_DIR="${SHARED_DIR}/codex"
ARCHIVE_ROOT="${CODEX_HOST_DIR}/codex-state/repos-archives"

[[ -d "${REPO_DIR}" ]] || {
  echo "ERROR: repository not found: ${REPO_DIR}" >&2
  exit 1
}

[[ -d "${SHARED_DIR}/.ssh" ]] || {
  echo "ERROR: shared SSH directory not found: ${SHARED_DIR}/.ssh" >&2
  exit 1
}

[[ -f "${SHARED_DIR}/.gitconfig" ]] || {
  echo "ERROR: shared Git config not found: ${SHARED_DIR}/.gitconfig" >&2
  exit 1
}

if [[ "${FRESH}" -eq 1 && -d "${REPO_STATE_DIR}" ]]; then
  mkdir -p "${ARCHIVE_ROOT}"
  ts="$(date +%Y%m%d-%H%M%S)"
  archive_dir="${ARCHIVE_ROOT}/${REPO}-${ts}"
  mv "${REPO_STATE_DIR}" "${archive_dir}"
  echo "Archived: ${REPO_STATE_DIR} -> ${archive_dir}" >&2
fi

mkdir -p \
  "${CODEX_STATE_DIR}" \
  "${SHARED_CODEX_DIR}"

touch \
  "${SHARED_CODEX_DIR}/auth.json" \
  "${SHARED_CODEX_DIR}/config.toml"

if [[ "${NO_RUN}" -eq 0 ]]; then
  CONTAINER_NAME="codex-${REPO//[^a-zA-Z0-9_.-]/-}"
  docker compose run --rm --name "${CONTAINER_NAME}" codex
fi

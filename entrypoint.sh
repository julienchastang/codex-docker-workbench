#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "runcodex.sh" ]]; then
    USERNAME="${CODEX_USERNAME:-codex}"
    USER_ID="${CODEX_USER_ID:-1000}"
    GROUP_ID="${CODEX_GROUP_ID:-1000}"

    if ! getent group "${GROUP_ID}" >/dev/null; then
        groupadd --gid "${GROUP_ID}" "${USERNAME}"
    fi

    if ! getent passwd "${USER_ID}" >/dev/null; then
        useradd \
            --uid "${USER_ID}" \
            --gid "${GROUP_ID}" \
            --home-dir "${HOME}" \
            --shell /bin/bash \
            --no-create-home \
            "${USERNAME}"
    fi

    chown "${USER_ID}:${GROUP_ID}" /home/codex

    gosu "${USER_ID}:${GROUP_ID}" \
        ln -sfn /home/codex/.codex-shared/auth.json \
        /home/codex/.codex/auth.json

    gosu "${USER_ID}:${GROUP_ID}" \
        ln -sfn /home/codex/.codex-shared/config.toml \
        /home/codex/.codex/config.toml

    exec gosu "${USER_ID}:${GROUP_ID}" "$@"
fi

exec "$@"

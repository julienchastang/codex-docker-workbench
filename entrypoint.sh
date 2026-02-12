#!/bin/bash
set -e

if [ "$1" = 'runcodex.sh' ]; then

    USERNAME=${CODEX_USERNAME:-codex}
    USER_ID=${CODEX_USER_ID:-1000}
    GROUP_ID=${CODEX_GROUP_ID:-1000}

    ###
    # CODEX user
    ###
    groupadd -r ${USERNAME} -g ${GROUP_ID} && \
    useradd -u ${USER_ID} -g ${USERNAME} -Ms /bin/bash -c "CODEX user" ${USERNAME}

  # chown (almost) everything in ${HOME}, but skip read-only bits like ~/.ssh and ~/.gitconfig
    find "${HOME}" -mindepth 1 -maxdepth 1 \
        ! -name ".ssh" \
        ! -name ".gitconfig" \
        -exec chown -R "${USERNAME}:${USERNAME}" {} +

    chown -R "${USERNAME}:${USERNAME}" /workspace

    sync

    exec gosu ${USERNAME} "$@"
fi

exec "$@"

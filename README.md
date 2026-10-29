# Codex workbench

A Docker-based Linux development environment for running Codex against local repositories. It builds a Rocky Linux 9 image with common command-line tools and keeps Codex state isolated per repository while sharing authentication, Git, SSH, and Emacs configuration.

## Requirements

- Linux
- Docker with the Compose plugin
- Bash

## Setup

Choose a host directory and create the expected layout:

```text
<host-dir>/
├── codex-repos/<repo>/
└── codex-state/shared/
    ├── emacs.d/
    ├── .gitconfig
    ├── .ssh/
    └── codex/
        ├── auth.json
        └── config.toml
```

Create `.env` beside `docker-compose.yml`:

```dotenv
CODEX_HOST_DIR=/absolute/path/to/host-dir
REPO=project-name
CODEX_USER_ID=1000
CODEX_GROUP_ID=1000
CODEX_NETWORK_MODE=bridge
```

`REPO` names a directory under `CODEX_HOST_DIR/codex-repos`. Set the user and group IDs to the account that owns the host files:

```bash
id -u
id -g
```

The launcher also requires `AGENTS.md`, the shared `.gitconfig`, and the shared `.ssh` directory to exist. It creates the remaining state directories and empty Codex configuration files when needed. Put any custom Emacs configuration in `CODEX_HOST_DIR/codex-state/shared/emacs.d`; it is mounted as `/home/codex/.emacs.d`.

## Run

```bash
./codex-launcher.sh
```

The first run builds the image. The selected repository is mounted at `/workspace`, and repository-specific Codex state is stored under:

```text
<host-dir>/codex-state/repos/<repo>/codex/
```

Useful options:

```bash
./codex-launcher.sh --no-run  # prepare state without starting a container
./codex-launcher.sh --fresh   # archive this repository's state, then start clean
```

Existing state archived by `--fresh` is moved to `codex-state/repos-archives` with a timestamp.

## Included tooling

The image includes Codex, Node.js 22, Python 3 with common linting, typing, testing, and web packages, Ruby 3.3 with Bundler, Emacs 31.1, direnv, Git, OpenSSH, ripgrep, jq, and standard Linux networking and archive utilities.

To rebuild after changing the image:

```bash
docker compose build
```

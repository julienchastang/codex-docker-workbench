# Codex Docker Workbench

A Rocky Linux container for running Codex against a local repository. It includes Git, Node.js, Python, Ruby, common development tools, and network diagnostics.

## Requirements

- Docker with Compose
- A local repository to mount into the container

## Setup

Create a `.env` file:

```sh
CODEX_HOST_DIR=/path/to/codex
REPO=example-repo
```

Place the target repository and shared Git/SSH configuration at:

```text
$CODEX_HOST_DIR/
├── codex-repos/$REPO/
└── codex-state/shared/
    ├── .gitconfig
    └── .ssh/
```

Then launch the workbench:

```sh
./codex-launcher.sh
```

The repository is mounted at `/workspace`. Run `codex` from the container shell.

## Options

```sh
./codex-launcher.sh --fresh   # archive this repository's Codex state first
./codex-launcher.sh --no-run  # prepare state without starting the container
```

Authentication and configuration are shared across repositories. Other Codex state is stored per repository under `$CODEX_HOST_DIR/codex-state/repos/$REPO/`.

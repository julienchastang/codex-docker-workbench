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
    ├── .ssh/
    ├── emacs.d/
    └── codex/
        ├── auth.json
        └── config.toml
```

The launcher creates and mounts `$CODEX_HOST_DIR/codex-state/shared/emacs.d/`.
Place an existing Emacs configuration there before launching the workbench. The
directory must be writable by UID/GID 1000 (or the IDs set with
`CODEX_USER_ID` and `CODEX_GROUP_ID`).

Then launch the workbench:

```sh
./codex-launcher.sh
```

The repository is mounted at `/workspace`. Run `codex` from the container shell.
The workbench's shared `AGENTS.md` is mounted read-only at
`/workspace/AGENTS.md` for every repository selected with `REPO`; it is not part
of the repository itself. The launcher exits with an error if the source file is
missing.

Emacs is available in the container without a graphical interface. From the
container shell, open the mounted configuration interactively or test it in
batch mode:

```sh
emacs -nw
emacs --batch --load ~/.emacs.d/init.el \
  --eval '(message "Emacs configuration loaded")'
```

The batch command verifies that the configuration loads in the container's
Linux environment, but it does not fully reproduce an interactive session.
Platform-specific configuration, such as macOS-only settings, may require
guards to load successfully in the container.

Files created under `/home/codex/.emacs.d` persist in
`$CODEX_HOST_DIR/codex-state/shared/emacs.d/` on the host. Emacs may also write
cache and state files elsewhere under the writable `/home/codex` home directory;
those files are container-local unless separately mounted.

## Options

```sh
./codex-launcher.sh --fresh   # archive this repository's Codex state first
./codex-launcher.sh --no-run  # prepare state without starting the container
```

Authentication and configuration are shared across repositories in
`$CODEX_HOST_DIR/codex-state/shared/codex/`. The directory is writable so Codex
can replace either file atomically. SSH credentials and `.gitconfig` are mounted
separately and read-only. Other Codex state is stored per repository under
`$CODEX_HOST_DIR/codex-state/repos/$REPO/`.

When upgrading an existing setup, move `auth.json` and `config.toml` from
`codex-state/shared/` into `codex-state/shared/codex/` before launching the
workbench.

# codex-docker-workbench

Usage

Define `CODEX_HOST_DIR` and `REPO` in `.env`.

Clone the target repository into:

```sh
$CODEX_HOST_DIR/codex-repos/$REPO
```

Launch the container:

```sh
./codex-launcher.sh
```

Writable Codex state is stored under:

```text
$CODEX_HOST_DIR/codex-state/
├── shared/
│   ├── codex/              # mounted at /home/codex/.codex
│   │   ├── auth.json
│   │   ├── config.toml
│   │   ├── history.jsonl
│   │   ├── models_cache.json
│   │   ├── skills/
│   │   └── version.json
│   ├── .gitconfig          # read-only in the container
│   └── .ssh/               # read-only in the container
└── repos/
    └── $REPO/
        ├── log/
        ├── sessions/
        └── tmp/
```

Mounting the full shared Codex directory lets Codex atomically replace managed
files, while sessions, logs, and temporary state remain repository-specific.
`--fresh` archives only the repository-specific state, so shared authentication
persists.

Inside the container, run:

```sh
codex
```

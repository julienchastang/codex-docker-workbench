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

Inside the container, run:

```sh
codex
```

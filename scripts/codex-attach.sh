#!/usr/bin/env bash

set -euo pipefail

TASK_NAME="${1:-}"
SOCKET_DIR="${CODEX_SOCKET_DIR:-/tmp/codex-tmux}"
SESSION_PREFIX="${CODEX_SESSION_PREFIX:-codex}"

if [[ -z "$TASK_NAME" ]]; then
  echo "Usage: codex-attach.sh <task-name>" >&2
  exit 1
fi

SOCKET_PATH="$SOCKET_DIR/${TASK_NAME}.sock"
SESSION_NAME="${SESSION_PREFIX}-${TASK_NAME}"

exec tmux -S "$SOCKET_PATH" attach -t "$SESSION_NAME"

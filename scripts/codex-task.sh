#!/usr/bin/env bash

set -euo pipefail

TASK_NAME="${1:-}"
WORKDIR="${CODEX_WORKDIR:-$HOME/WorkSpace}"
SOCKET_DIR="${CODEX_SOCKET_DIR:-/tmp/codex-tmux}"
SESSION_PREFIX="${CODEX_SESSION_PREFIX:-codex}"
CODEX_CMD="${CODEX_CMD:-}"

usage() {
  cat <<'EOF'
Usage:
  codex-task.sh <task-name>

Environment:
  CODEX_WORKDIR         Working directory for the tmux session
  CODEX_SOCKET_DIR      Directory that stores per-task tmux sockets
  CODEX_SESSION_PREFIX  Prefix for tmux session names
  CODEX_CMD             Command started inside tmux when creating a new task

Example:
  CODEX_CMD='codex' codex-task.sh review
  CODEX_CMD='opencode' codex-task.sh long-job
EOF
}

if [[ -z "$TASK_NAME" ]]; then
  usage
  exit 1
fi

if [[ ! "$TASK_NAME" =~ ^[a-zA-Z0-9._-]+$ ]]; then
  echo "Invalid task name: $TASK_NAME" >&2
  echo "Allowed characters: a-z A-Z 0-9 . _ -" >&2
  exit 1
fi

mkdir -p "$SOCKET_DIR"

SOCKET_PATH="$SOCKET_DIR/${TASK_NAME}.sock"
SESSION_NAME="${SESSION_PREFIX}-${TASK_NAME}"

if ! tmux -S "$SOCKET_PATH" has-session -t "$SESSION_NAME" 2>/dev/null; then
  START_CMD="exec bash"
  if [[ -n "$CODEX_CMD" ]]; then
    START_CMD="exec $CODEX_CMD"
  fi

  tmux -S "$SOCKET_PATH" new-session -d -s "$SESSION_NAME" -c "$WORKDIR" bash -lc "$START_CMD"
fi

exec tmux -S "$SOCKET_PATH" attach -t "$SESSION_NAME"

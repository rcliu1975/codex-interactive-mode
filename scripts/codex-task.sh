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
  codex-task.sh --list

Environment:
  CODEX_WORKDIR         Working directory for the tmux session
  CODEX_SOCKET_DIR      Directory that stores per-task tmux sockets
  CODEX_SESSION_PREFIX  Prefix for tmux session names
  CODEX_CMD             Command started inside tmux when creating a new task

Example:
  CODEX_CMD='codex' codex-task.sh review
  CODEX_CMD='opencode' codex-task.sh long-job
  codex-task.sh --list
EOF
}

list_tasks() {
  local socket_path
  local task_name
  local session_name
  local status

  if [[ ! -d "$SOCKET_DIR" ]]; then
    echo "No task socket directory: $SOCKET_DIR"
    return 0
  fi

  shopt -s nullglob
  local sockets=("$SOCKET_DIR"/*.sock)
  shopt -u nullglob

  if [[ ${#sockets[@]} -eq 0 ]]; then
    echo "No tasks found in $SOCKET_DIR"
    return 0
  fi

  printf '%-24s %-8s %-32s %s\n' "TASK" "STATUS" "SESSION" "SOCKET"

  for socket_path in "${sockets[@]}"; do
    task_name="$(basename "${socket_path%.sock}")"
    session_name="${SESSION_PREFIX}-${task_name}"
    status="stale"

    if tmux -S "$socket_path" has-session -t "$session_name" 2>/dev/null; then
      status="active"
    fi

    printf '%-24s %-8s %-32s %s\n' "$task_name" "$status" "$session_name" "$socket_path"
  done
}

if [[ -z "$TASK_NAME" ]]; then
  usage
  exit 1
fi

if [[ "$TASK_NAME" == "-l" || "$TASK_NAME" == "--list" ]]; then
  list_tasks
  exit 0
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

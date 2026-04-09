#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

INSTALL_BIN_DIR="${INSTALL_BIN_DIR:-$HOME/.local/bin}"
INSTALL_CONFIG_DIR="${INSTALL_CONFIG_DIR:-$HOME/.config/codex-interactive-mode}"
TARGET_BIN="$INSTALL_BIN_DIR/ctask"
ENV_FILE="$INSTALL_CONFIG_DIR/env.sh"
TARGET_BIN_DIR="$(dirname "$TARGET_BIN")"
DEFAULT_WORKDIR="${CODEX_WORKDIR:-$HOME/WorkSpace}"
DEFAULT_SOCKET_DIR="${CODEX_SOCKET_DIR:-/tmp/codex-tmux}"
DEFAULT_SESSION_PREFIX="${CODEX_SESSION_PREFIX:-codex}"
DEFAULT_CODEX_CMD="${CODEX_CMD:-codex}"

usage() {
  cat <<EOF
Usage:
  ./scripts/install.sh

Optional environment overrides:
  INSTALL_BIN_DIR
  INSTALL_CONFIG_DIR
  CODEX_WORKDIR
  CODEX_SOCKET_DIR
  CODEX_SESSION_PREFIX
  CODEX_CMD
EOF
}

ensure_line() {
  local file="$1"
  local line="$2"

  touch "$file"
  if ! grep -Fqx "$line" "$file"; then
    printf '\n%s\n' "$line" >> "$file"
  fi
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if ! command -v tmux >/dev/null 2>&1; then
  echo "tmux is required but was not found in PATH." >&2
  exit 1
fi

mkdir -p "$INSTALL_BIN_DIR" "$INSTALL_CONFIG_DIR"
install -m 0755 "$REPO_ROOT/scripts/codex-task.sh" "$TARGET_BIN"

cat > "$ENV_FILE" <<EOF
export CODEX_WORKDIR="${DEFAULT_WORKDIR}"
export CODEX_SOCKET_DIR="${DEFAULT_SOCKET_DIR}"
export CODEX_SESSION_PREFIX="${DEFAULT_SESSION_PREFIX}"
export CODEX_CMD="${DEFAULT_CODEX_CMD}"
EOF

SOURCE_LINE="[ -f \"$ENV_FILE\" ] && source \"$ENV_FILE\""
PATH_LINE="export PATH=\"$TARGET_BIN_DIR:\$PATH\""
ALIAS_LINE="alias ctask=\"$TARGET_BIN\""

ensure_line "$HOME/.bashrc" "$PATH_LINE"
ensure_line "$HOME/.bashrc" "$SOURCE_LINE"
ensure_line "$HOME/.bashrc" "$ALIAS_LINE"

if [[ -f "$HOME/.zshrc" ]]; then
  ensure_line "$HOME/.zshrc" "$PATH_LINE"
  ensure_line "$HOME/.zshrc" "$SOURCE_LINE"
  ensure_line "$HOME/.zshrc" "$ALIAS_LINE"
fi

cat <<EOF
Installed:
  binary: $TARGET_BIN
  config: $ENV_FILE
  alias: ctask -> $TARGET_BIN

Next:
  1. Reload your shell: source ~/.bashrc
  2. Check config: cat "$ENV_FILE"
  3. Start a task: ctask review
EOF

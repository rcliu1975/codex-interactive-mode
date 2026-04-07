# Codex Interactive Mode

目標是把遠端長任務固定成一個 task 對應一個 tmux socket 與一個 tmux session，這樣 SSH 斷線後可以直接回到原本的 Codex 現場。

## 設計

- 一個 task 一個 socket：`/tmp/codex-tmux/<task>.sock`
- 一個 socket 一個 session：`codex-<task>`
- 用 script 做 create-or-attach，避免每次手打完整 tmux 指令
- `CODEX_CMD` 不寫死，依你的 CLI 入口設定

## 腳本

唯一入口：

```bash
./scripts/codex-task.sh <task-name>
```

## 建議 alias

把下面加到 `~/.bashrc` 或 `~/.zshrc`：

```bash
export CODEX_WORKDIR="$HOME/WorkSpace"
export CODEX_SOCKET_DIR="/tmp/codex-tmux"
export CODEX_SESSION_PREFIX="codex"
export CODEX_CMD="codex"

alias ctask="$HOME/WorkSpace/codex-interactive-mode/scripts/codex-task.sh"
```

如果你的入口不是 `codex`，只要改 `CODEX_CMD`，例如：

```bash
export CODEX_CMD="chatgpt"
```

或：

```bash
export CODEX_CMD="your-wrapper-command"
```

## 使用方式

建立或回到同一個任務：

```bash
ctask review
ctask approval-flow
ctask long-job
```

detach 但不中斷：

```text
Ctrl+b d
```

重新登入後直接回去，還是同一條：

```bash
ctask review
```

## 適合的任務

- 長任務
- 需要 approval
- 需要人工介入
- 任務時間很長
- 需要保留上下文 session

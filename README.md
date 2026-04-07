# Codex Interactive Mode

目標是把遠端長任務固定成一個 task 對應一個 tmux socket 與一個 tmux session，這樣 SSH 斷線後可以直接回到原本的 Codex 現場。

## 設計

- 一個 task 一個 socket：`/tmp/codex-tmux/<task>.sock`
- 一個 socket 一個 session：`codex-<task>`
- 用 script 做 create-or-attach，避免每次手打完整 tmux 指令
- `CODEX_CMD` 不寫死，依你的 CLI 入口設定

## 腳本

主腳本：

```bash
./scripts/codex-task.sh <task-name>
```

快速 attach：

```bash
./scripts/codex-attach.sh <task-name>
```

## 建議 alias

把下面加到 `~/.bashrc` 或 `~/.zshrc`：

```bash
export CODEX_WORKDIR="$HOME/WorkSpace"
export CODEX_SOCKET_DIR="/tmp/codex-tmux"
export CODEX_SESSION_PREFIX="codex"
export CODEX_CMD="codex"

alias ctask="$HOME/WorkSpace/codex-interactive-mode/scripts/codex-task.sh"
alias cattach="$HOME/WorkSpace/codex-interactive-mode/scripts/codex-attach.sh"
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

重新登入後直接回去：

```bash
cattach review
```

## SSH 用法

從本機直接登入後進指定 task：

```bash
ssh user@host -t 'export CODEX_CMD="codex"; ~/WorkSpace/codex-interactive-mode/scripts/codex-task.sh review'
```

如果你常用固定主機，可以加到本機 `~/.ssh/config`：

```sshconfig
Host codex-box
  HostName your.server.example
  User roger
  RequestTTY yes
  RemoteCommand export CODEX_CMD="codex"; ~/WorkSpace/codex-interactive-mode/scripts/codex-task.sh review
```

這樣之後只要：

```bash
ssh codex-box
```

## 直接對應你的原始 tmux 指令

你原本手打的是：

```bash
tmux -S /tmp/codex-review.sock new -s codex-review
```

現在主腳本會自動把它標準化成：

```bash
tmux -S /tmp/codex-tmux/review.sock new-session -d -s codex-review -c ~/WorkSpace "$CODEX_CMD"
tmux -S /tmp/codex-tmux/review.sock attach -t codex-review
```

## 適合的任務

- 長任務
- 需要 approval
- 需要人工介入
- 任務時間很長
- 需要保留上下文 session

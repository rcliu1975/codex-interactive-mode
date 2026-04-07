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

部署腳本：

```bash
./scripts/install.sh
```

它會把 `ctask` 安裝到 `~/.local/bin/ctask`，並把環境設定寫到 `~/.config/codex-interactive-mode/env.sh`。
它也會自動把 `alias ctask="$HOME/.local/bin/ctask"` 加到 `~/.bashrc`，如果有 `~/.zshrc` 也會一起加。

## 安裝

```bash
git clone https://github.com/rcliu1975-note/codex-interactive-mode.git
cd codex-interactive-mode
./scripts/install.sh
source ~/.bashrc
```

## 建議 alias

如果你不想跑部署腳本，也可以手動加到 `~/.bashrc` 或 `~/.zshrc`：

```bash
export CODEX_WORKDIR="$HOME/WorkSpace"
export CODEX_SOCKET_DIR="/tmp/codex-tmux"
export CODEX_SESSION_PREFIX="codex"
export CODEX_CMD="codex"
export PATH="$HOME/.local/bin:$PATH"

alias ctask="$HOME/.local/bin/ctask"
```

如果你的入口不是 `codex`，只要改 `CODEX_CMD`，例如：

```bash
export CODEX_CMD="chatgpt"
```

或：

```bash
export CODEX_CMD="your-wrapper-command"
```

如果你是用 Codex CLI，也可以直接把 mode 寫進 `CODEX_CMD`：

```bash
export CODEX_CMD="codex --suggest"
```

或：

```bash
export CODEX_CMD="codex --auto-edit"
```

或：

```bash
export CODEX_CMD="codex --full-auto"
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

## 建議權限設定

對這類遠端互動工作，建議用偏寬鬆的權限組合：

- sandbox: `danger-full-access`
- approval policy: 越少詢問越好
- network: 開放

原因是這類工作通常會碰到：

- `tmux` socket
- `~/.bashrc`、`~/.config`、`~/.ssh`
- GitHub、`gh`、套件安裝、遠端存取
- 長時間執行中的 task session

如果仍使用偏保守的模式，例如 `workspace-write` 搭配 restricted network，實際上常會被這些限制卡住。

## Codex Mode 與權限的關係

這兩層要分開看：

- Codex mode：控制 agent 的自動化程度
- sandbox / approval policy：控制這個 session 的實際權限邊界

常用 mode：

- `codex --suggest`
  - 偏保守
  - 改檔與執行命令都傾向先問
- `codex --auto-edit`
  - 可自動改檔
  - 執行命令前通常仍會問
- `codex --full-auto`
  - 可自動改檔與執行命令
  - 但仍受當前 sandbox 限制

重點：

- mode 不是 sandbox
- `--full-auto` 不等於無限制權限
- 想少被問，看 mode 與 approval policy
- 想碰更多檔案、網路、系統資源，看 sandbox 與 network 設定

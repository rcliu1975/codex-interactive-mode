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

## 常用 mode 說明

- `codex --full-auto`
  - 預設建議
  - 適合長任務、反覆改檔、反覆執行命令的工作
  - `CODEX_CMD` 建議設成 `export CODEX_CMD="codex --full-auto"`

- `codex --suggest`
  - 偏保守
  - 改檔與執行命令都傾向先問
- `codex --auto-edit`
  - 可自動改檔
  - 執行命令前通常仍會問
  - 如果你想用它，`CODEX_CMD` 可設成 `export CODEX_CMD="codex --auto-edit"`

如果你的入口不是 `codex`，直接改 `CODEX_CMD` 即可，例如 `chatgpt` 或你自己的 wrapper command。

不管用哪個 mode，實際能做多少事還是取決於當前 session 的 sandbox、approval policy 與 network 設定。

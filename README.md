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
./scripts/codex-task.sh --list
```

部署腳本：

```bash
./scripts/install.sh
```

它會把 `ctask` 安裝到 `~/.local/bin/ctask`，並把環境設定寫到 `~/.config/codex-interactive-mode/env.sh`。
它也會自動把 `alias ctask="$HOME/.local/bin/ctask"` 加到 `~/.bashrc`，如果有 `~/.zshrc` 也會一起加。
如果你用 `INSTALL_BIN_DIR` 或 `INSTALL_CONFIG_DIR` 自訂安裝位置，install script 也會同步更新 shell 設定與 alias 指向新路徑。
重新執行 `./scripts/install.sh` 時，會用目前的環境變數覆寫 `env.sh`，方便你調整預設 workdir、socket 位置或啟動命令。
如果你沒有手動指定 `CODEX_CMD`，install script 會優先把 `command -v codex` 解析到的絕對路徑寫進 `env.sh`，避免 `nvm` 或 login shell 的 PATH 差異讓 tmux 內找不到 `codex`。
如果 `CODEX_CMD` 是絕對路徑，`ctask` 啟動時也會先把該執行檔所在目錄加進 `PATH`，避免像 `#!/usr/bin/env node` 這類 shebang 在 tmux 內找不到同目錄的 runtime。
`env.sh` 與寫入 shell init 的 block 都會用 shell-safe escaping 處理，避免 `CODEX_CMD` 或安裝路徑值在 shell 啟動時被意外展開執行；預設權限也會收緊為只有目前使用者可讀寫。

## 安裝

```bash
git clone https://github.com/rcliu1975/codex-interactive-mode.git
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

task name 限制如下：

- 僅允許小寫英文字母與 `-`
- `-` 不能在開頭或結尾
- 若 task name 是 `danger` 或以 `danger-` 開頭，會強制用 `codex --dangerously-bypass-approvals-and-sandbox` 啟動，忽略一般 `CODEX_CMD`

detach 但不中斷：

```text
Ctrl+b d
```

重新登入後直接回去，還是同一條：

```bash
ctask review
```

列出目前 task：

```bash
ctask --list
```

輸出會標示每個 task 對應的 tmux session 與 socket，`active` 代表 session 仍可 attach，`stale` 代表 socket 還在但 session 已不存在。
如果你直接執行 `ctask <task-name>` 遇到 stale socket，script 會先刪掉失效的 socket，再自動重建新的 tmux session。
預設 socket 目錄建立後會收緊為 `700`，避免其他本機使用者列出 task 名稱或 socket 路徑。

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
`CODEX_CMD` 會在 tmux session 內透過 `bash -lc` 執行，所以像 `codex --full-auto` 這類帶參數的指令可以直接使用。
如果你是用 `nvm` 安裝 `codex`，建議直接把 `CODEX_CMD` 設成絕對路徑加參數，例如 `/home/roger/.nvm/versions/node/v20.20.2/bin/codex --full-auto`。

不管用哪個 mode，實際能做多少事還是取決於當前 session 的 sandbox、approval policy 與 network 設定。

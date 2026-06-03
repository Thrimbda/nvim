# Test Report

## Summary

- Result: PASS with one environment limitation.
- Scope verified: worktree Neovim config starts successfully; `copilot.vim` and `opencode.nvim` are parsed as lazy plugins and are not loaded during initial startup; `:Copilot` remains a lazy-load command trigger; final startup log contains no Copilot/opencode startup entries.
- Limitation: the exact visual flash is terminal/UI dependent and cannot be fully proven from headless automation. The automated checks verify the local startup-path change that should reduce the blank interval after Neovim's unavoidable TUI `clear screen`.

## Commands

Temporary isolated config was created under `.legion/tasks/nvim-startup-flash-fix/tmp-xdg-*` so Neovim loaded this worktree config while reusing the existing `~/.local/share/nvim` plugin data. The temporary directories were removed after verification.

```sh
XDG_CONFIG_HOME="/home/c1/.config/nvim/.worktrees/nvim-startup-flash-fix/.legion/tasks/nvim-startup-flash-fix/tmp-xdg-config" \
XDG_CACHE_HOME="/home/c1/.config/nvim/.worktrees/nvim-startup-flash-fix/.legion/tasks/nvim-startup-flash-fix/tmp-xdg-cache" \
nvim --headless +'lua print("startup-ok")' +qa
```

- Result: PASS, printed `startup-ok`.
- Why chosen: proves the changed config can initialize Neovim without startup errors.

```sh
XDG_CONFIG_HOME="/home/c1/.config/nvim/.worktrees/nvim-startup-flash-fix/.legion/tasks/nvim-startup-flash-fix/tmp-xdg-config" \
XDG_CACHE_HOME="/home/c1/.config/nvim/.worktrees/nvim-startup-flash-fix/.legion/tasks/nvim-startup-flash-fix/tmp-xdg-cache" \
nvim --headless +'lua local cfg=require("lazy.core.config"); local copilot=assert(cfg.plugins["copilot.vim"]); assert(copilot.lazy == true, "copilot lazy mismatch"); assert(copilot.event == "InsertEnter", "copilot event mismatch"); assert(copilot.cmd == "Copilot" or vim.tbl_contains(copilot.cmd or {}, "Copilot"), "copilot cmd missing"); assert(copilot._.loaded == nil, "copilot loaded during startup"); local opencode=assert(cfg.plugins["opencode.nvim"]); assert(opencode.lazy == true, "opencode lazy mismatch"); assert(opencode.event == "VeryLazy", "opencode event mismatch"); assert(opencode._.loaded == nil, "opencode loaded during startup"); print("lazy-spec-ok")' +qa
```

- Result: PASS, printed `lazy-spec-ok`.
- Why chosen: directly proves the two changed plugin specs are lazy and absent from the initial startup load set, while preserving `:Copilot` command-based lazy loading.
- Note: an earlier assertion used `vim.tbl_contains()` assuming `copilot.cmd` was always a list; lazy.nvim preserved it as a string. The assertion was corrected and rerun without implementation changes.

```sh
XDG_CONFIG_HOME="/home/c1/.config/nvim/.worktrees/nvim-startup-flash-fix/.legion/tasks/nvim-startup-flash-fix/tmp-xdg-config" \
XDG_CACHE_HOME="/home/c1/.config/nvim/.worktrees/nvim-startup-flash-fix/.legion/tasks/nvim-startup-flash-fix/tmp-xdg-cache" \
nvim --headless --startuptime ".legion/tasks/nvim-startup-flash-fix/docs/startuptime-after.log" +qa
```

- Result: PASS, wrote `.legion/tasks/nvim-startup-flash-fix/docs/startuptime-after.log`.
- Evidence: the log has one `NVIM STARTING` section and no `copilot` or `opencode` entries.
- Note: the log still records Neovim's built-in TUI `clear screen`; this is expected and not directly removable by plugin config.

```sh
stylua --check "lua/plugins/copilot.lua" "lua/plugins/opencode.lua"
```

- Result: SKIPPED/UNAVAILABLE, `stylua` was not installed in this environment (`zsh:1: command not found: stylua`).
- Why acceptable: the Lua files are tiny table specs, and Neovim startup parsed them successfully.

## Manual UX Check

- Not run in this non-interactive tool session.
- Recommended local check: launch `nvim` normally from the terminal and confirm the initial black flash is no longer noticeable or is materially shorter.

# Test Report

## Summary

- Result: PASS with one environment limitation.
- Scope verified: the early file handler module registers `BufReadCmd` for `.parquet`, `.pqt`, and `.parq`; missing `tw` produces a readable fallback buffer; direct startup with `nvim sample.parquet` is intercepted before LazyVim's `VeryLazy` autocmd phase.
- Limitation: `tw` is not installed in this environment, so automated verification covered the fallback path and autocmd registration rather than launching the real Tabiew TUI.

## Commands

```sh
nvim --headless -u NONE '+luafile lua/config/file_handlers.lua' '+lua local found={}; for _,a in ipairs(vim.api.nvim_get_autocmds({ event = "BufReadCmd", group = "cone_open_parquet_with_tabiew" })) do found[a.pattern]=true end; assert(found["*.parquet"] and found["*.pqt"] and found["*.parq"], "tabiew parquet autocmd patterns missing"); print("file-handlers-autocmd-ok")' '+qa'
```

- Result: PASS, printed `file-handlers-autocmd-ok`.
- Why chosen: directly proves the new early module parses and registers all intended file patterns without depending on LazyVim startup timing.

```sh
nvim --headless -u NONE '+luafile lua/config/file_handlers.lua' '+edit sample.parquet' '+lua local lines=vim.api.nvim_buf_get_lines(0, 0, -1, false); assert(lines[1] == "Tabiew executable `tw` not found.", "missing tw fallback not shown"); assert(vim.bo.buftype == "nofile", "fallback buffer type mismatch"); print("file-handlers-fallback-ok")' '+qa!'
```

- Result: PASS, printed `file-handlers-fallback-ok`.
- Why chosen: verifies the user-facing failure mode when Tabiew is not installed.

```sh
XDG_CONFIG_HOME="$PWD/.legion/tasks/tabiew-parquet-auto-open/tmp-xdg-config" XDG_CACHE_HOME="$PWD/.legion/tasks/tabiew-parquet-auto-open/tmp-xdg-cache" XDG_STATE_HOME="$PWD/.legion/tasks/tabiew-parquet-auto-open/tmp-xdg-state" nvim --headless sample.parquet '+lua local lines=vim.api.nvim_buf_get_lines(0, 0, -1, false); assert(lines[1] == "Tabiew executable `tw` not found.", "direct startup fallback not shown"); assert(vim.bo.buftype == "nofile", "direct startup buffer type mismatch"); print("direct-startup-fallback-ok")' '+qa!'
```

- Result: PASS, printed `direct-startup-fallback-ok`.
- Why chosen: verifies the important startup path, `nvim sample.parquet`, using isolated `XDG_CONFIG_HOME`, `XDG_CACHE_HOME`, and `XDG_STATE_HOME` so the worktree config is loaded instead of the main config.
- Cleanup: temporary `tmp-xdg-*` directories were removed after verification.

```sh
git diff --check
```

- Result: PASS, no output.
- Why chosen: catches whitespace errors and conflict markers before review/commit.

```sh
nvim --headless -u NONE '+luafile lua/config/file_handlers.lua' '+lua local found={}; for _,a in ipairs(vim.api.nvim_get_autocmds({ event = "BufReadCmd", group = "cone_open_parquet_with_tabiew" })) do found[a.pattern]=true end; assert(found["*.parquet"] and found["*.pqt"] and found["*.parq"], "tabiew parquet autocmd patterns missing"); print("main-file-handlers-autocmd-ok")' '+qa'
```

- Result: PASS, printed `main-file-handlers-autocmd-ok` in the active main config directory.
- Why chosen: confirms the synchronized active config has the same file-handler registration as the worktree implementation.

```sh
nvim --headless sample.parquet '+lua local lines=vim.api.nvim_buf_get_lines(0, 0, -1, false); assert(lines[1] == "Tabiew executable `tw` not found.", "direct startup fallback not shown"); assert(vim.bo.buftype == "nofile", "direct startup buffer type mismatch"); print("main-direct-startup-fallback-ok")' '+qa!'
```

- Result: PASS, printed `main-direct-startup-fallback-ok` in the active main config directory.
- Why chosen: confirms the user-facing `~/.config/nvim` configuration now intercepts direct Parquet startup opens.

## Failed / Corrected Attempt

```sh
XDG_CONFIG_HOME="$PWD/.legion/tasks/tabiew-parquet-auto-open/tmp-xdg-config" XDG_CACHE_HOME="$PWD/.legion/tasks/tabiew-parquet-auto-open/tmp-xdg-cache" XDG_STATE_HOME="$PWD/.legion/tasks/tabiew-parquet-auto-open/tmp-xdg-state" nvim --headless '+lua local found={}; for _,a in ipairs(vim.api.nvim_get_autocmds({ event = "BufReadCmd", group = "cone_open_parquet_with_tabiew" })) do found[a.pattern]=true end; assert(found["*.parquet"] and found["*.pqt"] and found["*.parq"], "tabiew parquet autocmd patterns missing"); print("full-config-autocmd-ok")' '+qa'
```

- Result: FAIL before the implementation correction, `Invalid 'group': 'cone_open_parquet_with_tabiew'`.
- Root cause: `lua/config/autocmds.lua` is loaded by LazyVim on `VeryLazy`, which is too late for startup file reads such as `nvim data.parquet`.
- Fix: moved the Parquet `BufReadCmd` registration into `lua/config/file_handlers.lua` and required it from `init.lua` before `require("config.lazy")`.

## Skipped

- `stylua --check`: skipped because `stylua` is unavailable in this environment (`command -v stylua` returned no path).
- Real Tabiew launch: skipped because `tw` is unavailable in this environment (`command -v tw` returned no path). The fallback path is verified; users with Tabiew installed should run `nvim data.parquet` interactively for a final TUI smoke check.

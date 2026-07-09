# Patterns

## Orgmode Agenda Parity With Virtual Tags

- When porting Emacs org-agenda skip-function views to orgmode.nvim matchers, split project parent and project child context into separate virtual agenda tags. In this config, `PROJECT` marks project parents and `PROJECT_TASK` marks active tasks inside a project.
- Inject virtual tags through the orgmode search boundary instead of writing maintenance tags into org text. Ordinary org files should stay free of `PROJECT/STUCK/PROJECT_TASK/ARCHIVE_CANDIDATE` unless those are legacy materialized tags awaiting cleanup.
- Open agenda views that depend on virtual tags through a refresh wrapper. Running `org_legion.refresh_all()` before `b`, `n`, or `s` agenda views prevents stale files from drifting back into Standalone or missing Stuck Projects.
- Verify both the static agenda command structure and the virtual refresh rules. A narrow config-capture test can prove order/header/matcher behavior without real private org files; a separate refresh test should prove parent and child virtual tags are distinct and refresh does not mutate org text.

## Orgmode Refile Destination Picker

- Native orgmode `Input.open(... autocomplete_refile ...)` is not enough when the required UX is a visible fuzzy candidate list. It can still look like a single input prompt after restart.
- Do not set `ui.input.use_vim_ui = true` as a refile UX fix by itself. In this config, that routed refile through Snacks `vim.ui.input` and produced a single input box without the expected candidate list.
- For visible fuzzy refile destinations, patch the destination selection boundary rather than the move logic: reuse orgmode `_get_autocompletion_files()` and headline objects, present candidates with `vim.ui.select`, and return `{ file, headline? }` or `false`.
- Verify file root destinations, unfinished headline destinations, capture buffer refile, org file refile, and cancellation behavior. Headless tests can stub `vim.ui.select`; real visual rendering depends on the picker implementation, such as Snacks.

## Neovim Data Tool Plugins With External CLIs

- Add data tooling plugins as focused `lua/plugins/<name>.lua` lazy.nvim specs instead of changing central LazyVim bootstrap files.
- Prefer command/key lazy-load triggers and explicit keymaps for common workflows.
- Do not install external system CLIs as part of a plugin configuration task unless the task contract explicitly includes system package management.
- Verify and document required external CLIs separately. For Parquet via `dadbod-grip.nvim`, the key runtime dependency is `duckdb`.
- When `Lazy! install` modifies `lazy-lock.json`, review the lockfile and keep only entries authorized by scope.

## Startup-Critical File Handlers

- Do not put first-read `BufReadCmd` handlers in LazyVim's `lua/config/autocmds.lua` when they must handle `nvim <file>` during startup; that file is loaded on `VeryLazy` and can be too late.
- Register startup-critical file handlers from `init.lua` or another module required before `config.lazy`.
- Verify direct startup behavior separately from post-startup `:edit` behavior.
- For external viewer CLIs such as Tabiew's `tw`, provide a clear missing-executable fallback instead of trying to install the CLI from Neovim config.

## SOPS And Secret Editing Plugins

- Treat secret-editing plugin configuration as security-sensitive even when the repository change is only a Neovim plugin spec.
- If a plugin needs `BufReadCmd` handlers before the first supported encrypted file read, use explicit eager loading. Do not lazy-load on `BufReadPre`, `BufEnter`, or similar file events unless upstream documents that it is safe.
- Do not commit account-specific SOPS defaults such as `AWS_PROFILE`, `SOPS_AGE_KEY_FILE`, `GOOGLE_APPLICATION_CREDENTIALS`, key material, or credential paths.
- Verify setup and autocmd registration without opening, decrypting, encrypting, or writing real secret files.
- Document the external `sops` CLI separately; plugin installation does not install or configure SOPS keys.

## Lazy Package Spec Ownership

- Treat repository-owned `lua/plugins/*.lua` specs as the durable source of plugin behavior. Do not rely on plugin-owned `lazy.lua` files for command triggers, dependencies, or setup behavior that this config must preserve.
- If a third-party plugin ships a malformed `lazy.lua` package spec, prefer disabling lazy.nvim's package spec subsystem with `pkg.enabled = false` and declaring needed behavior explicitly in the user config. Changing only `pkg.sources` does not invalidate an existing `pkg-cache.lua`. Do not patch generated plugin clones under `~/.local/share/nvim/lazy/**` as the durable repair.
- When validating a worktree copy of this nvim config, isolate `XDG_CONFIG_HOME`, `XDG_CACHE_HOME`, and `XDG_STATE_HOME`. A plain `nvim -u <worktree>/init.lua` can still resolve modules or Lazy cache from the main config and produce false positives.

## LazyVim Startup Load Reduction

- This config sets `defaults.lazy = false`, so custom plugin specs are startup plugins unless they explicitly opt into lazy loading.
- For plugins that are not needed to draw the first screen, add `lazy = true` and a concrete trigger such as `event`, `cmd`, `keys`, or `ft`.
- Preserve command availability when delaying command-oriented plugins. Example: `copilot.vim` can use `event = "InsertEnter"` for suggestions while keeping `cmd = "Copilot"` for command-triggered loading.
- Do not treat Neovim's startup `clear screen` log entry as a plugin bug. It is built into TUI initialization; optimize plugin work that happens after the clear instead.

## Lazy Lock Runtime Synchronization

- When a Neovim regression starts after `lazy-lock.json` changes, check both the lockfile diff and the installed plugin checkout/build state before editing Lua config.
- Run `Lazy restore` to force installed plugin checkouts to the lockfile and run targeted build tasks for plugins with native artifacts, such as `blink.cmp`.
- For insert-mode failures after LazyVim updates, inspect `InsertEnter` plugins first. In this config, `blink.cmp` and `copilot.vim` are the primary insert-entry candidates.
- Validate TUI insert behavior with `expect` or another real PTY driver. Timer-only TUI scripts can look like Neovim hangs; prove the harness with `nvim --clean`.
- If restore/build resolves the symptom but the original hang is no longer stable, document the result as a runtime-state repair rather than a deterministic source patch.

## macOS Neovim Native Artifact Signing

- When Neovim flash-exits on macOS with no Lua log, check `~/Library/Logs/DiagnosticReports/nvim-*.ips` before continuing plugin-level debugging.
- `SIGKILL (Code Signature Invalid)` with `CODESIGNING Invalid Page` usually means macOS killed Neovim while mapping a native parser or plugin dylib.
- Compare the report's mapped region size with local native files under `~/.local/share/nvim/site/parser/*.so` and plugin artifacts such as `blink.cmp/target/release/*.dylib`.
- For insert-mode crashes involving `blink.cmp`, prefer `fuzzy.implementation = "lua"` when stability matters more than native fuzzy performance.
- After parser/build updates on macOS, ad-hoc sign local artifacts with `codesign --force --sign -` and re-run tree-sitter/parser smoke tests.

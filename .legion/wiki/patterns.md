# Patterns

## Neovim Data Tool Plugins With External CLIs

- Add data tooling plugins as focused `lua/plugins/<name>.lua` lazy.nvim specs instead of changing central LazyVim bootstrap files.
- Prefer command/key lazy-load triggers and explicit keymaps for common workflows.
- Do not install external system CLIs as part of a plugin configuration task unless the task contract explicitly includes system package management.
- Verify and document required external CLIs separately. For Parquet via `dadbod-grip.nvim`, the key runtime dependency is `duckdb`.
- When `Lazy! install` modifies `lazy-lock.json`, review the lockfile and keep only entries authorized by scope.

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

# Patterns

## Neovim Data Tool Plugins With External CLIs

- Add data tooling plugins as focused `lua/plugins/<name>.lua` lazy.nvim specs instead of changing central LazyVim bootstrap files.
- Prefer command/key lazy-load triggers and explicit keymaps for common workflows.
- Do not install external system CLIs as part of a plugin configuration task unless the task contract explicitly includes system package management.
- Verify and document required external CLIs separately. For Parquet via `dadbod-grip.nvim`, the key runtime dependency is `duckdb`.
- When `Lazy! install` modifies `lazy-lock.json`, review the lockfile and keep only entries authorized by scope.

## Lazy Package Spec Ownership

- Treat repository-owned `lua/plugins/*.lua` specs as the durable source of plugin behavior. Do not rely on plugin-owned `lazy.lua` files for command triggers, dependencies, or setup behavior that this config must preserve.
- If a third-party plugin ships a malformed `lazy.lua` package spec, prefer disabling lazy.nvim's package spec subsystem with `pkg.enabled = false` and declaring needed behavior explicitly in the user config. Changing only `pkg.sources` does not invalidate an existing `pkg-cache.lua`. Do not patch generated plugin clones under `~/.local/share/nvim/lazy/**` as the durable repair.
- When validating a worktree copy of this nvim config, isolate `XDG_CONFIG_HOME`, `XDG_CACHE_HOME`, and `XDG_STATE_HOME`. A plain `nvim -u <worktree>/init.lua` can still resolve modules or Lazy cache from the main config and produce false positives.

## LazyVim Startup Load Reduction

- This config sets `defaults.lazy = false`, so custom plugin specs are startup plugins unless they explicitly opt into lazy loading.
- For plugins that are not needed to draw the first screen, add `lazy = true` and a concrete trigger such as `event`, `cmd`, `keys`, or `ft`.
- Preserve command availability when delaying command-oriented plugins. Example: `copilot.vim` can use `event = "InsertEnter"` for suggestions while keeping `cmd = "Copilot"` for command-triggered loading.
- Do not treat Neovim's startup `clear screen` log entry as a plugin bug. It is built into TUI initialization; optimize plugin work that happens after the clear instead.

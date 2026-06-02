# Patterns

## Neovim Data Tool Plugins With External CLIs

- Add data tooling plugins as focused `lua/plugins/<name>.lua` lazy.nvim specs instead of changing central LazyVim bootstrap files.
- Prefer command/key lazy-load triggers and explicit keymaps for common workflows.
- Do not install external system CLIs as part of a plugin configuration task unless the task contract explicitly includes system package management.
- Verify and document required external CLIs separately. For Parquet via `dadbod-grip.nvim`, the key runtime dependency is `duckdb`.
- When `Lazy! install` modifies `lazy-lock.json`, review the lockfile and keep only entries authorized by scope.

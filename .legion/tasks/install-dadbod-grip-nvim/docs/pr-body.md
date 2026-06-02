## Summary

- Install `joryeugene/dadbod-grip.nvim` for DuckDB-backed data/Parquet exploration in Neovim.
- Add lazy.nvim command triggers and database/data keymaps.
- Lock only the new plugin entry without changing existing plugin pins.

## Verification

- `nvim --headless -u NONE "+luafile lua/plugins/dadbod-grip.lua" +qa`
- Isolated worktree Neovim config: `Lazy! install dadbod-grip.nvim`, `Lazy load dadbod-grip.nvim`, headless `+qa`
- `git diff -- lazy-lock.json` confirmed only `dadbod-grip.nvim` was added

## Notes

- `duckdb` CLI is not installed in the current shell; Parquet workflows require installing DuckDB separately.

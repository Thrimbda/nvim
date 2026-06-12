## Summary

- add an early Neovim file handler for `.parquet`, `.pqt`, and `.parq`
- launch Tabiew via `tw <absolute-path>` when available
- show a clear install hint when `tw` is missing

## Why

`lua/config/autocmds.lua` is loaded by LazyVim on `VeryLazy`, which is too late for `nvim data.parquet`. The handler is loaded from `init.lua` before `config.lazy` so direct startup opens work.

## Verification

- `nvim --headless -u NONE '+luafile lua/config/file_handlers.lua' ...` passed autocmd registration checks
- `nvim --headless -u NONE '+luafile lua/config/file_handlers.lua' '+edit sample.parquet' ...` passed missing-`tw` fallback checks
- isolated worktree config `nvim --headless sample.parquet ...` passed direct startup fallback checks
- `git diff --check`

## Notes

- `tw` is not installed in this environment, so real Tabiew TUI launch was not automated.
- No plugin or lockfile changes are included.

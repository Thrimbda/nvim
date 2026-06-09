# nvim-insert-mode-freeze-fix

## Summary

- Force `blink.cmp` to use Lua fuzzy matching to avoid native dylib load on insert.
- Add macOS ad-hoc signing helper for Neovim native artifacts.
- Pin `nvim-treesitter` to the lockfile commit and sign parser artifacts after builds.
- Update Legion evidence for the reopened code-sign crash diagnosis and verification.

## Validation

- `blink.cmp` config check: `fuzzy.implementation = lua`
- Markdown tree-sitter smoke: exit 0
- Org tree-sitter smoke: exit 0
- TUI insert + typing smoke: exit 0
- Crash report check: no new `nvim` DiagnosticReport after final verification

## Notes

Runtime repair also re-signed the currently installed parser/native artifacts under `~/.local/share/nvim`.

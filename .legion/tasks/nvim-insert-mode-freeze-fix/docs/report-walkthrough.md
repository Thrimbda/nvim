# Report Walkthrough: nvim-insert-mode-freeze-fix

Mode: implementation.

## What Changed

- Forced `blink.cmp` to use the Lua fuzzy matcher instead of loading its native dylib on insert.
- Added a macOS native-artifact signing helper for local parser/native outputs.
- Pinned `nvim-treesitter` to the lockfile commit and added build-time signing for parser artifacts.
- Re-signed the currently installed tree-sitter parsers, `orgmode` parser, and `blink.cmp` dylib.
- Updated Legion task evidence for the reopened diagnosis, verification, review, and wiki notes.

## Why

The first restore/build pass was insufficient. macOS crash reports showed Neovim being killed by code signing enforcement while mapping native artifacts. Insert mode loads `blink.cmp`, and normal file editing loads tree-sitter parsers, so both native paths had to be addressed.

## Verification

See `docs/test-report.md`.

Validated:

- `blink.cmp` config reports `fuzzy.implementation = lua`.
- Markdown and org tree-sitter parsers start successfully.
- TUI insert + typing smoke exits 0.
- No new `nvim` DiagnosticReports appear after final verification.

## Review

See `docs/review-change.md`.

Verdict: PASS.

## Residual Risk

Restart existing embedded Neovim/VS Code Neovim sessions before retesting, because already-running processes will not reload this config.

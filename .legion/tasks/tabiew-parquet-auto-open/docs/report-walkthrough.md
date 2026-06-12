# Report Walkthrough

## Mode

Implementation.

## What Changed

- Added `lua/config/file_handlers.lua` with a startup-critical `BufReadCmd` handler for `*.parquet`, `*.pqt`, and `*.parq`.
- Updated `init.lua` to require `config.file_handlers` before `config.lazy`.
- Kept `lua/config/autocmds.lua` unchanged for its existing `VeryLazy`-loaded behavior.

## Why It Changed This Way

- The original suggested location, `lua/config/autocmds.lua`, is too late for the key workflow `nvim data.parquet` because LazyVim loads that file on `VeryLazy`.
- Registering the handler before LazyVim startup preserves both direct command-line opens and later picker or `:e` opens.
- Tabiew remains an external dependency; Neovim config only detects `tw`, launches it when present, and shows install guidance when absent.

## Verification Evidence

- `docs/test-report.md` records PASS for early module autocmd registration.
- `docs/test-report.md` records PASS for the missing-`tw` fallback buffer.
- `docs/test-report.md` records PASS for direct startup handling through `nvim sample.parquet` with isolated worktree config paths.
- `docs/test-report.md` records PASS for `git diff --check`.

## Review Evidence

- `docs/review-change.md` verdict: PASS.
- No blocking correctness, maintainability, scope, or security findings.
- Residual risk is limited to a real interactive Tabiew smoke test after `tw` is installed.

## Reviewer Notes

- The branch intentionally does not install Tabiew or modify `lazy-lock.json`.
- This change handles `.parquet`, `.pqt`, and `.parq` only.
- If reviewing interactively with Tabiew installed, open a real Parquet file with `nvim data.parquet` and quit Tabiew with `Q` to confirm the terminal buffer is wiped.

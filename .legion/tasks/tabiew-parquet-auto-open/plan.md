# tabiew-parquet-auto-open

## Contract

- `name`: Open Parquet files with Tabiew from Neovim
- `taskId`: `tabiew-parquet-auto-open`
- `goal`: Opening `.parquet` files from Neovim should automatically show an interactive Tabiew table view instead of a raw binary buffer.
- `problem`: Parquet files are not useful as normal Neovim buffers. The desired workflow is zero-command viewing from `nvim data.parquet`, Telescope, Neo-tree, or other file open paths.

## Acceptance

- `nvim data.parquet`, `:e data.parquet`, and picker-based opens trigger a terminal running `tw <absolute-file-path>` for readable Parquet files.
- `.pqt` and `.parq` aliases are handled the same way as `.parquet`.
- If `tw` is unavailable, the buffer shows a clear install hint instead of failing silently.
- The implementation is confined to Neovim configuration and Legion task evidence.
- Verification confirms the config loads and the autocmd is registered without requiring a real Parquet fixture.

## Scope

- `init.lua` - load startup-critical file handlers before LazyVim's `VeryLazy` autocmd phase.
- `lua/config/file_handlers.lua` - add a dedicated BufReadCmd autocmd for Parquet-like extensions.
- `.legion/tasks/tabiew-parquet-auto-open/` - record contract, progress, verification, review, and handoff evidence.
- `.legion/wiki/**` - update only if a reusable Neovim configuration pattern is worth preserving.

## Non-Goals

- Do not install Tabiew system-wide from Neovim configuration.
- Do not add a Neovim data viewer plugin such as `data-explorer.nvim`, `data-preview.nvim`, or `dadbod-grip.nvim`.
- Do not change CSV, JSON, SQLite, Excel, or other data-file open behavior.
- Do not modify plugin lockfiles or unrelated LazyVim settings.

## Assumptions

- The user accepts Tabiew as the preferred external viewer and will install the `tw` executable separately if it is missing.
- `BufReadCmd` is the right interception point because it covers direct edits and file-picker opens that resolve to normal buffer reads.
- Running a terminal TUI inside the current Neovim buffer is acceptable for this workflow.

## Constraints

- Keep the change small, local, and reversible.
- Preserve existing LazyVim configuration style.
- Avoid touching existing unrelated local changes, including main-worktree `lazy-lock.json` modifications.

## Risks

- If `tw` is not installed, viewing cannot work; the fallback message must make this obvious.
- Some open paths may provide different autocmd args; the implementation should normalize the selected file path defensively.
- Terminal lifecycle handling must not leave stale buffers after the Tabiew process exits.

## Design Summary

- Use a dedicated `BufReadCmd` autocmd for `*.parquet`, `*.pqt`, and `*.parq`.
- Register this handler before `require("config.lazy")`; `lua/config/autocmds.lua` loads on `VeryLazy` and is too late for `nvim data.parquet` startup reads.
- Resolve the opened file to an absolute path before invoking `tw`.
- Use `termopen({ "tw", file })` in the target buffer and wipe the buffer after the terminal process exits.
- When `tw` is missing, replace the buffer with a short non-modifiable installation hint.
- Risk level: Low configuration change; no RFC required unless implementation reveals broader file-opening conflicts.

## Phases

- Brainstorm: create this stable task contract and scope boundary.
- Engineer: add the minimal autocmd and keep changes localized.
- Verify: run headless Neovim checks for config load and autocmd registration.
- Review: check for regressions, lifecycle issues, and out-of-scope edits.
- Report: write walkthrough evidence and update wiki if useful.

---
*Created: 2026-06-11 | Updated: 2026-06-11*

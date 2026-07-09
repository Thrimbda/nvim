# Legion Wiki Log

## 2026-07-09

- Added wiki summary for `org-agenda-norang-parity-fix`.
- Added orgmode agenda parity pattern: split project parent and project child context into virtual agenda tags, inject them through search adapter, and refresh before virtual-tag agenda views.
- Added wiki summary for `org-refile-fuzzy-prompt`.
- Added orgmode refile input pattern: keep refile destination on orgmode native input completion unless a replacement UI proves candidate visibility and preserves upstream refile semantics.
- Updated `org-refile-fuzzy-prompt` after follow-up failure: native input completion was insufficient for visible fuzzy candidates; current solution is a `vim.ui.select` / Snacks picker patch that preserves orgmode destination shape.
- Replaced the orgmode refile pattern with current picker guidance: patch destination selection, keep refile move semantics, and verify file/headline/cancel behavior.

## 2026-06-11

- Added wiki summary for `tabiew-parquet-auto-open`.
- Added startup-critical file handler pattern: first-read `BufReadCmd` integrations that must catch `nvim <file>` should load before `config.lazy`, not from LazyVim's `VeryLazy` autocmd file.

## 2026-06-09

- Added wiki summary for `nvim-insert-mode-freeze-fix`.
- Added Lazy lock runtime synchronization pattern: after lockfile changes, verify installed plugin checkouts/build artifacts with `Lazy restore` and targeted build tasks before changing Lua config.
- Updated `nvim-insert-mode-freeze-fix` after reopened failure: root cause involved macOS code-sign kills for Neovim native artifacts; added native artifact signing pattern.

## 2026-06-08

- Added wiki summary for `install-sops-nvim`.
- Added reusable SOPS/secret-editing plugin pattern: eager-load first-read BufReadCmd integrations, avoid credential defaults, and verify without touching real secret files.
- Added wiki summary for `update-sops-nvim` and updated current `sops.nvim` lock pin to `1656dac4d893f2d96c7ccb6d3fa3259bde6004e5`.

## 2026-06-02

- Created wiki summary for `install-dadbod-grip-nvim`.
- Added a reusable Neovim plugin installation pattern for external CLI-backed data tools.

## 2026-06-03

- Added wiki summary for `nvim-dadbod-grip-invalid-lazy-spec-fix`.
- Added Lazy package spec ownership and isolated worktree validation patterns.
- Updated Lazy package spec ownership after follow-up: `pkg.enabled = false` is required when stale `pkg-cache.lua` entries already exist.
- Added wiki summary for `nvim-startup-flash-fix`.
- Added LazyVim startup load reduction pattern for explicit lazy loading under `defaults.lazy = false`.

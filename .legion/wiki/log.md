# Legion Wiki Log

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

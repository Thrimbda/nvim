# Report Walkthrough: install-sops-nvim

Mode: implementation

## What Changed

- Added `lua/plugins/sops.lua` to register `Thrimbda/sops.nvim` through the existing LazyVim/lazy.nvim `plugins` import.
- Configured the plugin with upstream-required eager loading: `lazy = false`.
- Set `main = "nvim_sops"` and `opts = {}` to call the correct setup module without hardcoding any secret or account-specific defaults.
- Added `sops.nvim` to `lazy-lock.json` at commit `63d5eba3f60dc15291d7cd89243d200a8476a075`.
- Recorded Legion contract, RFC, RFC review, verification, and change review evidence under `.legion/tasks/install-sops-nvim/`.

## Why

The requested plugin needs `BufReadCmd`/`BufWriteCmd` handlers registered before the first supported encrypted file is opened. Lazy-loading on file events would be too late for the first read, so the RFC chose an eager minimal spec with no personal credential defaults.

## Evidence

- Design: `docs/rfc.md`
- RFC review: `docs/review-rfc.md` PASS
- Verification: `docs/test-report.md` PASS with documented external dependency gaps
- Change review: `docs/review-change.md` PASS with security lens applied

## Verification Summary

- Targeted `nvim_sops` module setup and `BufReadCmd` registration passed in a clean Neovim runtime.
- Full headless Neovim config load passed after isolated runtime setup.
- `sops` is not installed on this host; this is documented as an external runtime dependency outside this task.
- `stylua` is not installed on this host; formatting could not be run, but the new Lua file is minimal and formatted consistently.

## Reviewer Notes

- No secret material, credential paths, SOPS key paths, or real encrypted files are included.
- To use the plugin interactively, install and configure the external `sops` CLI separately.

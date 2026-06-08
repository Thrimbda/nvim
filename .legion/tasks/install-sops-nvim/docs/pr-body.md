## Summary

- Install `Thrimbda/sops.nvim` through the existing LazyVim/lazy.nvim plugin import.
- Pin `sops.nvim` in `lazy-lock.json` and use upstream-required eager loading with `main = "nvim_sops"`.
- Record Legion RFC, verification, review, and walkthrough evidence for the SOPS editing workflow change.

## Verification

- PASS: targeted `nvim_sops` setup/autocmd assertion in clean headless Neovim.
- PASS: full headless Neovim config load after isolated runtime setup.
- Documented: `sops` CLI is not installed on this host and remains an external runtime dependency.
- Documented: `stylua` is not installed on this host, so formatter execution was skipped.

## Security

- No secret material, credential paths, key files, or real encrypted files are committed.
- No account-specific SOPS defaults are hardcoded.

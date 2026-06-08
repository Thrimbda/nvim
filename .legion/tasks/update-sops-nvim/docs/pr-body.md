## Summary

- Update `sops.nvim` in `lazy-lock.json` from `63d5eba3f60dc15291d7cd89243d200a8476a075` to `1656dac4d893f2d96c7ccb6d3fa3259bde6004e5`.
- Keep `lua/plugins/sops.lua` unchanged because upstream still uses the existing `nvim_sops` setup path.
- Record Legion RFC, verification, review, and walkthrough evidence for the SOPS plugin update.

## Verification

- PASS: updated `nvim_sops` module setup and `BufReadCmd` registration in headless Neovim.
- PASS: full worktree Neovim config headless load with isolated XDG paths.
- Documented: `sops` CLI is not installed on this host and remains an external runtime dependency.
- Documented: `stylua` is not installed on this host, so formatter execution was skipped.

## Security

- No secret material, credential paths, key files, or real encrypted files are committed.
- No account-specific SOPS defaults are changed.
- Scope intentionally excludes unrelated plugin pin updates.

# RFC: Update Thrimbda/sops.nvim Lock

## Context

`Thrimbda/sops.nvim` is already installed through `lua/plugins/sops.lua` with eager loading and `main = "nvim_sops"`. The current lockfile pins commit `63d5eba3f60dc15291d7cd89243d200a8476a075`.

Upstream HEAD is now `1656dac4d893f2d96c7ccb6d3fa3259bde6004e5`. The upstream compare reports one commit: `fix: derive SOPS keys from metadata on save (#1)`. Source inspection confirms the plugin entrypoint and `require("nvim_sops").setup({})` path remain present, while the save path now derives reusable SOPS encryption flags from existing file metadata.

## Goals

- Update only the `sops.nvim` lazy.nvim lock entry to upstream HEAD.
- Keep the existing `lua/plugins/sops.lua` eager-load spec unchanged if upstream setup remains compatible.
- Verify module setup/autocmd registration and full Neovim config load without touching real secret files.
- Avoid committing unrelated plugin pin updates already present in the main workspace.

## Non-Goals

- Updating all lazy.nvim plugin pins.
- Installing `sops`, `stylua`, Mason packages, or system dependencies.
- Configuring SOPS keys, credentials, profiles, or creation rules.
- Creating, decrypting, encrypting, or writing real secret files.

## Options

### Option A: Lockfile-only update

Change only `lazy-lock.json` so `sops.nvim` points to `1656dac4d893f2d96c7ccb6d3fa3259bde6004e5`.

Trade-offs:

- Minimal and matches the user's update request.
- Avoids widening scope to unrelated plugin updates.
- Keeps existing security-sensitive plugin defaults unchanged.
- Depends on targeted verification to catch setup compatibility issues.

### Option B: Run a broad lazy.nvim update

Use lazy.nvim to update all outdated plugins and commit the resulting lockfile.

Trade-offs:

- Brings the full plugin set up to date.
- Violates the task scope by mixing unrelated plugin pin changes with a SOPS plugin update.
- Makes review and rollback noisier.

### Option C: Modify plugin spec while updating

Update the lockfile and change `lua/plugins/sops.lua` options or loading behavior.

Trade-offs:

- Useful only if upstream changed the setup contract.
- Current source inspection shows no setup contract change, so this adds unnecessary risk.
- Any secret-specific defaults would violate the established SOPS plugin pattern.

## Decision

Use Option A.

The implementation will update only the `sops.nvim` line in `lazy-lock.json`. `lua/plugins/sops.lua` remains unchanged because the upstream `plugin/nvim_sops.vim` and `lua/nvim_sops/init.lua` setup contract still match the existing spec.

## Scope

- `lazy-lock.json`: update only `sops.nvim` commit.
- `.legion/tasks/update-sops-nvim/**`: task evidence.
- `.legion/wiki/**`: closeout summary if useful.

## Verification

- Confirm the new upstream commit with `git ls-remote` or cloned source.
- Clone or otherwise load the updated plugin in an isolated worktree-local runtime.
- Run a targeted headless Neovim assertion that `require("nvim_sops").setup({})` succeeds and registers `BufReadCmd` handlers.
- Run a full headless config load with isolated XDG directories.
- Check external `sops` availability and document it as a runtime dependency gap if missing.

## Rollback

Rollback is a Git revert of the PR or changing the `sops.nvim` lock entry back to `63d5eba3f60dc15291d7cd89243d200a8476a075`.

No config schema, secret files, or system packages are changed. If the new upstream commit causes a regression, reverting the single lockfile line restores the previous plugin source.

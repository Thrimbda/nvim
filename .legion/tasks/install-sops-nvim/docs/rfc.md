# RFC: Install Thrimbda/sops.nvim

## Context

The Neovim configuration uses LazyVim with lazy.nvim and imports all files under `lua/plugins/`. The user requested installation of `https://github.com/Thrimbda/sops.nvim`, a plugin that wraps the external `sops` CLI and registers `BufReadCmd`/`BufWriteCmd` handlers for `*.enc.env`, `*.enc.json`, and `*.enc.yaml`.

This is a small configuration change, but it adds a new dependency in a secrets-related editing workflow. The design needs to keep the installation minimal while avoiding secret-specific configuration or unsafe lazy-loading.

## Goals

- Register `Thrimbda/sops.nvim` in the existing lazy.nvim plugin import path.
- Follow upstream's requirement that the plugin load before the first supported encrypted file is read.
- Keep setup defaults generic and avoid embedding personal key or cloud credential paths.
- Verify the updated Neovim configuration without creating or editing real secret files.

## Non-Goals

- Install the `sops` CLI or key management tools.
- Configure `AWS_PROFILE`, `SOPS_AGE_KEY_FILE`, `GOOGLE_APPLICATION_CREDENTIALS`, or other user-specific secret settings.
- Create, decrypt, encrypt, or modify real SOPS files.
- Replace the requested plugin with an alternative unless this repository is unusable.

## Options

### Option A: Minimal eager lazy.nvim spec

Add `lua/plugins/sops.lua` with `Thrimbda/sops.nvim`, `lazy = false`, `main = "nvim_sops"`, and empty `opts`.

Trade-offs:

- Matches upstream lazy.nvim guidance for early `BufReadCmd` registration.
- Avoids module inference risk by naming `nvim_sops` explicitly.
- Avoids hardcoded secrets or account-specific defaults.
- Adds startup-loaded plugin code, but the plugin is small and upstream requires eager loading.

### Option B: Configure account-specific defaults

Add the plugin plus `defaults.awsProfile`, `defaults.ageKeyFile`, or `defaults.gcpCredentialsPath` values.

Trade-offs:

- Could improve convenience for one local environment.
- Risks committing credential paths or secret workflow assumptions into shared config.
- Violates the task constraint to avoid hardcoded secret or account defaults.

### Option C: Lazy-load on encrypted-file events

Add the plugin with `event = "BufReadPre"`, `BufEnter`, or similar file-triggered lazy loading.

Trade-offs:

- Reduces startup loading.
- Conflicts with upstream warning that these events are too late for the first encrypted file because `BufReadCmd` handlers must already exist.
- Risks a broken first-open workflow, which is the main value of this plugin.

## Decision

Use Option A.

The implementation will add a dedicated `lua/plugins/sops.lua` spec:

- `"Thrimbda/sops.nvim"`
- `lazy = false`
- `main = "nvim_sops"`
- `opts = {}`

No keymaps or personal defaults will be added. The upstream workflow is automatic for supported file suffixes, and any system-level dependency gap will be documented instead of fixed by this task.

## Scope

- Add `lua/plugins/sops.lua`.
- Allow `lazy-lock.json` to update if lazy.nvim installs or syncs the plugin.
- Record task evidence under `.legion/tasks/install-sops-nvim/`.
- Update `.legion/wiki/` only with reusable closeout knowledge.

## Verification

- Run formatting on the new Lua spec if available or applicable.
- Run headless Neovim load against the worktree configuration.
- Run lazy.nvim install/sync verification for `sops.nvim` and record whether `lazy-lock.json` changes.
- Check `sops --version`; if missing, record it as an external dependency gap rather than installing it.
- Do not open or write real encrypted files during verification.

## Rollback

Rollback is a plain Git revert of the PR or removal of `lua/plugins/sops.lua` plus any `lazy-lock.json` entry for `sops.nvim`.

No data migration is introduced. No secret files are modified as part of this task. If the external plugin later proves unsuitable, the revert returns Neovim to the previous state because the change is isolated to a plugin spec and generated lockfile state.

## Open Questions

- None for implementation. User-specific SOPS key and credential setup remains outside this task.

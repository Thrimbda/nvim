# install-sops-nvim

## Task Contract

- **Name**: Install sops.nvim
- **Task ID**: install-sops-nvim
- **Goal**: Install `Thrimbda/sops.nvim` in the existing LazyVim/lazy.nvim Neovim configuration so supported SOPS encrypted files can be edited transparently from Neovim.
- **Problem**: The current Neovim config does not register a SOPS integration plugin. The user asked to install `https://github.com/Thrimbda/sops.nvim` through the Legion workflow.

## Acceptance

- [ ] A lazy.nvim plugin spec for `Thrimbda/sops.nvim` exists under `lua/plugins/` and is discoverable through the existing `{ import = "plugins" }` entry.
- [ ] The spec follows upstream loading requirements: the plugin is not lazy-loaded, `nvim_sops` is used as the setup module, and no secrets or account-specific defaults are hardcoded.
- [ ] `lazy-lock.json` is updated if lazy.nvim installation or sync verification changes the lockfile.
- [ ] Neovim can load the updated configuration headlessly, or any external dependency gap is documented.
- [ ] Legion verification, review, walkthrough, and wiki evidence are recorded before closeout.

## Assumptions

- The repository uses LazyVim with lazy.nvim and imports `lua/plugins/*.lua` through `lua/config/lazy.lua`.
- This task installs the Neovim plugin only. The `sops` CLI, keys, cloud credentials, and SOPS creation rules are user/system dependencies.
- The default plugin workflow is automatic for `*.enc.env`, `*.enc.json`, and `*.enc.yaml`; no keymaps are required by upstream.

## Constraints

- Keep the change minimal and avoid broad LazyVim restructuring.
- Do not install system packages or write outside this repository.
- Do not hardcode secret material, credential paths, AWS profiles, age key paths, or GCP credential paths.
- Do not introduce extra commands/keymaps unless needed for successful plugin setup.

## Risks

- `sops.nvim` depends on the external `sops` command and valid SOPS configuration; plugin installation alone may not make encrypted file editing usable on every machine.
- The target repository is very small and has no releases; pinning is through lazy.nvim's lockfile rather than plugin tags.
- The plugin writes encrypted output back on `:w` for supported suffixes, so SOPS creation rules must already be correct for new or modified files.

## Scope

- `lua/plugins/sops.lua`
- `lazy-lock.json` if changed by lazy.nvim verification
- `.legion/tasks/install-sops-nvim/**`
- `.legion/wiki/**` closeout writeback when reusable task knowledge needs updating

## Non-Goals

- Installing the `sops` CLI or any key management tool.
- Configuring personal keys, cloud credentials, account profiles, or repository-specific SOPS creation rules.
- Creating, decrypting, or modifying real secret files as part of verification.
- Replacing this requested plugin with another SOPS plugin unless the requested repository proves unusable.

## Design Summary

- Add a focused LazyVim plugin spec in `lua/plugins/sops.lua` for `Thrimbda/sops.nvim`.
- Set `lazy = false` because upstream requires BufReadCmd handlers before the first encrypted file read.
- Set `main = "nvim_sops"` and `opts = {}` so lazy.nvim calls the correct setup module without relying on repository-name inference.
- Verify with headless Neovim loading and lazy.nvim plugin sync/install behavior; document any external `sops` CLI gap instead of installing it.

## Phases

1. **Contract** - Create a stable Legion task contract and checklist.
2. **Design** - Record the dependency, loading, verification, and rollback decision in a standard RFC.
3. **Implementation** - Add the lazy.nvim spec and update generated lockfile state if needed.
4. **Verification** - Validate headless Neovim load and dependency readiness far enough to prove the config is usable.
5. **Review** - Review the resulting diff for scope, security, and behavioral risk.
6. **Closeout** - Record walkthrough and wiki writeback, then complete the Git/PR lifecycle or document blockers.

---

Created: 2026-06-08

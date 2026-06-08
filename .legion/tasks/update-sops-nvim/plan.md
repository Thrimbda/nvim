# update-sops-nvim

## Task Contract

- **Name**: Update sops.nvim
- **Task ID**: update-sops-nvim
- **Goal**: Update the existing `Thrimbda/sops.nvim` lazy.nvim lock entry from `63d5eba3f60dc15291d7cd89243d200a8476a075` to the current upstream HEAD `1656dac4d893f2d96c7ccb6d3fa3259bde6004e5`.
- **Problem**: The repository already installs `Thrimbda/sops.nvim`, but the lockfile points at an older commit. The user asked to update this plugin and submit the change through Legion workflow.

## Acceptance

- [ ] `lazy-lock.json` updates only the `sops.nvim` entry to upstream HEAD `1656dac4d893f2d96c7ccb6d3fa3259bde6004e5` unless verification proves a different commit is required.
- [ ] `lua/plugins/sops.lua` remains functionally unchanged unless upstream changes require config adjustment.
- [ ] No other plugin pins, secret files, credential paths, key material, or account-specific SOPS defaults are changed.
- [ ] Neovim can load the updated configuration headlessly, or any external dependency gap is documented.
- [ ] Legion verification, review, walkthrough, wiki writeback, and Git/PR lifecycle are completed.

## Assumptions

- The user's phrase "this plugin" refers to the `Thrimbda/sops.nvim` plugin installed in the immediately preceding task.
- The update target is upstream repository HEAD because `sops.nvim` does not publish releases or tags in the existing workflow.
- The `sops` CLI and user SOPS key configuration remain external runtime dependencies.

## Constraints

- Keep this as a lockfile-only plugin update unless upstream requires a config change.
- Do not install system packages or write persistent artifacts outside this repository.
- Do not commit the main workspace's pre-existing broad `lazy-lock.json` plugin pin updates.
- Do not open, decrypt, encrypt, or write real secret files during verification.

## Risks

- `sops.nvim` is part of a secrets editing workflow; even lockfile-only updates should be reviewed through a security lens.
- Upstream behavior could change between commits and affect automatic `BufReadCmd`/`BufWriteCmd` handling.
- Clean lazy.nvim bootstrap can be noisy because existing Mason/Treesitter setup may install tools; verification should use the narrowest credible checks.

## Scope

- `lazy-lock.json`
- `.legion/tasks/update-sops-nvim/**`
- `.legion/wiki/**` closeout writeback when useful
- `lua/plugins/sops.lua` only if upstream requires a config adjustment

## Non-Goals

- Updating every plugin in `lazy-lock.json`.
- Installing `sops`, `stylua`, Mason packages, or any system dependencies.
- Configuring keys, cloud credentials, profiles, SOPS rules, or secret files.
- Reworking the existing `sops.nvim` lazy.nvim spec unless required by upstream.

## Design Summary

- Treat the update as a narrow dependency pin bump: compare the current lock entry with upstream HEAD and change only `sops.nvim`.
- Reuse the existing eager-load plugin spec unless upstream source inspection or verification shows it no longer matches the plugin setup contract.
- Validate with a targeted `nvim_sops` module setup/autocmd assertion and a full headless config load using isolated XDG directories.
- Preserve the user's unrelated main-workspace `lazy-lock.json` changes by doing implementation in a worktree from `origin/master`.

## Phases

1. **Contract** - Create a stable Legion task contract and checklist.
2. **Design** - Record the narrow update decision and verification/rollback path.
3. **Implementation** - Update the `sops.nvim` lock entry only.
4. **Verification** - Validate module setup and headless config load without touching secret files.
5. **Review** - Review scope, security, and verification evidence.
6. **Closeout** - Record walkthrough and wiki writeback, then complete PR lifecycle.

---

Created: 2026-06-08

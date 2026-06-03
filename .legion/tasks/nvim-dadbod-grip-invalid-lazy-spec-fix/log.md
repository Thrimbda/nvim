# Nvim Dadbod Grip Invalid Lazy Spec Fix Log

## 2026-06-03

- Entered Legion via `legion-workflow`; no existing task id/path was provided, so entered `brainstorm`.
- Located current user plugin spec at `lua/plugins/dadbod-grip.lua`; it includes the plugin source `joryeugene/dadbod-grip.nvim` and is not the command-only invalid spec shown in the error.
- Located the command-only invalid fragment at `/home/c1/.local/share/nvim/lazy/dadbod-grip.nvim/lazy.lua`.
- Confirmed with the user that the fix should be repository-owned in `/home/c1/.config/nvim`, use a worktree, and avoid cache-only repair or old-commit pinning.
- Materialized the robust Lazy package-spec repair contract.
- Created worktree `.worktrees/nvim-dadbod-grip-invalid-lazy-spec-fix/` on branch `legion/nvim-dadbod-grip-invalid-lazy-spec-fix` from `origin/master`.
- Engineer stage: configured lazy.nvim `pkg.sources` to exclude plugin-owned `lazy.lua` package specs and keep `rockspec`/`packspec` sources.
- Engineer stage: expanded `lua/plugins/dadbod-grip.lua` to explicitly declare every actual `Grip*` command created by the plugin and removed the undeclared `GripToggle` trigger.
- Engineer check: isolated worktree Neovim startup succeeded and `dadbod-grip.nvim` command triggers included `GripOpen`.
- Engineer check: isolated package cache no longer included `dadbod-grip.nvim/lazy.lua` or `noice.nvim/lazy.lua`; LazyVim already declares `noice.nvim` and `nui.nvim` explicitly.
- Verify stage: isolated worktree Neovim startup passed.
- Verify stage: `Lazy! reload` passed under isolated worktree config/state/cache.
- Verify stage: Lazy config assertions confirmed the `lazy` package source is disabled, dadbod-grip command triggers are complete, `GripToggle` is absent, and problematic plugin-owned `lazy.lua` specs are absent from package cache.
- Verify stage: `GripHome` command lazy-load trigger passed.
- Verify stage: `git diff --check` passed; `stylua` was unavailable in the current environment.
- Review stage: readiness review passed with no blocking findings.
- Review note: no security trigger was present; `stylua` absence is a non-blocking tooling gap because Neovim parsed the modified Lua files during validation.
- Report stage: generated implementation-mode `docs/report-walkthrough.md` and `docs/pr-body.md` from existing validation and review evidence.
- Wiki stage: added task summary plus Lazy package-spec ownership and isolated worktree validation patterns.

## 2026-06-03 Follow-Up

- User reported the same invalid `Grip` command-only plugin spec after PR #2 merged.
- Diagnosed the missed path: live `~/.local/state/nvim/lazy/pkg-cache.lua` still contained the old `dadbod-grip.nvim/lazy.lua` package spec. Removing `lazy` from `pkg.sources` does not prevent lazy.nvim from loading an already-existing package cache.
- Follow-up implementation: changed `lua/config/lazy.lua` from `pkg.sources = { "rockspec", "packspec" }` to `pkg.enabled = false` so Lazy skips package-spec loading entirely.
- Follow-up verification passed with the live stale package cache still present: package specs were not loaded into Lazy meta, `Lazy! reload` passed, `GripHome` lazy-loaded, and `git diff --check` passed.

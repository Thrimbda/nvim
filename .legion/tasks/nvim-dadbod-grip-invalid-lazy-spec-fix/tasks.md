# Nvim Dadbod Grip Invalid Lazy Spec Fix Tasks

## Status

- Current stage: follow-up review/wiki complete; PR lifecycle pending.
- Execution mode: default implementation mode, low-risk config repair path.
- Worktree: `.worktrees/nvim-dadbod-grip-invalid-lazy-spec-fix/`
- Branch: `legion/nvim-dadbod-grip-invalid-lazy-spec-fix`
- Base ref: `origin/master`

## Checklist

- [x] Identify the invalid `Grip` command-only spec source.
- [x] Confirm robust repository-owned fix boundary with the user.
- [x] Materialize the Neovim Lazy package-spec repair contract.
- [x] Create isolated worktree from `origin/master`.
- [x] Patch Lazy package-source handling and affected plugin declarations.
- [x] Run targeted Neovim/Lazy validation and record a test report.
- [x] Run readiness review.
- [x] Generate walkthrough/PR body.
- [x] Write Legion wiki updates.
- [ ] Commit, push, open PR, and follow PR lifecycle if requested/available.
- [ ] Cleanup worktree and refresh main workspace after terminal state.

## Handoff Notes

- Reported error: `Invalid plugin spec { cmd = { "Grip", "GripStart", ... } }`.
- Root-cause observation: `/home/c1/.local/share/nvim/lazy/dadbod-grip.nvim/lazy.lua` returns a command-only fragment without a plugin source.
- User explicitly requested a real repository fix, not a cautious compatibility workaround, cache-only repair, or old-commit pin.
- Follow-up root cause: `pkg.sources` excluded future `lazy.lua` scans but did not invalidate the already-existing live `pkg-cache.lua` containing the bad dadbod-grip package spec.

# nvim-insert-mode-freeze-fix Tasks

## Status

- Current phase: Wiki writeback complete; local runtime repair verified.
- Task owner: Codex
- Risk level: Low, with possible escalation if plugin dependency or lockfile changes are required.

## Checklist

- [x] Confirm task entry through Legion workflow.
- [x] Materialize stable task contract in `plan.md`.
- [x] Record design-lite direction in `docs/rfc.md`.
- [x] Open isolated git worktree from latest `origin/master`.
- [x] Reproduce or bracket the insert-mode freeze with timeout-bound Neovim checks.
- [x] Identify the local config or plugin trigger.
- [x] Apply minimal fix.
- [x] Verify insert-mode smoke path.
- [x] Record verification evidence in `docs/test-report.md`.
- [x] Run delivery review and write `docs/review-change.md`.
- [x] Write reviewer-facing walkthrough.
- [x] Update `.legion/wiki/**` if there is reusable knowledge.

## Out of Scope Checklist

- [ ] Broad plugin upgrades.
- [ ] Lockfile churn unrelated to the root cause.
- [ ] Completion or AI assistant redesign.
- [ ] Terminal emulator or shell changes.

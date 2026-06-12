# tabiew-parquet-auto-open Tasks

## Status

- Current phase: Git delivery in progress after explicit user request.
- Task owner: OpenCode
- Risk level: Low configuration change.
- Base ref: `origin/master`
- Branch: `legion/tabiew-parquet-auto-open-tabiew`
- Worktree: `.worktrees/tabiew-parquet-auto-open`

## Checklist

- [x] Enter Legion workflow and create task contract.
- [x] Create isolated Git worktree from latest `origin/master`.
- [x] Inspect existing Neovim autocmd structure.
- [x] Add Tabiew auto-open logic for Parquet extensions.
- [x] Verify Neovim config loads and autocmd registers.
- [x] Record verification in `docs/test-report.md`.
- [x] Run readiness review and record `docs/review-change.md`.
- [x] Write `docs/report-walkthrough.md` and PR body.
- [x] Update `.legion/wiki/**` if reusable knowledge applies.
- [ ] Commit, push, open PR, and follow repository lifecycle if remote access permits.

## Delivery Note

- The same code change was synchronized into the active main config so `~/.config/nvim` works immediately.
- Commit, push, and PR delivery were requested explicitly on 2026-06-12.

## Out of Scope Checklist

- [ ] Install system packages.
- [ ] Add data viewer plugins.
- [ ] Change unrelated plugin or lockfile state.
- [ ] Broaden file handling beyond Parquet aliases.

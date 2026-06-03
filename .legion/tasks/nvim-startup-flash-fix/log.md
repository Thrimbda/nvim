# nvim-startup-flash-fix Log

## 2026-06-03

- Entered Legion workflow because the repository is Legion-managed and the user explicitly requested Legion process.
- Created new task instead of restoring an existing one because no task id/path was provided.
- Confirmed symptom boundary with user: Neovim startup briefly blacks out the terminal, and acceptance is removing the visible flash without regressing existing behavior.
- Classified initial risk as low configuration work unless investigation reveals broader startup/UI coupling.
- Opened isolated worktree `.worktrees/nvim-startup-flash-fix` on branch `legion/nvim-startup-flash-fix-startup-flash` from base `origin/master` at `a3738dfc02b79340eeceee21d9d0355dce73cf31`.
- Found no explicit `clear` or redraw command in local startup config. The unavoidable `clear screen` entry comes from Neovim TUI initialization, so the fix targets reducing the blank interval before first UI readiness.
- Changed `copilot.vim` to explicit lazy loading on `InsertEnter` and `opencode.nvim` to explicit lazy loading on `VeryLazy`; both were previously pulled into startup because `defaults.lazy = false` applies to custom plugin specs.
- Verification passed for isolated worktree startup and lazy.nvim parsed state. `stylua` was unavailable in the environment. Manual visual confirmation remains terminal-dependent and is recorded in `docs/test-report.md`.
- Review found a command-availability regression risk for `copilot.vim`; added `cmd = "Copilot"` so `:Copilot` still lazy-loads before the first `InsertEnter`.
- Re-ran verification after the Copilot command trigger change. A test assertion type assumption was corrected; final isolated startup, lazy spec assertion, and startup log checks passed. `stylua` remains unavailable.
- Review-change verdict: PASS. No blocking findings, no scope creep, no security triggers. Residual UX check is manual because the exact flash is terminal-dependent.
- Wrote implementation-mode delivery artifacts: `docs/report-walkthrough.md` and `docs/pr-body.md`.
- Completed wiki writeback: added `wiki/tasks/nvim-startup-flash-fix.md`, linked it from `wiki/index.md`, and added a reusable LazyVim startup load reduction pattern.

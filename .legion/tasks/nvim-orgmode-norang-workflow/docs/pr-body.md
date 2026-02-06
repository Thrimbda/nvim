## What
Add a Norang-style orgmode workflow for Neovim, including custom agenda views and a punch in/out module to keep clocks running across tasks.
Document the setup and daily usage so the workflow is self-contained in the repo.

## Why
Provide a predictable daily flow that mirrors Norang's block agenda and continuous clocking style.
Reduce friction when switching tasks by falling back to a parent project or a default Organization task.

## How
Extend orgmode config with custom agenda commands and keymaps for agenda + punch actions.
Implement `org_punch` to locate the default task by `:ID:` and manage keep-running behavior with parent/default fallback.
Add documentation describing configuration, keymaps, and day-to-day usage.

## Testing
- Not run (no automated tests). See `/.legion/tasks/nvim-orgmode-norang-workflow/docs/test-report.md` for manual verification steps.

## Risk / Rollback
- Risk: low. Changes are confined to Neovim config and documentation.
- Rollback: remove org_punch setup/keymaps, delete `lua/org_punch.lua`, and remove the workflow doc.

## Links
- Task brief: `/.legion/tasks/nvim-orgmode-norang-workflow/docs/task-brief.md`
- RFC: none
- Review notes: `/.legion/tasks/nvim-orgmode-norang-workflow/docs/review-code.md`
- Walkthrough: `/.legion/tasks/nvim-orgmode-norang-workflow/docs/report-walkthrough.md`

# Walkthrough: Norang-style orgmode workflow (Neovim)

## Goal and Scope
- Goal: Implement a Norang-inspired orgmode workflow with custom agenda views and continuous clocking, plus repo-local documentation.
- Scope: `lua/plugins/orgmode.lua`, `lua/org_punch.lua`, `docs/orgmode-norang-workflow.md`.

## Design Summary
- RFC: none.
- Approach: extend orgmode config with custom agenda commands and add a small punch module that keeps clocks running by falling back to a parent project or a default task located by `:ID:`.

## Change List (by module/file)
- `lua/plugins/orgmode.lua`
  - Add Norang-style agenda commands: block agenda, NEXT list, REFILE inbox.
  - Wire org_punch setup with agenda file path, default task ID, and project TODO keywords.
  - Add keymaps for punch in/out, keep-running clock out, and agenda shortcuts.
- `lua/org_punch.lua`
  - Implement default task lookup by `:ID:` across agenda files.
  - Add punch in/out state and keep-running clock out behavior with parent/default fallback.
  - Preserve window/view when jumping across files and actions.
- `docs/orgmode-norang-workflow.md`
  - Document setup (default task ID), agenda commands, keymaps, and daily usage flow.

## How to Verify
Reference: `/.legion/tasks/nvim-orgmode-norang-workflow/docs/test-report.md`.

- Manual checks:
  - Open `:Org agenda b` and confirm the block agenda sections render.
  - Punch in (`<F9>i`) clocks into the default Organization task.
  - Clock a task, then use keep-running clock out (`<F9>O`) to fall back to parent/default.
  - Punch out (`<F9>o`) stops continuous clocking.
  - Confirm clock logs are stored in LOGBOOK drawers.

## Risks and Rollback
- Risk level: low. Changes are limited to Lua config and docs.
- Rollback: remove org_punch setup and keymaps from `lua/plugins/orgmode.lua` and delete `lua/org_punch.lua` plus the workflow doc.

## Open Items and Next Steps
- Non-blocking review suggestions noted in `/.legion/tasks/nvim-orgmode-norang-workflow/docs/review-code.md` (guarding missing clock actions, clarifying warnings) were not addressed in this change set.
- Next: consider adding user-facing notifications for missing mappings or inactive clocks per the review notes.

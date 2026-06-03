# Report Walkthrough

## Mode

Implementation.

## What Changed

- `lua/plugins/copilot.lua`: explicitly lazy-load `github/copilot.vim`, preserving `:Copilot` as a command trigger and loading suggestions on `InsertEnter`.
- `lua/plugins/opencode.lua`: explicitly lazy-load `nickjvandyke/opencode.nvim` on `VeryLazy`.

## Why

- The repository sets `defaults.lazy = false` for custom plugin specs, so custom plugins without explicit lazy conditions are pulled into the initial startup path.
- The startup flash cannot remove Neovim's built-in TUI `clear screen`, but reducing non-first-screen startup work should shorten the blank interval before the UI is ready.
- The change avoids dashboard/theme rewrites, plugin upgrades, and terminal-specific hacks.

## Verification Evidence

- `docs/test-report.md`: isolated worktree startup passed with `startup-ok`.
- `docs/test-report.md`: lazy.nvim spec assertion passed with `lazy-spec-ok`.
- `docs/startuptime-after.log`: contains one startup section and no `copilot` or `opencode` entries.
- `stylua` was unavailable in the environment; Neovim parsed the changed Lua specs successfully.

## Review Evidence

- `docs/review-change.md`: PASS.
- No blocking findings.
- No security triggers.
- Residual manual UX check is documented because terminal rendering cannot be fully proven headlessly.

## Residual Risk

- A terminal may still show the intrinsic Neovim alternate-screen clear. The expected improvement is a shorter or no longer noticeable blank interval caused by plugin startup load.

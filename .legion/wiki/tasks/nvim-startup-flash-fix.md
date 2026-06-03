# nvim-startup-flash-fix

## Metadata

- `task-id`: `nvim-startup-flash-fix`
- `status`: `active`
- `risk`: `low`
- `schema-version`: `2026-06-03`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

- This task reduces the noticeable black-screen flash on Neovim startup by removing non-first-screen plugins from the initial startup load path.
- The current effective fix is to explicitly mark `copilot.vim` and `opencode.nvim` as lazy, because this config sets `defaults.lazy = false` for custom lazy.nvim specs.
- `copilot.vim` loads on `InsertEnter` and still supports `:Copilot` command-triggered lazy loading.
- `opencode.nvim` loads on `VeryLazy`, keeping its setup out of the first startup path.
- Neovim's built-in TUI `clear screen` is still expected; the durable conclusion is to reduce plugin-caused blank interval rather than trying to remove the terminal alternate-screen clear.

## Reusable Decisions

- In this config, custom plugin specs that are not required for the first screen should use explicit `lazy = true` plus an appropriate trigger, because `defaults.lazy = false` otherwise makes them startup plugins.
- When delaying a command-providing plugin, preserve important user commands with `cmd = ...` so lazy loading does not regress command availability.
- Validate worktree copies of this Neovim config through isolated XDG config/cache paths; otherwise Neovim can accidentally load the main config or Lazy cache.

## Related Raw Sources

- `plan`: `.legion/tasks/nvim-startup-flash-fix/plan.md`
- `log`: `.legion/tasks/nvim-startup-flash-fix/log.md`
- `tasks`: `.legion/tasks/nvim-startup-flash-fix/tasks.md`
- `test-report`: `.legion/tasks/nvim-startup-flash-fix/docs/test-report.md`
- `review`: `.legion/tasks/nvim-startup-flash-fix/docs/review-change.md`
- `report`: `.legion/tasks/nvim-startup-flash-fix/docs/report-walkthrough.md`

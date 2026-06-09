# nvim-insert-mode-freeze-fix

## Metadata

- `task-id`: `nvim-insert-mode-freeze-fix`
- `status`: `active`
- `risk`: `low`
- `schema-version`: `2026-06-09`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

- The user reported Neovim freezing around insert mode and identified the staged `lazy-lock.json` update as the likely trigger.
- The durable repair was runtime synchronization: run `Lazy restore` against the active config and run the `blink.cmp` build task so installed plugin checkouts/build outputs match the staged lockfile.
- No Lua configuration patch was made because insert and typing checks passed after restore/build and the original freeze was not consistently reproducible under automation.
- Verification covered default buffer insert+typing, org buffer insert+typing, and a headless insert+typing assertion.

## Reusable Decisions

- When an issue appears after `lazy-lock.json` changes, first verify whether installed plugin checkouts and native build artifacts match the lockfile before changing Lua config.
- For insert-mode failures after LazyVim updates, inspect `InsertEnter` plugins first. In this config, key candidates are `blink.cmp` and `copilot.vim`; org buffers also require checking `orgmode`.
- Use `expect` for TUI insert smoke tests. Timer-only Neovim TUI scripts can produce false hangs; validate the harness against `nvim --clean` before trusting a hang result.
- Treat a non-reproducible post-restore fix as a runtime-state repair and document residual manual-verification risk.

## Related Raw Sources

- `plan`: `.legion/tasks/nvim-insert-mode-freeze-fix/plan.md`
- `log`: `.legion/tasks/nvim-insert-mode-freeze-fix/log.md`
- `tasks`: `.legion/tasks/nvim-insert-mode-freeze-fix/tasks.md`
- `design-lite`: `.legion/tasks/nvim-insert-mode-freeze-fix/docs/rfc.md`
- `test-report`: `.legion/tasks/nvim-insert-mode-freeze-fix/docs/test-report.md`
- `review`: `.legion/tasks/nvim-insert-mode-freeze-fix/docs/review-change.md`
- `report`: `.legion/tasks/nvim-insert-mode-freeze-fix/docs/report-walkthrough.md`

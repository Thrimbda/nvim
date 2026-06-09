# nvim-insert-mode-freeze-fix

## Metadata

- `task-id`: `nvim-insert-mode-freeze-fix`
- `status`: `complete`
- `risk`: `low`
- `schema-version`: `2026-06-09`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

- The user reported Neovim freezing around insert mode and identified the staged `lazy-lock.json` update as the likely trigger.
- The initial runtime synchronization was insufficient. The reopened investigation found macOS `SIGKILL (Code Signature Invalid)` / `CODESIGNING Invalid Page` reports for native Neovim artifacts.
- The durable source repair forces `blink.cmp` to use the Lua fuzzy matcher, pins `nvim-treesitter` to the lockfile commit, and signs parser/native artifacts after builds on macOS.
- The runtime repair re-signed the currently installed tree-sitter parsers, `orgmode` parser, and `blink.cmp` dylib.
- Verification covered blink config, markdown/org tree-sitter startup, TUI insert+typing, and absence of new crash reports after final smoke checks.

## Reusable Decisions

- When an issue appears after `lazy-lock.json` changes, first verify whether installed plugin checkouts and native build artifacts match the lockfile before changing Lua config.
- For insert-mode failures after LazyVim updates, inspect `InsertEnter` plugins first. In this config, key candidates are `blink.cmp` and `copilot.vim`; org buffers also require checking `orgmode`.
- Use `expect` for TUI insert smoke tests. Timer-only Neovim TUI scripts can produce false hangs; validate the harness against `nvim --clean` before trusting a hang result.
- On macOS, inspect `~/Library/Logs/DiagnosticReports/nvim-*.ips` for `Code Signature Invalid` before assuming a Lua exception or plugin hang.
- Re-sign local tree-sitter parser `.so` and native plugin dylibs after parser/build updates when DiagnosticReports show `CODESIGNING Invalid Page`.

## Related Raw Sources

- `plan`: `.legion/tasks/nvim-insert-mode-freeze-fix/plan.md`
- `log`: `.legion/tasks/nvim-insert-mode-freeze-fix/log.md`
- `tasks`: `.legion/tasks/nvim-insert-mode-freeze-fix/tasks.md`
- `design-lite`: `.legion/tasks/nvim-insert-mode-freeze-fix/docs/rfc.md`
- `test-report`: `.legion/tasks/nvim-insert-mode-freeze-fix/docs/test-report.md`
- `review`: `.legion/tasks/nvim-insert-mode-freeze-fix/docs/review-change.md`
- `report`: `.legion/tasks/nvim-insert-mode-freeze-fix/docs/report-walkthrough.md`

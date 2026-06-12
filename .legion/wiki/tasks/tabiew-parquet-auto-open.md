# tabiew-parquet-auto-open

## Metadata

- `task-id`: `tabiew-parquet-auto-open`
- `status`: `completed`
- `risk`: `low`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

- Parquet-like files now have an early Neovim file handler that can open Tabiew through `tw <absolute-path>`.
- The handler covers `.parquet`, `.pqt`, and `.parq`.
- The handler is required from `init.lua` before `config.lazy` because LazyVim's normal `lua/config/autocmds.lua` file loads on `VeryLazy`, too late for `nvim data.parquet`.
- If `tw` is missing, Neovim shows a non-modifiable install hint instead of a raw binary buffer or silent failure.

## Reusable Decisions

- Startup-critical `BufReadCmd` handlers must be registered before LazyVim's `VeryLazy` autocmd loader.
- External TUI viewers should be treated as runtime dependencies; Neovim config should detect missing CLIs and provide guidance, not install them.
- Verification for file-open handlers should include the direct startup path, not only post-startup `:edit` behavior.

## Related Raw Sources

- `plan`: `.legion/tasks/tabiew-parquet-auto-open/plan.md`
- `log`: `.legion/tasks/tabiew-parquet-auto-open/log.md`
- `tasks`: `.legion/tasks/tabiew-parquet-auto-open/tasks.md`
- `test-report`: `.legion/tasks/tabiew-parquet-auto-open/docs/test-report.md`
- `review`: `.legion/tasks/tabiew-parquet-auto-open/docs/review-change.md`
- `report`: `.legion/tasks/tabiew-parquet-auto-open/docs/report-walkthrough.md`

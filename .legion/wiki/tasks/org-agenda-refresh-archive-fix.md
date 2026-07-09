# org-agenda-refresh-archive-fix

## Metadata

- `task-id`: `org-agenda-refresh-archive-fix`
- `status`: `completed`
- `risk`: `low`
- `schema-version`: `2026-07-09`
- `historical`: `false`
- `supersedes`: `org-agenda-archive-parity-fix` done keyword coverage only
- `superseded-by`: `(none)`

## Outcome Summary

- 修复 PR #12 后 archive section 仍少于 Emacs baseline 的问题：`PHONE` / `MEETING` capture keywords 现在和 `DONE/CANCELLED` 一起作为 done-state keyword 参与 `ARCHIVE_CANDIDATE`。
- 当前有效结论：Norang archive parity 不只依赖 matcher 和月份规则，还要求 orgmode `org_todo_keywords`、org_legion `todo.done` 与 capture templates 的完成态 keyword 集合一致。
- 修复 agenda 打开前 refresh 失败时的双 warning：agenda wrapper 使用 `refresh_all({ notify = false })`，失败时只发一条带文件路径、`error.code` 和 `error.message` 的 warning。
- `OrgLegionRefresh` 手动命令仍保留 summary notify，并在失败时追加同一套 failure details。
- 验证与 review 均 PASS；render handoff 采用 artifact/local-only，因为仓库暂无 PR HTML preview 基建。

## Reusable Decisions

- Norang-style done-state parity must include capture-specific completion keywords such as `PHONE` and `MEETING`, not only `DONE` / `CANCELLED`.
- Keep orgmode `org_todo_keywords`, org_legion `todo.done`, archive tests, and capture templates synchronized when adding done-state keywords.
- Agenda wrappers that call `org_legion.refresh_all()` before opening a view should pass `{ notify = false }` and emit one contextual warning with failure details if the refresh summary has failures.
- Refresh failure summaries should expose file path plus `error.code/message`, not org file contents.

## Related Raw Sources

- `plan`: `.legion/tasks/org-agenda-refresh-archive-fix/plan.md`
- `log`: `.legion/tasks/org-agenda-refresh-archive-fix/log.md`
- `tasks`: `.legion/tasks/org-agenda-refresh-archive-fix/tasks.md`
- `rfc`: `.legion/tasks/org-agenda-refresh-archive-fix/docs/rfc.md`
- `test-report`: `.legion/tasks/org-agenda-refresh-archive-fix/docs/test-report.md`
- `review-change`: `.legion/tasks/org-agenda-refresh-archive-fix/docs/review-change.md`
- `report`: `.legion/tasks/org-agenda-refresh-archive-fix/docs/report-walkthrough.md`
- `render-handoff`: `.legion/tasks/org-agenda-refresh-archive-fix/docs/render-handoff.md`

## Notes

- 本任务补齐 PR #12 的 keyword coverage；PR #12 的 `-REFILE/` matcher 和月份窗口结论仍然有效。

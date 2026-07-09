# org-agenda-archive-parity-fix

## Metadata

- `task-id`: `org-agenda-archive-parity-fix`
- `status`: `completed`
- `risk`: `low`
- `schema-version`: `2026-07-09`
- `historical`: `false`
- `supersedes`: `org-agenda-norang-parity-fix` archive candidate behavior only
- `superseded-by`: `(none)`

## Outcome Summary

- 修复 PR #11 后 `Tasks to Archive` 仍不符合 Norang baseline 的问题。
- 当前有效结论：archive candidate 不是 day-count stale 规则，而是 done-state todo 子树中没有本月或上月 `YYYY-MM-` 时间戳。
- `b` agenda 的 archive section 应使用 `-REFILE/` 作为用户可见 matcher，由 org_legion virtual search adapter 内部叠加 `ARCHIVE_CANDIDATE` 过滤。
- `ARCHIVE_CANDIDATE` 仍是内部虚拟标签，不应写回 org 文本；旧物化标签由 cleanup 显式清理。

## Reusable Decisions

- Norang archive parity must model `bh/skip-non-archivable-tasks`, not an approximate stale-days cutoff.
- Exact `-REFILE/` queries in this config are treated as the Norang archive agenda query while org_legion is enabled.
- Tests for archive parity must include current-month, last-month, old DONE, open TODO, and REFILE DONE examples.

## Related Raw Sources

- `plan`: `.legion/tasks/org-agenda-archive-parity-fix/plan.md`
- `log`: `.legion/tasks/org-agenda-archive-parity-fix/log.md`
- `tasks`: `.legion/tasks/org-agenda-archive-parity-fix/tasks.md`
- `rfc`: `.legion/tasks/org-agenda-archive-parity-fix/docs/rfc.md`
- `test-report`: `.legion/tasks/org-agenda-archive-parity-fix/docs/test-report.md`
- `review`: `.legion/tasks/org-agenda-archive-parity-fix/docs/review-change.md`
- `report`: `.legion/tasks/org-agenda-archive-parity-fix/docs/report-walkthrough.md`

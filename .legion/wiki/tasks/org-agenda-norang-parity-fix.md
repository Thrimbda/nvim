# org-agenda-norang-parity-fix

## Metadata

- `task-id`: `org-agenda-norang-parity-fix`
- `status`: `completed`
- `risk`: `low`
- `schema-version`: `2026-07-09`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

- 修复 `:Org agenda b` 与 Emacs 原生 Norang block agenda baseline 的顺序、标题和任务分类差异。
- 当前有效结论是：Norang-style block agenda 使用 day agenda、Tasks to Refile、Stuck Projects、Projects、Project Next Tasks、Project Subtasks、Standalone Tasks、Waiting and Postponed Tasks、Tasks to Archive 的顺序。
- 新增 `PROJECT_TASK` 虚拟标签，用于标记项目内 active 子任务；`PROJECT/STUCK/PROJECT_TASK/ARCHIVE_CANDIDATE` 通过 agenda/search 时的内存索引注入，不写回 org 文本。
- 相关 agenda 快捷键在打开前执行 `org_legion.refresh_all()`，降低未刷新虚拟索引导致的分类漂移。
- 验证与 review 均 PASS；render handoff 采用 artifact-only/local，因为仓库暂无 PR HTML preview 基建。

## Reusable Decisions

- 用虚拟标签近似 Emacs org-agenda skip functions 时，不要只依赖 inherited `PROJECT`；需要把 project parent 与 project child context 拆成不同查询标签。
- 对依赖虚拟标签的 agenda view，在打开前刷新内存索引，避免旧 org 文件状态让 view 分类漂移。
- PR walkthrough HTML 若仓库没有现成 Pages preview，且当前任务不属于基础设施范围，应记录 artifact-only/local render handoff，而不是顺手引入 CI/Pages workflow。

## Related Raw Sources

- `plan`: `.legion/tasks/org-agenda-norang-parity-fix/plan.md`
- `log`: `.legion/tasks/org-agenda-norang-parity-fix/log.md`
- `tasks`: `.legion/tasks/org-agenda-norang-parity-fix/tasks.md`
- `rfc`: `.legion/tasks/org-agenda-norang-parity-fix/docs/rfc.md`
- `test-report`: `.legion/tasks/org-agenda-norang-parity-fix/docs/test-report.md`
- `review-change`: `.legion/tasks/org-agenda-norang-parity-fix/docs/review-change.md`
- `report`: `.legion/tasks/org-agenda-norang-parity-fix/docs/report-walkthrough.md`
- `render-handoff`: `.legion/tasks/org-agenda-norang-parity-fix/docs/render-handoff.md`

## Notes

- 若后续要完全复刻 Emacs skip-function 行为，仍应单独建 task；本任务是 orgmode.nvim matcher 与虚拟 agenda 标签边界内的低风险修复。

# org-refile-fuzzy-prompt

## Metadata

- `task-id`: `org-refile-fuzzy-prompt`
- `status`: `active`
- `risk`: `low`
- `schema-version`: `2026-07-09`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

- 本任务修复 orgmode refile destination 只有 Snacks 单行输入框、没有可见 fuzzy 候选的问题。
- 当前有效实现是删除 `lua/plugins/orgmode.lua` 中 `ui.input.use_vim_ui = true` 覆盖，让 refile 回到 orgmode.nvim 默认 input completion。
- orgmode.nvim 本地默认 `ui.input.use_vim_ui = false`，并且 `Capture:autocomplete_refile()` 可通过 fuzzy 输入返回候选目标。
- 不新增 Telescope/Snacks picker，不改 refile 移动语义，也不改 agenda、capture、punch、clock 或 TODO 行为。
- 当前实现、验证、review、walkthrough 和 wiki writeback 已完成；PR lifecycle 尚未完成，所以 summary 状态保持 `active`。

## Reusable Decisions

- 对 orgmode.nvim refile destination 输入，优先保留 orgmode 原生 input completion；不要为了浮窗外观把 refile 强制切到 `vim.ui.input`，除非同时验证候选列表可见性。
- 如果需要更完整的 picker 体验，应作为单独设计任务处理，避免复制上游 destination 解析与 refile 移动语义。
- 验证 worktree 内 Neovim 配置时，不要只跑 `nvim -u <worktree>/init.lua`；runtimepath 可能仍解析到主配置。应使用 spec-level 断言或隔离 XDG 路径。

## Related Raw Sources

- `plan`: `.legion/tasks/org-refile-fuzzy-prompt/plan.md`
- `log`: `.legion/tasks/org-refile-fuzzy-prompt/log.md`
- `tasks`: `.legion/tasks/org-refile-fuzzy-prompt/tasks.md`
- `rfc`: `.legion/tasks/org-refile-fuzzy-prompt/docs/rfc.md`
- `test-report`: `.legion/tasks/org-refile-fuzzy-prompt/docs/test-report.md`
- `review`: `.legion/tasks/org-refile-fuzzy-prompt/docs/review-change.md`
- `render-handoff`: `.legion/tasks/org-refile-fuzzy-prompt/docs/render-handoff.md`
- `report`: `.legion/tasks/org-refile-fuzzy-prompt/docs/report-walkthrough.md`

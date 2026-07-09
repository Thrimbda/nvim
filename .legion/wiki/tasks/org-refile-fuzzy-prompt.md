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

- 本任务修复 orgmode refile destination 只有单行 input、没有可见 fuzzy 候选列表的问题。
- 初版“删除 `ui.input.use_vim_ui = true` 并回到 orgmode 原生 input completion”的结论已被用户重启验证为不足；它只提供 completion function，不保证显示候选 picker。
- 当前有效实现是新增 `lua/org_refile_picker.lua`，patch `orgmode.capture.get_destination()` 使用 `vim.ui.select` 展示 file + unfinished headline destination。
- Snacks picker 默认接管 `vim.ui.select`，因此 refile destination 会打开可见候选列表，并通过输入文本 fuzzy 过滤。
- 实现仍返回 orgmode 原有移动逻辑需要的 `{ file, headline? }` 或取消时 `false`，不改 agenda、capture、punch、clock 或 TODO 行为。
- 当前实现、验证、review、walkthrough 和 wiki writeback 已完成；PR lifecycle 尚未完成，所以 summary 状态保持 `active`。

## Reusable Decisions

- 对 orgmode.nvim refile destination，原生 `Input.open(... autocomplete_refile ...)` 不等价于可见 fuzzy picker；若验收要求图一式候选列表，应使用 `vim.ui.select` / picker 入口并验证 candidate visibility。
- 不要把 refile 强制切到 `vim.ui.input` 作为 UX 修复；在本配置中这会产生单输入框而没有预期候选列表。
- 自定义 picker 应复用 orgmode 的 `_get_autocompletion_files()` 与 headline objects，并返回 `{ file, headline? }`，避免重写 refile 移动语义。
- 验证 worktree 内 Neovim 配置时，不要只跑 `nvim -u <worktree>/init.lua`；runtimepath 可能仍解析到主配置。应使用 spec-level 断言或隔离 XDG 路径。

## Related Raw Sources

- `plan`: `.legion/tasks/org-refile-fuzzy-prompt/plan.md`
- `log`: `.legion/tasks/org-refile-fuzzy-prompt/log.md`
- `tasks`: `.legion/tasks/org-refile-fuzzy-prompt/tasks.md`
- `rfc`: `.legion/tasks/org-refile-fuzzy-prompt/docs/rfc.md`
- `review-rfc`: `.legion/tasks/org-refile-fuzzy-prompt/docs/review-rfc.md`
- `test-report`: `.legion/tasks/org-refile-fuzzy-prompt/docs/test-report.md`
- `review-change`: `.legion/tasks/org-refile-fuzzy-prompt/docs/review-change.md`
- `render-handoff`: `.legion/tasks/org-refile-fuzzy-prompt/docs/render-handoff.md`
- `report`: `.legion/tasks/org-refile-fuzzy-prompt/docs/report-walkthrough.md`

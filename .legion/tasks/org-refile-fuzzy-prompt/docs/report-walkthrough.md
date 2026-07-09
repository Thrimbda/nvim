# Report Walkthrough

## Profile

implementation

## Reviewer Summary

- 本任务修复 orgmode refile 目标选择只有 Snacks 单行输入框、没有可见 fuzzy 候选的问题。
- 实现采用最小改动：删除 `lua/plugins/orgmode.lua` 中 `ui.input.use_vim_ui = true` 覆盖，让 orgmode 回到默认 input completion 路径。
- 文档同步更新为 orgmode 原生 refile completion，不再声称 Snacks input 提供候选。
- `verify-change` 与 `review-change` 均为 PASS。
- PR lifecycle 尚未完成：PR 未创建，checks/review/merge、auto-merge、cleanup 和主工作区 refresh 仍待 git-worktree-pr 后续阶段处理。
- Render handoff 为 artifact-only / local render：仓库无现成 HTML preview workflow，新增 Pages preview 超出本任务 scope。

## Scope

In scope:

- `lua/plugins/orgmode.lua`
- `skills/legion-workflow/references/orgmode-legion-workflow.md`
- `.legion/tasks/org-refile-fuzzy-prompt/**`

Out of scope:

- 重写 orgmode.nvim refile 实现。
- 新增 Telescope/Snacks picker refile。
- 改 agenda、capture、punch、clock 或 TODO 行为。
- 处理 `blink.cmp` native fuzzy 或 treesitter 稳定性历史问题。

## Evidence Map

| Claim | Evidence | Status |
|---|---|---|
| 任务 contract 稳定且低风险 | `plan.md`, `docs/rfc.md` | PASS |
| orgmode 不再强制走 `vim.ui.input` | `lua/plugins/orgmode.lua`, `docs/test-report.md` | PASS |
| refile fuzzy 候选函数可用 | `docs/test-report.md` 的 `Capture.autocomplete_refile("ntl")` 断言 | PASS |
| capture/punch/agenda 相关行为未见回归 | `docs/test-report.md` 的完整 smoke suite | PASS |
| 变更符合 scope 且无 blocking finding | `docs/review-change.md` | PASS |

## What Changed / What Was Decided

删除本仓库对 orgmode 输入 UI 的覆盖：

```lua
ui = {
  input = {
    use_vim_ui = true,
  },
},
```

这样 refile destination prompt 回到 orgmode.nvim 默认路径，并继续使用上游已有的 `Capture:get_destination()` 和 `Capture:autocomplete_refile()`。

## Verification / Review Status

- `rg` 断言 `use_vim_ui = true` 覆盖已消失。
- orgmode 默认值断言输出 `orgmode_default_use_vim_ui false`。
- worktree spec-level 断言输出 `worktree_spec_ui nil`。
- `Capture.autocomplete_refile("ntl")` 返回 `/org/ntnl.org/`。
- `ALLOW_UNPINNED_ORGMODE=1 bash tests/smoke/run.sh` exit 0，20 个 smoke case 全部通过。
- `docs/review-change.md` 结论为 PASS，无 blocking findings。

## Risks and Limits

- 未做交互式像素截图验证；当前证据覆盖配置路径、上游 fuzzy function 和 smoke 行为。
- smoke 使用 unpinned 本地 orgmode runtime，因为仓库没有 `.tests/deps/orgmode`。
- 真实 TUI 候选弹窗仍取决于 Neovim 原生 input completion 设置，但本任务已恢复 orgmode 默认能力。

## Reviewer Checklist

- [ ] 变更是否保持在 refile input UI scope 内？
- [ ] 是否接受恢复 orgmode 原生 input completion，而不是新增 picker？
- [ ] 验证证据是否足以替代交互式截图？
- [ ] 文档是否清楚暴露了 smoke 的 unpinned runtime 限制？

## Next Stage

`docs/report-walkthrough.html` 已交给 `pr-html-render` 判定为 artifact-only / local render；之后进入 `legion-wiki` 写回。`docs/pr-body.md` 仅作为 PR 创建/更新输入，不代表 PR lifecycle 已完成。

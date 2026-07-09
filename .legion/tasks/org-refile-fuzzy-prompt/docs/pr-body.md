# Implementation Review: org-refile-fuzzy-prompt

> 本 PR body 只是 PR 创建/更新输入，不代表 checks/review/merge、auto-merge、worktree cleanup 或主工作区 refresh 已完成。

## 交付摘要

- 修复 orgmode refile destination 只有 Snacks 单行输入框、没有可见 fuzzy 候选的问题。
- 删除 `lua/plugins/orgmode.lua` 中 `ui.input.use_vim_ui = true` 覆盖，恢复 orgmode 默认 input completion。
- 更新 Legion orgmode workflow 说明，避免继续声称 Snacks input 提供 refile 候选。

## 范围

**In scope**

- `lua/plugins/orgmode.lua`
- `skills/legion-workflow/references/orgmode-legion-workflow.md`
- `.legion/tasks/org-refile-fuzzy-prompt/**`

**Out of scope**

- 不重写 orgmode.nvim refile。
- 不新增 Telescope/Snacks picker refile。
- 不改变 agenda/capture/punch/clock/TODO 行为。

## 主要改动

- 移除 orgmode setup 中的 `ui.input.use_vim_ui = true`。
- 将 refile 输入说明改为 orgmode 原生 input completion，可通过输入文本 fuzzy 过滤候选目标。
- 增加 task contract、design-lite、验证报告、审查报告和 walkthrough。

## 验证与审查

- 验证: `.legion/tasks/org-refile-fuzzy-prompt/docs/test-report.md`
- 变更审查: `.legion/tasks/org-refile-fuzzy-prompt/docs/review-change.md`
- 设计一致性: `.legion/tasks/org-refile-fuzzy-prompt/docs/rfc.md`

验证摘要：

- `rg` 确认 `use_vim_ui = true` 覆盖已消失。
- orgmode 默认值为 `use_vim_ui=false`。
- worktree spec-level 断言确认传给 `orgmode.setup()` 的配置不再包含 `ui.input`。
- `Capture.autocomplete_refile("ntl")` 返回 `/org/ntnl.org/`。
- `ALLOW_UNPINNED_ORGMODE=1 bash tests/smoke/run.sh` exit 0，20 个 smoke case 全部通过。
- `review-change` 为 PASS，无 blocking findings。

## 风险与限制

- 未做交互式像素截图验证，当前通过配置路径、上游 fuzzy function 和 smoke suite 证明核心语义。
- smoke 使用 unpinned 本地 orgmode runtime，因为仓库没有 `.tests/deps/orgmode`。
- 真实候选弹窗外观仍取决于 Neovim 原生 input completion 设置。

## 评审重点

- [ ] 变更是否符合 task contract 与 scope？
- [ ] 恢复 orgmode 原生 input completion 是否是可接受的最小方案？
- [ ] 验证证据是否足以支撑交付结论？
- [ ] 风险、限制与 non-goals 是否已经清楚暴露？

## 证据链接

- plan: `.legion/tasks/org-refile-fuzzy-prompt/plan.md`
- design-lite: `.legion/tasks/org-refile-fuzzy-prompt/docs/rfc.md`
- test-report: `.legion/tasks/org-refile-fuzzy-prompt/docs/test-report.md`
- review-change: `.legion/tasks/org-refile-fuzzy-prompt/docs/review-change.md`
- report-walkthrough: `.legion/tasks/org-refile-fuzzy-prompt/docs/report-walkthrough.html`
- render-handoff: `.legion/tasks/org-refile-fuzzy-prompt/docs/render-handoff.md`

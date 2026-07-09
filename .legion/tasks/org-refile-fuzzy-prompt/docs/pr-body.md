# Implementation Review

> 本 PR body 只是 PR 创建/更新输入，不代表 checks/review/merge、auto-merge、worktree cleanup 或主工作区 refresh 已完成。

## 交付摘要

- 修复 orgmode refile 仍显示单行 input 的问题：新增 `org_refile_picker`，把 destination 选择切到 `vim.ui.select`，由 Snacks picker 展示可见候选并 fuzzy 过滤。
- 候选包含 agenda 文件 root 与未完成 headline destination。
- 选择结果仍返回 orgmode 原有移动逻辑需要的 `{ file, headline? }`，取消返回 `false`。

## 范围

**In scope**

- `lua/org_refile_picker.lua`
- `lua/plugins/orgmode.lua`
- orgmode smoke tests 与 smoke runner isolation
- Legion task docs、workflow reference、walkthrough、wiki writeback

**Out of scope**

- 不改 orgmode.nvim refile 移动语义。
- 不改 agenda/capture template、TODO keyword、clock 或 punch 行为。
- 不新增 HTML preview workflow。

## 主要改动

- 新增 `org_refile_picker.build_items()`，从 orgmode destination files 生成 file + headline 候选。
- patch `orgmode.capture.get_destination()`，通过 `vim.ui.select` 打开 picker，选择后 resolve `{ file, headline? }`，取消时 resolve `false`。
- 在 orgmode plugin setup 中启用 picker patch。
- 新增 smoke case 验证候选构建、headline destination 选择和取消行为。
- 调整 smoke runner 让 worktree root 优先于主配置 root，避免测试加载旧模块。

## 验证与审查

- 验证: `docs/test-report.md`
- RFC: `docs/rfc.md`
- RFC review: `docs/review-rfc.md`
- 变更审查: `docs/review-change.md`
- Walkthrough: `docs/report-walkthrough.md` / `docs/report-walkthrough.html`

验证结果：

- `refile_picker_builds_file_and_headline_candidates`: PASS
- `refile_picker_selects_and_cancels_destination`: PASS
- worktree spec-level patch 断言：PASS，输出 `picker_patched true`
- `ALLOW_UNPINNED_ORGMODE=1 bash tests/smoke/run.sh`: PASS，22 个 case 全部通过
- `git diff --check`: PASS
- `stylua --check ...`: 当前机器没有 `stylua`

## 风险与限制

- headless 环境未做真实 TUI 截图；验证证明 refile 入口会调用 `vim.ui.select`，视觉由 Snacks picker 接管。
- patch 依赖 orgmode.nvim 内部 `_get_autocompletion_files()` 和 headline API；实现保留 fallback，并用 smoke case 覆盖当前 shape。

## 评审重点

- [ ] destination 选择是否真的从 input 切到 `vim.ui.select`。
- [ ] `{ file, headline? }` 和 `false` 的 return shape 是否与 orgmode 原 refile 流程兼容。
- [ ] fallback 与 smoke runner 调整是否合理。
- [ ] 风险、限制和 non-goals 是否清楚。

## 证据链接

- plan: `.legion/tasks/org-refile-fuzzy-prompt/plan.md`
- rfc: `.legion/tasks/org-refile-fuzzy-prompt/docs/rfc.md`
- review-rfc: `.legion/tasks/org-refile-fuzzy-prompt/docs/review-rfc.md`
- test-report: `.legion/tasks/org-refile-fuzzy-prompt/docs/test-report.md`
- review-change: `.legion/tasks/org-refile-fuzzy-prompt/docs/review-change.md`
- report-walkthrough: `.legion/tasks/org-refile-fuzzy-prompt/docs/report-walkthrough.html`

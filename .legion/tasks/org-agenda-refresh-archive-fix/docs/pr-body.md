# Implementation Review

> 本 PR body 只是 PR 创建/更新输入，不代表 checks/review/merge、auto-merge、worktree cleanup 或主工作区 refresh 已完成。

## 交付摘要

- 修复 Norang-style agenda 的 `Tasks to Archive` 漏项：`PHONE` / `MEETING` 现在和 Emacs baseline 一样作为 done-state keyword 参与 archive candidate。
- 修复 agenda 打开前 `org_legion refresh` 双 warning：agenda wrapper 静默调用 refresh，并在失败时只发一条带失败文件和错误摘要的 warning。
- 手动 `:OrgLegionRefresh` 仍显示 refresh summary，并在失败时附带文件级诊断。

## 范围

**In scope**

- `lua/plugins/orgmode.lua`
- `lua/org_legion/init.lua`
- `lua/org_legion/todo_triggers.lua`
- smoke tests 与当前 Legion task docs

**Out of scope**

- 不修改真实 org 文件内容。
- 不重做 agenda renderer。
- 不处理外部同步或 OneDrive 文件系统问题本身。

## 主要改动

- `org_todo_keywords` 和 `org_legion.todo.done` 增加 `PHONE` / `MEETING`。
- 新增 `format_refresh_failures()` / `format_refresh_summary()`，输出失败文件、`error.code` 和 `error.message`。
- agenda wrapper 使用 `refresh_all({ notify = false })`，避免 `refresh_all()` 和 wrapper 各报一次。
- `todo_triggers` 让 `PHONE/MEETING` 清理 `WAITING/HOLD/CANCELLED` stale tags。
- 新增 smoke coverage：archive `PHONE/MEETING`、failure warning details、manual refresh formatter、trigger cleanup。

## 验证与审查

- 验证: `.legion/tasks/org-agenda-refresh-archive-fix/docs/test-report.md`
- 变更审查: `.legion/tasks/org-agenda-refresh-archive-fix/docs/review-change.md`
- 设计记录: `.legion/tasks/org-agenda-refresh-archive-fix/docs/rfc.md`
- Walkthrough: `.legion/tasks/org-agenda-refresh-archive-fix/docs/report-walkthrough.html`

验证摘要：

- Targeted smoke: PASS
- Full smoke: PASS, `All smoke cases passed.`
- `git diff --check`: PASS
- 真实 agenda refresh: `org_legion refresh: total=22 ok=22 fail=0 skipped_conflict=0 skipped_unloaded=0`
- `stylua`: 本机未安装，未运行

## 风险与限制

- smoke 使用现有 opt-in unpinned orgmode fallback：`/Users/c1/.local/share/nvim/lazy/orgmode`。
- 若后续交互态 loaded buffer 仍有 refresh failure，新的 warning 会定位失败文件和错误摘要，但不会自动修复 org 文件内容。

## 评审重点

- [ ] `PHONE/MEETING` 作为 done-state keyword 是否符合 Emacs/Norang baseline。
- [ ] agenda pre-refresh failure 是否只产生一条 warning。
- [ ] failure formatter 是否足够定位问题且没有输出文件正文。
- [ ] 新增 smoke 是否覆盖用户截图中的 archive 缺项。

## 证据链接

- plan: `.legion/tasks/org-agenda-refresh-archive-fix/plan.md`
- rfc: `.legion/tasks/org-agenda-refresh-archive-fix/docs/rfc.md`
- test-report: `.legion/tasks/org-agenda-refresh-archive-fix/docs/test-report.md`
- review-change: `.legion/tasks/org-agenda-refresh-archive-fix/docs/review-change.md`
- report-walkthrough: `.legion/tasks/org-agenda-refresh-archive-fix/docs/report-walkthrough.html`

# Implementation Review

> 本 PR body 只是 PR 创建或更新输入，不代表 checks/review/merge、auto-merge、worktree cleanup 或主工作区 refresh 已完成。

## 交付摘要

- 修复 `:Org agenda b` 与 Emacs 原生 Norang block agenda baseline 的 section 顺序、标题和任务分类差异。
- 新增 `PROJECT_TASK` 虚拟标签，把项目父节点和项目内子任务拆开。
- 把 `PROJECT/STUCK/PROJECT_TASK/ARCHIVE_CANDIDATE` 从写回 org 文件的派生标签改成 agenda/search 时的内存分类；cleanup 仅保留为旧物化标签迁移工具。
- 打开依赖虚拟标签的 agenda 快捷键前刷新 `org_legion` 内存索引，避免分类漂移。

## 范围

**In scope**

- `lua/plugins/orgmode.lua`
- `lua/org_legion/**`
- `lua/tests/smoke/orgmode_smoke.lua`
- `tests/smoke/run.sh`
- `skills/legion-workflow/**`
- `.legion/tasks/org-agenda-norang-parity-fix/**`

**Out of scope**

- 不修改用户私有 org 文件。
- 不重做 clock、capture、refile picker、punch 状态机。
- 不更新 orgmode.nvim pin 或引入新依赖。

## 主要改动

- `b` block agenda 顺序调整为 Norang baseline：day agenda、Tasks to Refile、Stuck Projects、Projects、Project Next Tasks、Project Subtasks、Standalone Tasks、Waiting and Postponed Tasks、Tasks to Archive。
- 新增 `org_legion.virtual_tags`，安装 `OrgFile.apply_search` adapter，仅在查询包含虚拟标签时临时注入 `PROJECT/STUCK/PROJECT_TASK/ARCHIVE_CANDIDATE`。
- 新增 `PROJECT_TASK` 虚拟标签，并把 `PROJECT/STUCK/PROJECT_TASK/ARCHIVE_CANDIDATE` 排除出 tag inheritance。
- `<F12>`、`<Leader>oab`、`<Leader>oan`、`<Leader>oas` 打开 agenda 前会先运行 `org_legion.refresh_all()`。
- 新增 smoke 覆盖 custom command 结构、虚拟标签 refresh/search、refresh 不改写 org 文本，以及 full smoke 回归。

## 验证与审查

- 验证: `.legion/tasks/org-agenda-norang-parity-fix/docs/test-report.md`
- 变更审查: `.legion/tasks/org-agenda-norang-parity-fix/docs/review-change.md`
- 设计一致性: `.legion/tasks/org-agenda-norang-parity-fix/docs/rfc.md`

## 风险与限制

- `stylua` 在当前环境不可用，已记录为 skipped。
- Full smoke 使用本机 unpinned orgmode runtime fallback。
- 空 section 的显示仍受 orgmode.nvim agenda renderer 行为影响。

## 评审重点

- [ ] agenda order/header/matcher 是否符合 baseline？
- [ ] `PROJECT_TASK` 虚拟分类是否正确降低 project 父子串区风险？
- [ ] refresh 不再写回 org 文件是否符合预期迁移路线？
- [ ] 打开 agenda 前自动 refresh 的副作用是否可接受？
- [ ] 验证证据是否足够覆盖本次分类修复？

## 证据链接

- plan: `.legion/tasks/org-agenda-norang-parity-fix/plan.md`
- design-lite: `.legion/tasks/org-agenda-norang-parity-fix/docs/rfc.md`
- test-report: `.legion/tasks/org-agenda-norang-parity-fix/docs/test-report.md`
- review-change: `.legion/tasks/org-agenda-norang-parity-fix/docs/review-change.md`
- report-walkthrough: `.legion/tasks/org-agenda-norang-parity-fix/docs/report-walkthrough.html`

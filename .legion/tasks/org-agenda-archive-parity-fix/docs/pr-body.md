# Implementation Review

本 PR body 只是 PR 创建/更新输入，不代表 checks/review/merge、auto-merge、worktree cleanup 或主工作区 refresh 已完成。

## 交付摘要

- 修复 PR #11 后 `Tasks to Archive` 仍不符合 Norang baseline 的问题。
- Archive candidate 现在按 Norang 规则判定：done-state todo 子树里有本月或上月时间戳时跳过。
- `b` agenda 的 archive block 改为 `-REFILE/`，由虚拟搜索 adapter 内部叠加 archive candidate 过滤。

## 范围

**In scope**

- `lua/org_legion/rules.lua`
- `lua/org_legion/virtual_tags.lua`
- `lua/plugins/orgmode.lua`
- `lua/tests/smoke/orgmode_smoke.lua`
- `tests/smoke/run.sh`

**Out of scope**

- 其他 agenda section。
- 批量 archive 操作。
- 自动删除用户 org 文件里的历史物化 `ARCHIVE_CANDIDATE` 标签。

## 主要改动

- 将 archive 判定从 day-count stale 近似改为本月/上月 `YYYY-MM-` 前缀扫描。
- 让 `-REFILE/` 精确查询走 org_legion virtual search adapter，并过滤到内部 `ARCHIVE_CANDIDATE`。
- 新增 `legion_archive_candidates_match_norang_month_boundary` smoke case，并加入 runner。

## 验证与审查

- 验证: `.legion/tasks/org-agenda-archive-parity-fix/docs/test-report.md`
- 变更审查: `.legion/tasks/org-agenda-archive-parity-fix/docs/review-change.md`
- 设计记录: `.legion/tasks/org-agenda-archive-parity-fix/docs/rfc.md`

## 风险与限制

- `-REFILE/` 在 org_legion adapter 中被解释为 Norang archive 查询。这个绑定是精确匹配，避免影响其它包含 `REFILE` 的常规查询。
- 若 org 文件中已经存在真实 `ARCHIVE_CANDIDATE` 标签，cleanup 仍需用户显式执行；本 PR 保证 agenda archive 不再依赖或新增该物化标签。

## 评审重点

- [ ] 变更是否符合 Norang `tags "-REFILE/"` 加 `bh/skip-non-archivable-tasks` 的语义？
- [ ] 月份边界 smoke 是否覆盖了截图暴露的最近 DONE 混入问题？
- [ ] `ARCHIVE_CANDIDATE` 是否继续保持虚拟、不写回？

## 证据链接

- plan: `.legion/tasks/org-agenda-archive-parity-fix/plan.md`
- design-lite: `.legion/tasks/org-agenda-archive-parity-fix/docs/rfc.md`
- test-report: `.legion/tasks/org-agenda-archive-parity-fix/docs/test-report.md`
- review-change: `.legion/tasks/org-agenda-archive-parity-fix/docs/review-change.md`
- report-walkthrough: `.legion/tasks/org-agenda-archive-parity-fix/docs/report-walkthrough.md`

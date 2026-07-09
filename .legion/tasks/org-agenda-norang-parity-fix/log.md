# org-agenda-norang-parity-fix Log

| 时间 | 阶段 | 记录 |
|---|---|---|
| 2026-07-09 | brainstorm | 用户要求以 Emacs 原生 Norang agenda 截图为 baseline，修复 nvim org agenda view，并明确要求使用 Legion workflow。 |
| 2026-07-09 | brainstorm | 入口判断：仓库存在 `.legion/`，当前请求是修改型多步骤工程任务；无明确恢复 task id/path，因此创建新 task contract。 |
| 2026-07-09 | brainstorm | 初步差异：当前 `b` command 顺序为 Refile -> Today -> Next actions -> Waiting/Hold -> Projects...；baseline 为 day agenda -> Tasks to Refile -> Stuck/Projects -> Project Next/Subtasks -> Standalone -> Waiting and Postponed -> Tasks to Archive。 |
| 2026-07-09 | design-lite | 风险判定为 Low：局部配置与测试改动，无 API/schema/auth/security/依赖变更，可通过 `git revert` 回滚。 |
| 2026-07-09 | engineer | 只靠 `PROJECT` tag inheritance 会让 project 父节点区和 project 子任务区互相串区；实现改为新增 `PROJECT_TASK` 分类，并将虚拟/旧物化标签排除出普通继承。 |
| 2026-07-09 | contract-pivot | 用户确认应按 Emacs 原生路线，project/stuck/archive 这类状态不应写回 org 文件；任务转向虚拟 agenda 分类/内存索引。 |
| 2026-07-09 | engineer | 新增 `org_legion.virtual_tags`，`OrgLegionRefresh` 改为重建内存索引，agenda search 仅在查询包含虚拟标签时临时注入 `PROJECT/STUCK/PROJECT_TASK/ARCHIVE_CANDIDATE`。 |
| 2026-07-09 | verify-change | `ALLOW_UNPINNED_ORGMODE=1 bash tests/smoke/run.sh` PASS，含 `legion_refresh_indexes_stuck_project`、`legion_refresh_indexes_project_tasks` 与 `legion_e2e_integrated_flow`；直接执行脚本因无执行位被改用 `bash`。 |
| 2026-07-09 | review-change | PASS；无 blocking findings；未命中安全触发；残余风险为 unpinned orgmode runtime smoke fallback。 |
| 2026-07-09 | report-walkthrough | 生成 `docs/report-walkthrough.html`、`docs/report-walkthrough.md`、`docs/pr-body.md`；HTML 静态质量门 PASS；render handoff 记录为 artifact-only/local，见 `docs/render-handoff.md`。 |
| 2026-07-09 | legion-wiki | 新增 `.legion/wiki/tasks/org-agenda-norang-parity-fix.md`，更新 index/log/patterns，记录 orgmode agenda parity derived tag 模式。 |

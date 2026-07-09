# Report Walkthrough

## Profile

implementation

## Reviewer Summary

- 本任务修复 `:Org agenda b` 与 Emacs 原生 Norang block agenda baseline 的顺序、标题和分类差异。
- 主要实现是重排 custom command，新增 `PROJECT_TASK` 虚拟标签，并把 `PROJECT/STUCK/PROJECT_TASK/ARCHIVE_CANDIDATE` 改为 agenda/search 时的内存分类。
- `review-change` 结论为 PASS，无 blocking findings，未命中安全触发。
- PR lifecycle 尚未完成；本文档和 `pr-body.md` 只是 review 输入。

## Scope

In scope:

- `lua/plugins/orgmode.lua`
- `lua/org_legion/**`
- `lua/tests/smoke/orgmode_smoke.lua`
- `tests/smoke/run.sh`
- `skills/legion-workflow/**`
- `.legion/tasks/org-agenda-norang-parity-fix/**`

Out of scope:

- 不重做 Norang 全套 GTD workflow。
- 不修改 clock、capture、refile picker 状态机。
- 不修改用户私有 org 文件。
- 不更新 orgmode.nvim pin 或新增依赖。

## Evidence Map

| Claim | Evidence | Status |
|---|---|---|
| agenda baseline 已按截图顺序重排 | `plan.md`, `docs/rfc.md`, `lua/plugins/orgmode.lua` | PASS |
| project 父节点与项目子任务分类已拆开 | `lua/org_legion/rules.lua`, `agenda_block_matches_norang_baseline`, `legion_refresh_indexes_project_tasks` | PASS |
| refresh 不再写回 org 文本 | `lua/org_legion/virtual_tags.lua`, `legion_refresh_indexes_stuck_project`, `legion_e2e_integrated_flow` | PASS |
| 旧 org workflow 未回归 | `docs/test-report.md`, full smoke | PASS |
| 变更可交付 | `docs/review-change.md` | PASS |

## What Changed / What Was Decided

- `b` command 变为 Norang-style block agenda：day agenda、Tasks to Refile、Stuck Projects、Projects、Project Next Tasks、Project Subtasks、Standalone Tasks、Waiting and Postponed Tasks、Tasks to Archive。
- 新增 `PROJECT_TASK` 虚拟标签，用于标记项目内 active 子任务。
- `PROJECT/STUCK/PROJECT_TASK/ARCHIVE_CANDIDATE` 排除出普通 tag inheritance，避免旧物化标签让 Projects 区和 Project Subtasks 区互相串区。
- `OrgLegionRefresh` 现在只重建内存索引；agenda/search adapter 只在查询包含虚拟标签时临时注入这些分类。
- `<F12>`、`<Leader>oab`、`<Leader>oan`、`<Leader>oas` 打开 agenda 前先执行 `org_legion.refresh_all()`。

## Verification / Review Status

- Targeted smoke: PASS。
- Full smoke: PASS。
- `git diff --check`: PASS。
- `stylua`: skipped，因为当前环境未安装。
- Review: PASS，无 blocking findings。

## Risks and Limits

- Full smoke 使用本机 unpinned orgmode runtime，这是现有 runner 的显式 fallback。
- 空 section 是否显示仍受 orgmode.nvim agenda renderer 行为影响，本轮只修复配置结构和分类输入。
- 打开相关 agenda 前会刷新虚拟索引；若 refresh 失败，会 warning 并继续打开 agenda。

## Reviewer Checklist

- [ ] `b` block agenda 顺序和标题是否符合截图 baseline？
- [ ] `PROJECT_TASK` 的分类边界是否符合 Norang 近似语义？
- [ ] 验证证据是否足以覆盖 UI 配置、虚拟标签 search 和 refresh 不写回？
- [ ] 文档是否清楚说明 PR lifecycle 尚未完成？

## Next Stage

PR-backed lifecycle 中，本任务采用 artifact-only/local render handoff，见 `docs/render-handoff.md`。下一步进入 `legion-wiki` 写回。`docs/pr-body.md` 仅作为 PR 创建或更新输入。

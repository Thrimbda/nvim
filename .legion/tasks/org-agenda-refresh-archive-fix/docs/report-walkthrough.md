# Report Walkthrough

## Profile

implementation

## Reviewer Summary

- 本次修复两个用户可见问题：archive section 漏掉 Emacs baseline 中的 `PHONE` / `MEETING` done-state 条目，以及 agenda 前 refresh 失败时出现两条含糊 warning。
- 根因是配置层只把 `DONE/CANCELLED` 当完成态，PR #12 的 archive matcher 虽然已经接近 Norang 查询语义，但没有把 `PHONE/MEETING` 纳入 done keyword 集合。
- 另一个根因是 `refresh_all()` 自己通知一次，agenda wrapper 再按 fail 数通知一次，且 wrapper 不显示失败文件和 `error.code/message`。
- 交付状态：implementation review PASS，full smoke PASS，真实 agenda 文件 refresh 为 `total=22 ok=22 fail=0`。

## Scope

In scope:

- 更新 `lua/plugins/orgmode.lua` 的 orgmode done keywords、faces、agenda refresh wrapper 和 `org_legion.todo.done` 配置。
- 更新 `lua/org_legion/init.lua` 的 done keyword defaults 和 refresh failure summary formatter。
- 更新 `lua/org_legion/todo_triggers.lua`，让 `PHONE/MEETING` 清理 stale flow tags。
- 增加 smoke 覆盖 archive completeness、warning details、manual refresh formatter 和 trigger cleanup。

Out of scope:

- 不修改真实 org 文件内容。
- 不清理已有物化 `ARCHIVE_CANDIDATE` 标签。
- 不重做 agenda renderer 或 section 结构。
- 不处理外部同步状态或 OneDrive 文件系统问题本身。

## Evidence Map

| Claim | Evidence | Status |
|---|---|---|
| `PHONE/MEETING` 已进入 orgmode 和 org_legion done-state 配置 | `lua/plugins/orgmode.lua`; `lua/org_legion/init.lua`; `agenda_block_matches_norang_baseline` | PASS |
| `PHONE/MEETING` 旧条目能匹配 `Tasks to Archive` 的 `-REFILE/` 查询 | `legion_archive_candidates_match_norang_month_boundary` | PASS |
| agenda 前 refresh 失败只产生一条带详情 warning | `agenda_refresh_failure_warning_includes_details` | PASS |
| manual `OrgLegionRefresh` summary 带失败文件与错误 code/message | `legion_refresh_failure_summary_formats_paths` | PASS |
| done-state trigger 不留下 stale `WAITING/HOLD/CANCELLED` tags | `todo_state_tag_triggers_legion` | PASS |
| 全量 org workflow 未回归 | `docs/test-report.md` full smoke | PASS |
| 只读交付审查无阻塞项 | `docs/review-change.md` | PASS |

## Delivery Path

1. `brainstorm`: 收敛用户反馈为 archive completeness 和 refresh diagnostics 两个问题。
2. `design-lite`: 选择低风险配置 parity 加统一 failure formatter。
3. `engineer`: 实现 keyword parity、single warning wrapper、failure summary formatter 和 smoke tests。
4. `verify-change`: targeted smoke、full smoke、`git diff --check`、真实 agenda refresh。
5. `review-change`: PASS，无 blocking findings。
6. `report-walkthrough`: 当前文档、HTML artifact 和 PR body。
7. `legion-wiki`: 下一阶段写回任务 summary 与 reusable pattern。

## What Changed / What Was Decided

- `org_todo_keywords` 现在是 `TODO/NEXT/WAITING/HOLD | DONE/CANCELLED/PHONE/MEETING`，和 capture templates 中已有的 `PHONE` / `MEETING` keyword 对齐。
- `org_legion.todo.done` 默认值和插件配置都包含 `PHONE/MEETING`，archive candidate 规则不需要额外分支即可覆盖这些完成态。
- `open_agenda_after_legion_refresh()` 调用 `refresh_all({ notify = false })`，避免 refresh summary 和 agenda wrapper 同时通知。
- `format_refresh_failures()` 和 `format_refresh_summary()` 把失败文件、`error.code` 和 `error.message` 压缩到 warning 中。
- `todo_triggers` 把 `PHONE/MEETING` 当成 done-state cleanup 目标，清理 `WAITING/HOLD/CANCELLED`，但保留业务 tag。

## Verification / Review Status

- Targeted smoke: PASS。
- Full smoke: PASS，输出 `All smoke cases passed.`。
- `git diff --check`: PASS。
- `stylua`: 本机未安装，未运行。
- 真实 `~/OneDrive/cone/**/*.org` refresh: `org_legion refresh: total=22 ok=22 fail=0 skipped_conflict=0 skipped_unloaded=0`。
- `review-change`: PASS，无阻塞项，未命中 security trigger。

## Risks and Limits

- 本机 smoke 使用现有 opt-in unpinned orgmode fallback：`/Users/c1/.local/share/nvim/lazy/orgmode`，因为仓库没有 `.tests/deps/orgmode`。
- 如果用户交互态还有 transient loaded buffer 内容导致 refresh failure，新 warning 会显示具体文件和错误摘要，但不会自动修复该 org 文件内容。
- PR lifecycle 尚未完成；PR body 和 walkthrough 是创建 PR 的输入，不代表 checks、review、merge、cleanup 或主工作区 refresh 已完成。

## Reviewer Checklist

- [ ] 检查 `PHONE/MEETING` 是否应作为 Norang done-state keyword 与 Emacs baseline 保持一致。
- [ ] 检查 agenda wrapper 是否只在 fail 时发一条 warning，且不阻止 agenda 打开。
- [ ] 检查 failure formatter 是否只暴露路径和错误摘要，不泄露文件内容。
- [ ] 检查新增 smoke 是否覆盖截图中的 archive 缺项和 warning 问题。

## Next Stage

Render handoff 结果：artifact/local-only，不新增 Pages preview workflow。PR-backed lifecycle 仍需执行：`legion-wiki` 写回总结，然后 commit、push、PR、checks/review、merge、cleanup 和主工作区 refresh。

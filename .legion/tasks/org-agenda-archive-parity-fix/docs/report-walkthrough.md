# Report Walkthrough

## Profile

implementation

## Reviewer Summary

- 本任务修复 PR #11 后遗留的 `Tasks to Archive` 差异。
- Archive candidate 判定现在按 Norang 原生月份语义执行：done-state todo 只有在子树没有本月或上月时间戳时才可归档。
- `b` agenda 的 archive block 改为 `-REFILE/`，虚拟搜索 adapter 在内部叠加 `ARCHIVE_CANDIDATE` 过滤。
- 新增 smoke 覆盖 old DONE、this-month DONE、last-month DONE、open TODO、REFILE DONE。

## Scope

In scope:

- `lua/org_legion/rules.lua`
- `lua/org_legion/virtual_tags.lua`
- `lua/plugins/orgmode.lua`
- `lua/tests/smoke/orgmode_smoke.lua`
- `tests/smoke/run.sh`

Out of scope:

- 不重做其他 agenda sections。
- 不实现批量 archive 操作。
- 不自动删除用户文件里已有的物化 `ARCHIVE_CANDIDATE` 标签。

## Evidence Map

| Claim | Evidence | Status |
|---|---|---|
| Archive 规则改为 Norang 月份语义 | `docs/rfc.md`, `lua/org_legion/rules.lua` | PASS |
| Agenda archive block 不再裸查 `ARCHIVE_CANDIDATE` | `lua/plugins/orgmode.lua`, `agenda_block_matches_norang_baseline` | PASS |
| 当前月和上月时间戳会阻止 archive | `legion_archive_candidates_match_norang_month_boundary` | PASS |
| 变更没有写回派生标签 | `docs/test-report.md` | PASS |
| 代码审查无阻塞项 | `docs/review-change.md` | PASS |

## What Changed / What Was Decided

- `ARCHIVE_CANDIDATE` 保留为内部虚拟标签，但用户可见 archive matcher 改为 Norang 的 `-REFILE/`。
- `-REFILE/` 这个精确查询会被 org_legion virtual search adapter 解释为 Norang archive block 查询。
- 旧的 day-count stale 近似被替换为本月和上月前缀扫描。

## Verification / Review Status

- `ALLOW_UNPINNED_ORGMODE=1 bash tests/smoke/run.sh`: PASS。
- `git diff --check`: PASS。
- `stylua`: 当前环境不可用，skipped。
- `review-change`: PASS。

## Risks and Limits

- 若用户 org 文件里已有真实 `ARCHIVE_CANDIDATE` 标签，它仍是普通用户标签；本修复保证它不再把最近 DONE 拉进 archive section。
- `-REFILE/` 被精确绑定到 Norang archive 语义。若未来需要通用的 “not REFILE” tags search，需要 orgmode.nvim 提供更细的 custom command context。

## Reviewer Checklist

- [ ] 确认 `Tasks to Archive` matcher 与 Norang baseline 一致。
- [ ] 确认月份边界行为符合预期。
- [ ] 确认 `ARCHIVE_CANDIDATE` 仍不写回 org 文件。

## Next Stage

PR-backed lifecycle 仍需创建 PR、跟进 checks、尝试 auto-merge、合并后清理 worktree 并刷新主工作区。

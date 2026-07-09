# Log

| Date | Phase | Notes |
|---|---|---|
| 2026-07-09 | brainstorm | 用户反馈 PR #11 后 `Tasks to Archive` 仍不对；截图显示 archive section 仍列出不应出现的 DONE 条目，并出现 `ARCHIVE_CANDIDATE` 可见标签。 |
| 2026-07-09 | design-lite | 对照 Norang 原文：archive block 是 `tags "-REFILE/"` 加 `bh/skip-non-archivable-tasks`；done subtree 若有本月或上月任意时间戳则跳过。 |
| 2026-07-09 | engineer | 将 archive candidate 改为 Norang 月份前缀规则；`Tasks to Archive` matcher 改为 `-REFILE/`，由虚拟搜索 adapter 叠加内部 archive candidate 过滤。 |
| 2026-07-09 | verify | `ALLOW_UNPINNED_ORGMODE=1 bash tests/smoke/run.sh` 通过，包含新增 `legion_archive_candidates_match_norang_month_boundary`；`git diff --check` 通过；`stylua` 不可用，记录为 skipped。 |
| 2026-07-09 | closeout | 生成 walkthrough、PR body、render handoff，并写回 Legion wiki task summary 与 orgmode agenda parity pattern。 |

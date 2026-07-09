# org-agenda-archive-parity-fix

## Contract

- `name`: Norang archive candidate parity fix
- `taskId`: `org-agenda-archive-parity-fix`
- `goal`: 修复 `:Org agenda b` 中 `Tasks to Archive` 与 Emacs/Norang baseline 的剩余差异。
- `problem`: PR #11 将 `ARCHIVE_CANDIDATE` 改为虚拟标签，但 archive 判定仍是近似的 `stale_days + recent_month_window` 规则，且 agenda block 直接查询实现标签；截图显示 `Tasks to Archive` 仍包含不应出现的 DONE 条目，并可能暴露 `ARCHIVE_CANDIDATE`。

## Acceptance

- `Tasks to Archive` 使用 Norang 原生语义：排除 `REFILE`，只列 done-state todo，并跳过子树中包含本月或上月任意时间戳的条目。
- 当前月/上月的 inactive timestamp、closed date、note timestamp、clock timestamp 等都会阻止条目进入 archive section。
- 早于上月且无当前月/上月时间戳的 DONE 条目仍能进入 archive section。
- `ARCHIVE_CANDIDATE` 继续作为内部虚拟标签存在，但 `b` agenda archive matcher 不再以裸标签查询作为用户可见语义。
- 保持 PR #11 的虚拟标签不写回 org 文件原则，不引入新的物化派生标签。

## Scope

- 允许修改 `lua/org_legion/**` 中 archive 规则和虚拟搜索行为。
- 允许修改 `lua/plugins/orgmode.lua` 中 `Tasks to Archive` 的 matcher。
- 允许补充 smoke 测试和 Legion 交付文档。

## Non-goals

- 不重做其他 Norang agenda sections。
- 不实现真实批量 archive 操作。
- 不删除用户已有的实际 `ARCHIVE_CANDIDATE` 标签；cleanup 仍作为显式迁移命令。
- 不改变 `PROJECT`、`STUCK`、`PROJECT_TASK` 的现有语义。

## Assumptions

- `org-done-keywords` 等价于当前配置里的 `DONE` 和 `CANCELLED`。
- Norang 的月份判断按当前本地时间计算：本月和上月任意 `YYYY-MM-` 时间戳都算当前，不可归档。
- `Tasks to Archive` 的用户可见 baseline 来自 Norang `tags "-REFILE/"` 加 `bh/skip-non-archivable-tasks`。

## Constraints

- 修改必须在 Git worktree 中完成，并通过 PR 交付。
- 不碰主工作区已有的 `lazy-lock.json` 修改。
- 不引入新依赖。

## Risks

- orgmode.nvim 的 matcher 不支持 Emacs skip-function，需要继续通过虚拟搜索 adapter 模拟。
- 若用户 org 文件中已有物化 `ARCHIVE_CANDIDATE` 标签，普通 tag 显示可能仍能看到真实标签；本任务只保证本插件不再新增或依赖它。
- 时间相关测试需要固定 `now`，避免月初/月末 flake。

## Design Summary

- 将 archive candidate 判定从 `stale_days + recent_month_window` 改为 Norang 月份前缀模型：计算 `this_month_prefix` 和 `last_month_prefix`，在 done subtree 中查找这些前缀；找到则不可归档。
- 为虚拟搜索 adapter 增加 archive skip 查询支持，让 `-REFILE/` 能结合内部 `ARCHIVE_CANDIDATE` 语义过滤，而不是要求 agenda 直接查询裸虚拟标签。
- 将 `b` agenda 的 archive block 改为 Norang baseline 的 `-REFILE/` 形式，并加一个内部选项启用 archive candidate filter。

## Phases

- `engineer`: 实现 archive 判定、matcher 调整和测试。
- `verify-change`: 运行 smoke、diff check 和必要的 targeted 测试。
- `review-change`: 检查行为风险、测试覆盖和 scope。
- `report-walkthrough`: 生成 reviewer-facing handoff。
- `legion-wiki`: 写回当前真源和可复用模式。

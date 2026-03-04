# norang-workflow

本 Skill 是本仓库 Norang orgmode 工作流的 AI 执行指南。

## 真源与更新策略

- 主真源：`docs/orgmode-norang-workflow.md`
- 若本 Skill 与真源文档或运行时行为冲突，以 `docs/orgmode-norang-workflow.md` 为准，并将本文件视为过期。
- Last verified: 2026-03-04。
- 当真源文档更新时，需要同步更新本 Skill 与 `Last verified`。

## 适用范围与目标

当任务涉及本仓库 orgmode 的日常执行或说明编写时使用本 Skill，尤其是：

- Punch in/out 连续记时
- 任务级 clock in/out
- Capture 的 clock handoff
- Agenda 视图（`b/n/t/s/r`）与日常执行顺序
- Norang refresh/cleanup/reload 排错

目标：

- 让 AI 以最小歧义执行工作流。
- 在非收工场景下尽量保持连续记时。
- 优先执行更安全的操作（先 dry-run，再 apply；先 reload，再深度恢复）。

不在范围内：

- 修改 Lua 运行时代码（`lua/**`）
- 重定义文档之外的 TODO 状态或标签规则
- 调整 orgmode UI 像素/布局行为

## 执行前检查（Preflight）

在执行流程或故障处置前，先检查：

1. 默认任务 ID 已配置且可解析：
   - `lua/config/options.lua` 中存在 `vim.g.org_organization_task_id`
   - 对应 `:ID:` headline 位于 `org_agenda_files` 覆盖文件中
2. 可选日志文件：
   - 如 journal 目标非默认，设置 `vim.g.org_diary_file`
3. 键位前提：
   - `<Leader>` 为 `<Space>`
   - org 前缀为 `<Leader>o`
4. 写回语义：
   - punch/clock 状态变化是内存 buffer 变更，必要时需要手动保存

## 命令与快捷键矩阵

### Punch（连续记时）

| 操作 | 快捷键 / 命令 | 预期行为 |
| --- | --- | --- |
| 开始连续记时 | `<Leader>opI` | 开启 punch 模式，并 clock 到默认组织任务 |
| 结束当前任务但保持连续 | `<Leader>opo` | 对当前条目 clock out，然后回到父任务或默认任务 |
| 结束连续记时 | `<Leader>opO` | 关闭 punch 模式并 clock out |

### Clock（任务级）

| 操作 | 快捷键 / 命令 | 预期行为 |
| --- | --- | --- |
| 当前条目 clock in | `<Leader>oxi`（或 agenda `I`） | 应用 Norang 的 TODO/NEXT 自动切换规则 |
| 当前条目 clock out | `<Leader>oxo`（或 agenda `O`） | 删除 `0:00` CLOCK；在 punch 模式回退到父任务/默认任务 |
| 取消当前 clock | agenda `X` | 取消当前 clock |
| 查看 clock report | agenda `R` | 打开或切换 clock 汇总视图 |

### Capture

| 操作 | 快捷键 / 命令 | 预期行为 |
| --- | --- | --- |
| 打开 capture | `<Leader>X` | 使用 Norang 模板，并暂停当前 clock（handoff） |
| 完成 capture | `<C-c>` | 保存 capture，并恢复之前 clock |
| 取消 capture | `<Leader>ok` | 取消 capture，并恢复之前 clock |

兼容性说明：本仓库已禁用默认 `<Leader>oc`，请只使用 `<Leader>X`。

### Agenda

| 视图 | 快捷键 / 命令 | 用途 |
| --- | --- | --- |
| Block agenda | `<F12>` 或 `<Leader>oab` 或 `:Org agenda b` | 主日程总览（项目/独立任务/归档候选等） |
| NEXT 列表 | `<Leader>oan` 或 `:Org agenda n` | 下一步行动 |
| Timeline | `<Leader>oat` 或 `:Org agenda t` | 当日时间线（需显式时间戳才占位） |
| Stuck Projects | `<Leader>oas` 或 `:Org agenda s` | 识别卡住的项目 |
| Refile 列表 | `<Leader>oar` 或 `:Org agenda r` | 收件箱/重归档处理 |

## 标准操作流程

### 开工

1. 执行 Preflight（默认任务 ID、agenda 覆盖）。
2. 用 `<Leader>opI` 开启连续记时。
3. 打开 block agenda（`<Leader>oab`），选择具体任务。
4. 用 `<Leader>oxi`（或 agenda `I`）进入该任务。

### 工作中

1. 有新输入时用 `<Leader>X` capture，完成后 `<C-c>`。
2. 切换任务时，先 `<Leader>oxo`，再对下个任务 clock in。
3. 完成当前任务但不下班时，优先 `<Leader>opo` 保持连续记时。
4. 若派生标签/状态看起来不一致，执行 `:OrgNorangRefresh`。

### 收工

1. 回到安全状态（通常是默认任务）。
2. 用 `<Leader>opO` 结束连续记时。
3. 按需保存变更 buffer（memory-only 语义）。
4. 可选整理：检查 agenda `r`（refile）及 WAITING/HOLD 条目。

## 常见故障与恢复

- `E_CFG_INVALID`：
  - 修复配置关系（如 `todo.next` 必须属于 `todo.active`，writeback 必须为 `memory_only`）
  - 执行 `:OrgNorangReload`
- 刷新时报 `E_CONFLICT_STALE_SNAPSHOT`：
  - 说明事务期间文件有变化，重新执行 `:OrgNorangRefresh`
- `skipped_unloaded` 过高：
  - 检查 `refresh.refresh_unloaded_files`，并确认文件可写、在覆盖范围内
- Punch in 未回到默认任务：
  - 检查 `vim.g.org_organization_task_id` 与对应 `:ID:` headline 是否可被 agenda 解析
- `opo` 未回父任务：
  - 当不存在 TODO/NEXT/WAITING/HOLD 祖先任务时，回退默认任务是预期行为
- clock 后 timeline 没有 time block：
  - 只有显式带时间的 `SCHEDULED`/timestamp 才会占用时间线槽位
- Capture CLOCK 时长看起来不一致：
  - Capture 按分钟粒度计时；不足 1 分钟可能不写 CLOCK，跨分钟边界按分钟差写入

## 回滚与安全边界

当需要回滚派生标签影响时：

1. 临时停用或停止 Norang 自动化路径。
2. 执行 `:OrgNorangCleanupDerivedTags`（dry-run）。
3. 审阅影响后，仅在用户明确确认后执行 `:OrgNorangCleanupDerivedTags!`。
4. 保存受影响 buffer。

安全说明：

- Cleanup 仅清理派生标签（`PROJECT`、`STUCK`、`ARCHIVE_CANDIDATE`），不应删除用户自定义标签。
- 不确定时一律先 dry-run，避免直接 apply。

## AI 执行边界

- 可以：按文档执行命令/快捷键、检查前置条件、报告偏差。
- 不可以：修改 Lua 运行时代码、发明未定义语义、在未保存情况下声称已持久化。
- 若任务要求改动 `lua/**` 或重设计 TODO/标签规则：停止 autopilot，转人工决策。
- 若观察到行为与本 Skill 不一致：引用具体差异，并以 `docs/orgmode-norang-workflow.md` 为准。

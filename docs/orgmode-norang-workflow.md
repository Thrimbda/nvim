# nvim-orgmode Norang 工作流使用说明

本文档说明本仓库当前的 Norang 工作流：

- 自定义 agenda 视图（`b/n/r`）
- Punch in/out 连续记时（不中断 clock）
- `org_norang` 派生标签刷新与清理

## 1. 先准备默认任务（必须）

在任意 org 文件放一个默认任务，并设置稳定 `:ID:`。

```org
* Tasks
** Organization
   :PROPERTIES:
   :ID: 01234567-89ab-cdef-0123-456789abcdef
   :END:
```

在 Neovim 配置里设置该 ID：

```lua
vim.g.org_organization_task_id = "01234567-89ab-cdef-0123-456789abcdef"
```

`lua/org_punch.lua` 会用这个 ID 作为兜底任务。

## 2. 已配置能力

来自 `lua/plugins/orgmode.lua`：

- TODO 流程：`TODO -> NEXT/WAITING/HOLD -> DONE/CANCELLED`
- 完成日志：写入 `LOGBOOK`
- Agenda 打开后自动移动到右侧
- 自定义 agenda：
  - `:Org agenda b`：Block agenda（保留 Refile/Today/Next/Waiting/Hold，并新增派生视图）
  - `:Org agenda n`：NEXT 列表
  - `:Org agenda t`：Timeline（日视图时间线）
  - `:Org agenda s`：Stuck Projects 列表
  - `:Org agenda r`：REFILE 列表

`b` 视图新增：

- `PROJECT+STUCK`（Stuck Projects）
- `PROJECT-STUCK`（Projects）
- `+TODO="TODO"-PROJECT-REFILE`（Standalone Tasks）
- `ARCHIVE_CANDIDATE`（Archive Candidates）

## 3. org_norang 命令

- `:OrgNorangRefresh`：全量刷新（默认处理 `org_agenda_files` 内全部文件，包含未加载文件）
- `:OrgNorangReload`：重载配置并尝试从 `E_CFG_INVALID` 恢复
- `:OrgNorangCleanupDerivedTags`：清理派生标签 dry-run（默认不写）
- `:OrgNorangCleanupDerivedTags!`：清理派生标签 apply（实际修改内存 buffer）

刷新语义（V1）：

- 规则模式：`approx`
- `mode=precise` 会降级到 `approx` 并给出 warning
- 写回语义：`memory_only`（已加载 buffer 只改内存，不自动写盘）
- 当 `refresh.refresh_unloaded_files = true`（默认）时，`OrgNorangRefresh` 会直接写回未加载文件
- 保存触发刷新后，已加载 buffer 可能再次变脏，需要用户二次保存
- 若将 `refresh.refresh_unloaded_files = false`，未加载文件会计入 `skipped_unloaded`

## 4. 快捷键

- `<Leader>oab`：打开 block agenda
- `<Leader>oan`：打开 NEXT 列表
- `<Leader>oat`：打开 Timeline（日视图）
- `<Leader>oas`：打开 Stuck Projects 列表
- `<Leader>oar`：打开 REFILE 列表

时间线说明：

- 已启用 `org_agenda_time_grid`（daily），会在日视图显示时间栅格
- 若任务没有时间戳（只有日期没有小时分钟），会出现在当天列表但不占用具体时间槽

Punch 相关：

- `<Leader>opI`：Punch In（开启连续记时，并 clock 到默认任务）
- `<Leader>opo`：Clock out 但保持连续（自动回父任务或默认任务）
- `<Leader>opO`：Punch Out（停止连续记时，并 clock out）

原生 clock（orgmode.nvim）：

- Org 文件中：`<Leader>oxi` / `<Leader>oxo` / `<Leader>oxj`
- Agenda 视图中：`I` / `O`

## 5. 推荐日常流程

1. 上班后 `<Leader>opI` 进入连续记时。
2. `<Leader>oab` 打开 block agenda。
3. 对具体任务执行 clock in。
4. 完成当前任务时使用 `<Leader>opo`，优先保持连续 clock。
5. 午休或下班 `<Leader>opO` 结束连续记时。
6. 需要统一更新派生标签时执行 `:OrgNorangRefresh`。

## 6. 回滚与 cleanup

当需要回滚派生标签副作用时：

1. 先停用 `org_norang.setup`（或临时 `enabled = false`）。
2. 执行 `:OrgNorangCleanupDerivedTags` 查看 dry-run 结果。
3. 确认后执行 `:OrgNorangCleanupDerivedTags!` 应用清理。
4. 保存受影响 buffer。

说明：cleanup 仅清理 `PROJECT/STUCK/ARCHIVE_CANDIDATE` 派生标签，不会删除用户标签。

## 7. 排错

### 7.1 `:OrgNorangRefresh` 后统计里 `skipped_unloaded` 很高

通常是 `refresh.refresh_unloaded_files = false` 或文件不可写导致；默认配置下该值应较低。

### 7.2 提示 `E_CONFLICT_STALE_SNAPSHOT`

说明刷新事务期间 `changedtick` 或 `mtime` 发生变化，系统放弃写回以避免覆盖新改动。重新执行刷新即可。

### 7.3 `E_CFG_INVALID`（进入错误态）

检查配置是否合法（例如 `todo.next` 必须属于 `todo.active`，`writeback` 必须是 `memory_only`），修复后执行 `:OrgNorangReload`。

### 7.4 `<Leader>opI` 没有 clock 到默认任务

检查是否设置了 `vim.g.org_organization_task_id`，且对应 ID 存在于 `org_agenda_files` 覆盖文件中。

### 7.5 `<Leader>opo` 后没有回父任务

若当前条目向上的祖先里没有 `TODO/NEXT/WAITING/HOLD` 父任务，会回到默认任务，这是预期行为。

## 8. 相关文件

- 配置：`lua/plugins/orgmode.lua`
- Norang 模块：`lua/org_norang/init.lua`
- Punch 实现：`lua/org_punch.lua`

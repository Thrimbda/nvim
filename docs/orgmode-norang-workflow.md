# nvim-orgmode Norang 工作流使用说明

本文档说明如何在本仓库中使用已经配置好的 Norang 风格工作流：

- 自定义 agenda 视图（`b/n/r`）
- Punch in/out 连续记时（不中断 clock）

## 1. 先准备默认任务（必须）

在你的任意 org 文件里放一个默认任务，并设置稳定的 `:ID:`。

```org
* Tasks
** Organization
   :PROPERTIES:
   :ID: 01234567-89ab-cdef-0123-456789abcdef
   :END:
```

然后在你的 Neovim 配置里设置这个 ID（与上面一致）：

```lua
vim.g.org_organization_task_id = "01234567-89ab-cdef-0123-456789abcdef"
```

说明：`lua/org_punch.lua` 会用这个 ID 作为“兜底任务”定位点。

## 2. 已配置的关键能力

来自 `lua/plugins/orgmode.lua`：

- TODO 流程：`TODO -> NEXT/WAITING/HOLD -> DONE/CANCELLED`
- 完成日志：写入 `LOGBOOK`（`org_log_into_drawer = "LOGBOOK"`）
- Agenda 窗口：打开后自动移动到右侧
- 自定义 agenda：
  - `:Org agenda b`：Block agenda（Refile + Today + Next + Waiting + Hold）
  - `:Org agenda n`：NEXT 列表
  - `:Org agenda r`：REFILE 列表

## 3. 快捷键

- `<Leader>oab`：打开 block agenda
- `<Leader>oan`：打开 NEXT 列表
- `<Leader>oar`：打开 REFILE 列表

Punch 相关：

- `<Leader>opI`：Punch In（开启连续记时，并 clock 到默认任务）
- `<Leader>opo`：Clock out 但保持连续（自动回父任务或默认任务）
- `<Leader>opO`：Punch Out（停止连续记时，并 clock out）

原生 clock（orgmode.nvim）：

- Org 文件中：`<Leader>oxi` / `<Leader>oxo` / `<Leader>oxj`
- Agenda 视图中：`I` / `O`

提示：`<Leader>opo` 和 `<Leader>opO` 只差大小写，建议在终端里确认大写 `O` 能正常触发。

## 4. 每天怎么用（推荐流程）

1. 上班后按 `<Leader>opI`，先进入连续记时状态。
2. 按 `<Leader>oab` 打开 block agenda，进入当天任务。
3. 对具体任务执行 clock in（agenda/orgmode 的原生 clock in）。
4. 做完一个任务时，不要直接停表，使用 `<Leader>opo`：
   - 先 clock out 当前任务
   - 若存在父项目任务（`TODO/NEXT/WAITING/HOLD`），自动 clock in 到父任务
   - 否则回到默认 `Organization` 任务
5. 午休或下班按 `<Leader>opO` 结束连续记时。

## 5. 使用原则（很重要）

- Punch In 之后，优先用 `<Leader>opo` 而不是普通 clock out。
- 如果你直接普通 clock out，可能会出现“空档分钟”不被记录。
- 默认任务 ID 必须存在且唯一，否则 punch in 无法兜底。

## 6. 排错

### 6.1 按了 `<Leader>opI` 没有 clock 到默认任务

检查：

- 是否设置了 `vim.g.org_organization_task_id`
- 对应 ID 是否真的存在于 `org_agenda_files` 覆盖的文件中
- 默认路径当前是 `~/OneDrive/cone/**/*`

### 6.2 `<Leader>opo` 后没有回父任务

这是正常的前提之一：

- 当前任务向上的祖先标题里，需要存在带 TODO 关键字的父任务（`TODO/NEXT/WAITING/HOLD`）。
- 如果没有，会回默认任务。

### 6.3 Agenda 视图为空

检查 org 文件是否在 `org_agenda_files` 路径内，以及条目是否满足对应匹配条件（如 `NEXT`、`REFILE`）。

### 6.4 Agenda 没在右侧

- 当前配置会在 `orgagenda` buffer 打开后执行 `wincmd L`。
- 如果你手动改了窗口布局，重新执行一次 `:Org agenda b` 即可回到右侧。

## 7. 相关文件

- 配置：`lua/plugins/orgmode.lua`
- Punch 实现：`lua/org_punch.lua`
- 验证步骤：`.legion/tasks/nvim-orgmode-norang-workflow/docs/test-report.md`

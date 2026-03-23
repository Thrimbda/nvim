# nvim-orgmode Legion 工作流使用说明

本文档说明本仓库当前的 Legion 工作流：

- 自定义 agenda 视图（`b/n/t/s/r`）
- Punch in/out 连续记时（不中断 clock）
- `org_legion` 派生标签刷新与清理

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

本仓库当前放在 `lua/config/options.lua`，这是默认任务 ID 的唯一配置入口（`org_punch` 不再内置硬编码兜底 ID）。

Journal 目标文件也支持在配置里显式指定：

```lua
vim.g.org_diary_file = "~/OneDrive/cone/diary.org"
```

`lua/plugins/orgmode.lua` 顶部会读取该值（未设置时回退到同一路径默认值）。

## 2. 已配置能力

来自 `lua/plugins/orgmode.lua`：

- TODO 流程：`TODO -> NEXT/WAITING/HOLD -> DONE/CANCELLED`
- TODO 状态触发标签（Legion）：
  - 切到 `WAITING` 自动添加 `WAITING`
  - 切到 `HOLD` 自动添加 `WAITING` 与 `HOLD`
  - 切到 `CANCELLED` 自动添加 `CANCELLED` 并移除 `WAITING/HOLD`
  - 切到 `TODO/NEXT/DONE` 自动移除 `WAITING/HOLD/CANCELLED`
- Clock in 状态切换（Legion）：普通 `TODO` 任务在 clock in 后自动变 `NEXT`；若对 `NEXT` 项目节点 clock in 会回到 `TODO`
- 完成日志：写入 `LOGBOOK`
- Agenda 打开后自动移动到右侧
- Capture 模板（`<Leader>X`）已扩展为多类型：
  - `t` Todo（inbox 到 `refile.org`）
  - `r` Respond（NEXT + 当日 SCHEDULED）
  - `n` Note
  - `m` Meeting
  - `p` Phone call
  - `w` Org protocol（Web 链接快速捕获）
  - `h` Habit（`STYLE=habit` + `REPEAT_TO_STATE=NEXT`）
  - `j` Journal（写入 `diary.org` datetree）
  - Capture 期间会执行 clock handoff：打开模板时暂停当前 clock，完成/取消 capture 后恢复之前 clock
- Clock/punch 状态切换默认只改内存 buffer，不自动写盘（由你手动保存）
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

## 3. org_legion 命令

- `:OrgLegionRefresh`：全量刷新（默认处理 `org_agenda_files` 内全部文件，包含未加载文件）
- `:OrgLegionReload`：重载配置并尝试从 `E_CFG_INVALID` 恢复
- `:OrgLegionCleanupDerivedTags`：清理派生标签 dry-run（默认不写）
- `:OrgLegionCleanupDerivedTags!`：清理派生标签 apply（实际修改内存 buffer）

刷新语义（V1）：

- 规则模式：`approx`
- `mode=precise` 会降级到 `approx` 并给出 warning
- 写回语义：`memory_only`（已加载 buffer 只改内存，不自动写盘）
- 当 `refresh.refresh_unloaded_files = true`（默认）时，`OrgLegionRefresh` 会直接写回未加载文件
- 保存触发刷新后，已加载 buffer 可能再次变脏，需要用户二次保存
- 若将 `refresh.refresh_unloaded_files = false`，未加载文件会计入 `skipped_unloaded`

## 4. 快捷键（完整清单）

### 4.1 基础说明

- 当前配置中 `<Leader>` 为 `<Space>`（空格）
- orgmode 前缀为 `mappings.prefix = "<Leader>o"`，下文中的 `<prefix>` 等价于 `<Leader>o`
- 以下清单基于当前仓库配置与 orgmode 默认映射（已包含本仓库的覆盖项）

### 4.2 仓库自定义（Legion 增强）

- `<Leader>X`：Org Capture（Legion clock handoff，替代默认 `<Leader>oc`）
- `<F12>` / `<Leader>oab`：打开 block agenda
- `<Leader>oan`：打开 NEXT 列表
- `<Leader>oat`：打开 Timeline（日视图）
- `<Leader>oas`：打开 Stuck Projects 列表
- `<Leader>oar`：打开 REFILE 列表
- `<Leader>opI`：Punch In（开启连续记时，并 clock 到默认任务）
- `<Leader>opo`：Clock out 但保持连续（自动回父任务或默认任务）
- `<Leader>opO`：Punch Out（停止连续记时，并 clock out）
- `<Leader>oxi`：对当前条目 clock in（带 Legion TODO/NEXT 自动切换）
- `<Leader>oxo`：对当前条目 clock out（若时长为 `0:00` 自动删除该 CLOCK 行；在 punch 模式下会自动回到父任务或默认任务）
- Agenda 视图中：`I`/`O` 已由本仓库重绑到 Legion clock in/out 实现

### 4.3 全局映射（任意 buffer）

- `<Leader>oa`：打开 agenda prompt

### 4.4 Agenda 视图（`orgagenda`）

- `f` / `b` / `.`：下一跨度 / 上一跨度 / 回到今天
- `vd` / `vw` / `vm` / `vy`：日 / 周 / 月 / 年视图
- `q`：关闭 agenda
- `<CR>` / `<TAB>`：在当前窗口打开条目 / 在分屏打开条目
- `J`：跳转到指定日期
- `r`：重载 org 文件并刷新 agenda
- `t`：切换 TODO 状态
- `I` / `O` / `X` / `R`：clock in / clock out / clock cancel / clock report
- `<Leader>oxj` / `<Leader>oxe`：跳到当前 clock 条目 / 设置 effort
- `<Leader>o,` / `+` / `-`：设置优先级 / 提升优先级 / 降低优先级
- `<Leader>ot`：设置标签
- `<Leader>oid` / `<Leader>ois`：设置 deadline / schedule
- `<Leader>or`：refile
- `<Leader>ona`：add note
- `<Leader>o$` / `<Leader>oA`：archive / 切换 ARCHIVE 标签
- `<Leader>oo`：open at point
- `/`：过滤（category/tag/title）
- `K`：预览当前条目
- `g?`：显示 agenda 帮助

### 4.5 Org 文件视图（`org`）

- `cit` / `ciT`：TODO 前进切换 / 后退切换
- `<Leader>o,` / `ciR` / `cir`：优先级循环 / 提升 / 降低
- `<C-Space>`：切换 checkbox
- `<Leader>o*`：切换标题行/普通行
- `<TAB>` / `<S-TAB>`：局部折叠循环 / 全局折叠循环
- `<<` / `>>`：标题升级 / 降级
- `<s` / `>s`：子树升级 / 降级
- `<Leader><CR>`：上下文插入；当光标在标题行时会改为“respect content”模式（新标题插到当前 subtree 之后）
- `<Leader>oih`：在当前 subtree 之后插入同级 headline
- `<Leader>oiT`：插入 TODO headline（紧随当前 headline）
- `<Leader>oit`：在当前 subtree 之后插入 TODO headline
- `<Leader>oK` / `<Leader>oJ`：子树上移 / 下移
- `}` / `{`：下一个 / 上一个可见 headline
- `]]` / `[[`：同级下一个 / 同级上一个 headline
- `g{`：跳到父 headline
- `cid`：通过日历修改光标下日期
- `<S-Up>` / `<S-Down>`：日期按天增减
- `<C-a>` / `<C-x>`：光标下时间戳字段增减
- `<Leader>oid` / `<Leader>ois`：设置 deadline / schedule
- `<Leader>oi.` / `<Leader>oi!`：插入活动 / 非活动时间戳
- `<Leader>od!`：切换活动/非活动时间戳类型
- `<Leader>oli` / `<Leader>ols`：插入链接 / 存储链接
- `<Leader>oo`：打开光标下链接或日期
- `<Leader>or`：refile 当前 headline
- `<Leader>ona`：add note
- `<Leader>oe` / `<Leader>obt`：导出 / tangle
- `<Leader>oxi` / `<Leader>oxo` / `<Leader>oxq` / `<Leader>oxj` / `<Leader>oxe`：clock in / clock out / clock cancel / clock goto / set effort
- `<Leader>o$` / `<Leader>oA`：archive subtree / 切换 ARCHIVE 标签
- `<Leader>o`：edit special（编辑 src block 等）
- `g?`：显示 org 帮助
- 插入模式 `<CR>`：org return

### 4.6 Capture 窗口

- `<C-c>`：finalize（保存并关闭）
- `<Leader>or`：refile 到指定位置
- `<Leader>ok`：kill（不保存关闭）
- `g?`：显示 capture 帮助
- refile 输入框已切换到 `vim.ui.input`（snacks input），可用 `<Tab>`/`<C-n>` 看补全候选

### 4.7 Closing Note 窗口

- `<C-c>`：finalize note
- `<Leader>ok`：kill note

### 4.8 Edit Src 窗口

- `<Leader>ow`：保存修改到原 org buffer
- `<Leader>o`：保存并退出 edit src
- `<Leader>ok`：放弃修改并退出
- `g?`：显示 edit src 帮助

### 4.9 Text Objects

- `ih` / `ah`：inner/around heading
- `ir` / `ar`：inner/around subtree
- `Oh` / `OH`：从 root 选择 inner/around heading
- `Or` / `OR`：从 root 选择 inner/around subtree

### 4.10 兼容与替换说明

- 默认 `<Leader>oc`（org capture）已禁用，由 `<Leader>X` 替代
- 默认 org/agenda 的 clock in/out 映射已禁用后重绑到 Legion 实现（按键保持一致）
- 时间线已启用 `org_agenda_time_grid`（daily）；没有具体时分的条目不会占用时间槽

## 5. 推荐日常流程

1. 上班后 `<Leader>opI` 进入连续记时。
2. `<Leader>oab` 打开 block agenda。
3. 对具体任务执行 clock in。
4. 完成当前任务时使用 `<Leader>opo`，优先保持连续 clock。
5. 午休或下班 `<Leader>opO` 结束连续记时。
6. 需要统一更新派生标签时执行 `:OrgLegionRefresh`。

## 6. 回滚与 cleanup

当需要回滚派生标签副作用时：

1. 先停用 `org_legion.setup`（或临时 `enabled = false`）。
2. 执行 `:OrgLegionCleanupDerivedTags` 查看 dry-run 结果。
3. 确认后执行 `:OrgLegionCleanupDerivedTags!` 应用清理。
4. 保存受影响 buffer。

说明：cleanup 仅清理 `PROJECT/STUCK/ARCHIVE_CANDIDATE` 派生标签，不会删除用户标签。

## 7. 排错

### 7.1 `:OrgLegionRefresh` 后统计里 `skipped_unloaded` 很高

通常是 `refresh.refresh_unloaded_files = false` 或文件不可写导致；默认配置下该值应较低。

### 7.2 提示 `E_CONFLICT_STALE_SNAPSHOT`

说明刷新事务期间 `changedtick` 或 `mtime` 发生变化，系统放弃写回以避免覆盖新改动。重新执行刷新即可。

### 7.3 `E_CFG_INVALID`（进入错误态）

检查配置是否合法（例如 `todo.next` 必须属于 `todo.active`，`writeback` 必须是 `memory_only`），修复后执行 `:OrgLegionReload`。

### 7.4 `<Leader>opI` 没有 clock 到默认任务

检查是否设置了 `vim.g.org_organization_task_id`，且对应 ID 存在于 `org_agenda_files` 覆盖文件中。

若多个 agenda 文件复用了同一个 `:ID:`，`<Leader>opI` 会优先命中当前 buffer；长期仍建议保持 ID 全局唯一，避免默认任务落到错误文件。

### 7.5 `<Leader>opo` 后没有回父任务

若当前条目向上的祖先里没有 `TODO/NEXT/WAITING/HOLD` 父任务，会回到默认任务，这是预期行为。

### 7.6 clock in 后 agenda 时间线没有出现 time block

这是预期行为：time grid 的“时间块”来自带具体时间的时间戳（如 `SCHEDULED: <... 10:00-11:00>`），不是来自 `CLOCK:` 记录。

- clock 数据会写入 `LOGBOOK`；可在 agenda 中按 `R` 切换 clock report 查看汇总
- 若希望在时间线占位，请给任务设置带时间的 `SCHEDULED`/timestamp

### 7.7 capture 的 CLOCK 记录时长与预期不一致

capture 的时长按“分钟粒度”记录：不足 1 分钟不会写 CLOCK 条目，跨分钟边界会按分钟差写入（例如 `21:32 -> 21:33` 记为 `0:01`）。

## 8. 相关文件

- 配置：`lua/plugins/orgmode.lua`
- Legion 模块：`lua/org_legion/init.lua`
- Punch 实现：`lua/org_punch.lua`

## 9. Parity smoke 覆盖边界

`tests/smoke/run.sh` 已纳入 Legion parity 套件（含 `legion_e2e_integrated_flow`），用于 headless、可重复的行为语义校验。

- MUST（阻断级）：
  - Punch in/out 连续记时与默认任务回落
  - Clock in TODO -> NEXT、Clock in NEXT project -> TODO
  - Punch 模式 clock out 回父任务/默认任务
  - Capture handoff 暂停与恢复、pre-refile 注入非 0:00 CLOCK
  - TODO 触发标签与派生标签 refresh/cleanup 语义
- SHOULD（观测级）：
  - `PROJECT/STUCK` 派生刷新稳定性（跨环境若有波动可单独追踪）
  - orgmode clock API 生命周期一致性（active headline 可观测）
- OUT-OF-SCOPE：
  - Agenda/Capture UI 像素级布局与动画
  - 交互提示文案、帮助窗口内容排序
  - 秒级时间戳格式一致性（仅断言分钟粒度和非 0:00）

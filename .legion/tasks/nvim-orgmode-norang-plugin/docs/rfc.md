# RFC: nvim-orgmode Norang 插件协议规范（org_norang）

- 状态：Draft（修订版，目标 `PASS-WITH-CHANGES`）
- 最近更新：2026-02-07
- Scope：`lua/plugins/orgmode.lua`, `lua/org_punch.lua`, `lua/org_norang/**`, `docs/orgmode-norang-workflow.md`
- 设计真源：本文（实现与测试 MUST 以本文为准）

## 本轮修订说明

- 收敛 `memory_only` 下 `refresh_all` 的边界：V1 仅处理“已加载 buffer”。
- 明确未加载 agenda 文件统一记为 `skipped_unloaded`，且 MUST 不隐式加载文件。
- 统一全量刷新汇总口径为 `total/ok/fail/skipped_conflict/skipped_unloaded` 并补充字段定义。
- 补充测试映射 `T16`，固定“已加载+未加载混合集合”场景的统计稳定断言。

## 摘要（Abstract）

本文定义 `org_norang` 的可实现、可测试、可评审协议：
1) 派生标签 `PROJECT`/`STUCK`/`ARCHIVE_CANDIDATE`；
2) 全量与单文件刷新协议（含并发、重入、冲突与写回语义）；
3) agenda block 扩展；
4) 与 `org_punch` 的兼容契约；
5) 可回滚命令 `OrgNorangCleanupDerivedTags`（dry-run + apply）。

V1 以 `approx` 为唯一 MUST 算法档位；`precise` 降级为 MAY（实验特性）。

## 动机（Motivation）

- 当前已有 Norang-lite：`b/n/r` agenda 与 `org_punch` keep-running。
- 当前缺失：派生标签自动维护、统一刷新协议、并发安全与回滚工具。
- 若无协议约束，会出现口径冲突（规则/配置/测试不一致）、重入写回风险、不可逆数据污染。

## 目标与非目标（Goals & Non-Goals）

### 目标

- G1：以最小侵入方式引入派生标签，并保持正文语义不变。
- G2：定义可恢复的刷新状态机与错误语义。
- G3：保证 `b/n/r` 与 `org_punch` keep-running 不回归。
- G4：提供可回滚路径，允许清理派生标签副作用。
- G5：每条 MUST 条款可映射到测试断言。

### 非目标

- NG1：不实现远程同步、数据库索引、跨设备一致性协议。
- NG2：不重写 `org_punch` 主流程。
- NG3：V1 不要求 `precise` 必须可用。
- NG4：不修改 Scope 外文件。

## 术语（Definitions）

- Agenda Files：`orgmode` 的 `org_agenda_files` 展开后的 `.org` 文件集合。
- Headline Node：以 `*` 开头的标题节点及其 subtree。
- 派生标签：由插件维护的标签，集合为 `derived_tags = {PROJECT, STUCK, ARCHIVE_CANDIDATE}`。
- 用户标签：不在 `derived_tags` 集合中的其它标签。
- `approx`：近似算法，V1 MUST。
- `precise`：精确算法，V1 MAY（实验）。
- 刷新事务（Refresh Tx）：一次对单文件的读取-计算-改写尝试。

## 协议总览（Protocol Overview）

### 初始化

`require("org_norang").setup(opts)` MUST 完成：
- 注册命令 `:OrgNorangRefresh`（全量刷新）；
- 注册命令 `:OrgNorangReload`（错误态恢复）；
- 注册命令 `:OrgNorangCleanupDerivedTags[!]`（`!` 表示 apply，默认 dry-run）；
- 按配置启用 `BufWritePost *.org` 单文件刷新。

### 单文件刷新（保存触发或显式调用）

1. 进入单文件互斥锁。
2. 读取快照：`changedtick` 与文件 `mtime`。
3. 解析 headline/TODO/tag。
4. 依据规则计算派生标签差异。
5. 按写回语义执行（见“并发与写回协议”）。
6. 输出结果（ok/fail + 错误码）。

### 全量刷新（命令触发）

1. 展开 Agenda Files。
2. 在 V1 `memory_only` 下，MUST 仅对“已加载 buffer”执行单文件刷新事务（best-effort）。
3. 对未加载 agenda 文件，MUST 记为 `skipped_unloaded`，且 MUST NOT 隐式加载。
4. 汇总 `total/ok/fail/skipped_conflict/skipped_unloaded`。

## 状态机（State Machine）

状态：
- `S0 Disabled`：未启用或显式关闭。
- `S1 Idle`：可用空闲。
- `S2 RefreshingSingle`：单文件刷新中。
- `S3 RefreshingAll`：全量刷新中。
- `S4 Degraded`：部分失败，但系统可继续服务。
- `S5 Error`：配置或初始化错误，处于错误态。

转移：
- `S0 -> S1`：`setup` 成功。
- `S1 -> S2`：`BufWritePost` 或 `refresh_file`。
- `S1 -> S3`：`:OrgNorangRefresh`。
- `S2 -> S1`：单文件成功。
- `S3 -> S1`：全量全部成功。
- `S3 -> S4`：全量部分失败。
- `S4 -> S3`：用户重试 `:OrgNorangRefresh`。
- `any -> S5`：`E_CFG_INVALID` 或初始化关键失败。
- `S5 -> S1`：用户修复配置后执行 `:OrgNorangReload` 成功（幂等）。
- `S5 -> S5`：继续执行刷新命令，返回 `E_CFG_INVALID` 且不执行刷新。

错误态最小命令集：
- 允许：`:OrgNorangReload`、`:messages`。
- 禁止执行刷新与清理 apply（dry-run MAY 允许，仅做分析不写入）。

## 数据模型（Data Model）

### 派生标签判定

- `PROJECT`：headline 为未完成态，且 subtree 中至少有一个未完成子任务。
- `STUCK`：headline 已是 `PROJECT`，且 subtree 不存在 `todo.next` 状态子任务。
- `ARCHIVE_CANDIDATE`：headline 为完成态，且同时满足：
  - 最后活动时间 `<= today - archive.stale_days`；
  - 最近 `archive.recent_month_window` 月内无活动。

### TODO 状态集合

默认：
- active：`TODO`, `NEXT`, `WAITING`, `HOLD`
- done：`DONE`, `CANCELLED`
- next：`NEXT`

约束：
- `todo.next` MUST 属于 `todo.active`。
- `todo.active` 与 `todo.done` SHOULD 不重叠。

### 配置 Schema

```lua
{
  enabled = true,
  refresh = {
    mode = "approx", -- "approx" | "precise"
    on_buf_write = true,
    debounce_ms = 120,
    writeback = "memory_only", -- V1: MUST 为 memory_only
  },
  derived_tags = {
    project = "PROJECT",
    stuck = "STUCK",
    archive_candidate = "ARCHIVE_CANDIDATE",
  },
  todo = {
    active = { "TODO", "NEXT", "WAITING", "HOLD" },
    done = { "DONE", "CANCELLED" },
    next = "NEXT",
  },
  archive = {
    stale_days = 30,
    recent_month_window = 2,
  },
  observability = {
    notify = true,
    log_level = "info", -- "error" | "warn" | "info" | "debug"
  },
}
```

字段约束：
- `derived_tags.*` MUST 非空且互不相同。
- `archive.stale_days` MUST `>= 1`。
- `archive.recent_month_window` MUST `>= 1`。
- 默认值仅为缺省，规则实现 MUST 读取配置值，不得硬编码 `30/2`。

### 全量刷新汇总字段

- `total`：本次 `refresh_all` 处理的 agenda 文件总数（已加载 + 未加载）。
- `ok`：已加载且刷新成功的文件数。
- `fail`：已加载且刷新失败（非冲突跳过）的文件数。
- `skipped_conflict`：已加载但因 `E_CONFLICT_STALE_SNAPSHOT` 跳过写回的文件数。
- `skipped_unloaded`：未加载 buffer 而被跳过的 agenda 文件数。

一致性约束：`total` MUST 等于 `ok + fail + skipped_conflict + skipped_unloaded`。

## 规则算法

### V1（MUST）：`approx`

- `PROJECT`：按 headline 层级判断“当前 active + 至少一个 active 后代”。
- `STUCK`：`PROJECT` 且 subtree headline 内未发现 `todo.next`。
- `ARCHIVE_CANDIDATE`：done 态 + 满足 `stale_days` 与 `recent_month_window` 双条件。

活动时间来源（approx）：
- SHOULD 识别常见日期格式 `%Y-%m-%d`。
- MAY 忽略复杂时区与稀有语法；忽略时按“无活动”处理并记录 debug。

### V2+（MAY）：`precise`（实验）

- `precise` MAY 实现 `SCHEDULED/DEADLINE/CLOCK` 更完整语法。
- 未实现时，系统 MUST 回退 `approx` 并发出一次 warning，不得失败。

## 并发与写回安全协议

### 单文件互斥与重入

- 同一路径 MUST 使用单文件互斥锁；锁持有期间同文件新请求 MUST 合并为一次尾随重跑（coalesce）。
- 不同文件 MAY 并发，但默认 SHOULD 顺序执行以降低 IO 抖动。

### 冲突检测

每次刷新事务 MUST 在提交前比较：
- buffer `changedtick` 是否仍等于事务开始快照；
- 文件 `mtime` 是否仍等于事务开始快照（对已加载缓冲可选，未加载文件 MUST 校验）。

若任一不一致：
- MUST 放弃写回并返回 `E_CONFLICT_STALE_SNAPSHOT`；
- MUST 不覆盖用户新改动；
- MAY 在全量刷新中记为 `skipped_conflict`。

### 写回语义（V1 决策）

- V1 MUST 使用 `memory_only`：只修改当前 buffer 内存文本，不做自动写盘。
- 因此保存触发后发生标签改写时，buffer MAY 重新变脏，用户可二次保存。
- 系统 MUST 设置内部防重入标记，避免由自身改写再次递归触发刷新。
- `refresh_all` 在 `memory_only` 下 MUST 仅遍历已加载 buffer；对未加载 agenda 文件 MUST 计入 `skipped_unloaded`。
- V1 不提供原子写盘；若未来引入 `atomic_file`，需新增 RFC 修订。

## Agenda 集成

`org_agenda_custom_commands.b` 扩展：
- `Stuck Projects`: `type = "tags_todo"`, `match = "PROJECT+STUCK"`
- `Projects`: `type = "tags_todo"`, `match = "PROJECT-STUCK"`
- `Archive Candidates`: `type = "tags"`, `match = "ARCHIVE_CANDIDATE"`

兼容要求：
- 现有 `Refile/Today/Next/Waiting/Hold` blocks MUST 继续可用。
- 现有 `b/n/r` 入口语义 MUST 不变（仅新增可见块，不移除既有块）。

## 与 `org_punch` 协作

- `org_norang` MUST 不调用 `org_punch` 私有实现。
- 协作边界为“共享 TODO 语义 + agenda 可见性”。
- `org_punch` keep-running 主流程 MUST 不因启用 `org_norang` 而改变。
- 若 TODO 语义未对齐，系统 MAY 告警，但 MUST 不阻断 punch。

## 标签改写规范与幂等

- 仅改写 headline 标签区；正文、属性抽屉、日志行 MUST 不改动。
- 标签集合 MUST 去重。
- 对派生标签采用字典序稳定排序；用户标签保持原相对顺序。
- 清理动作仅能删除 `derived_tags.*`，MUST 不删除用户标签。
- 对同一文件连续执行两次刷新，在无外部修改时第二次 MUST 产生空 diff。

## 错误语义（Error Semantics）

错误码：
- `E_CFG_INVALID`：配置非法（不可恢复，需修复配置）。
- `E_FILE_UNREADABLE`：文件不可读（可恢复，跳过）。
- `E_PARSE_HEADLINE`：解析失败（可恢复，当前文件失败）。
- `E_CONFLICT_STALE_SNAPSHOT`：快照冲突（可恢复，跳过写回）。
- `E_WRITE_FAILED`：内存改写失败（可恢复，当前文件失败）。
- `E_RUNTIME_INTERNAL`：未预期异常（可恢复，当前文件失败）。

重试语义：
- `E_FILE_UNREADABLE`/`E_PARSE_HEADLINE`/`E_WRITE_FAILED`/`E_RUNTIME_INTERNAL`：MAY 下次刷新重试。
- `E_CONFLICT_STALE_SNAPSHOT`：SHOULD 以最新缓冲重跑一次。
- `E_CFG_INVALID`：MUST 修复配置后执行 `:OrgNorangReload`。

## 安全考虑（Security Considerations）

- 输入校验：MUST 校验配置类型、标签名与路径。
- 权限边界：MUST 仅处理 Agenda Files 中 `.org` 文件。
- 资源耗尽：SHOULD 使用 debounce、重入合并与分批刷新。
- 滥用防护：MAY 设定单次全量最大文件数并告警。
- 数据安全：MUST 不执行外部 shell 命令。

## 向后兼容与发布（Backward Compatibility & Rollout）

迁移：
1. 阶段 1：启用 `org_norang`，默认 `mode=approx`。
2. 阶段 2：启用 agenda 新 blocks。
3. 阶段 3：补充文档与验收脚本。

灰度：
- 先开 `on_buf_write`，再推广 `:OrgNorangRefresh` 到全库。

回滚：
1. 关闭 `org_norang.setup` 与新增 blocks。
2. 执行 `:OrgNorangCleanupDerivedTags`（dry-run 确认后 apply）。
3. 验证仅派生标签被清理，用户标签保留。

## 可测试性（Testability）

### 规范性条款

- R1：系统 MUST 提供 `:OrgNorangRefresh`。
- R2：系统 MUST 提供 `:OrgNorangReload`。
- R3：系统 MUST 提供 `:OrgNorangCleanupDerivedTags`（默认 dry-run，`!` 为 apply）。
- R4：`BufWritePost *.org` MUST 触发单文件刷新（可配置关闭）。
- R5：刷新 MUST 仅改 headline 标签区。
- R6：`PROJECT` MUST 按“active 且含 active 子任务”判定。
- R7：`STUCK` MUST 按“PROJECT 且无 `todo.next` 子任务”判定。
- R8：`ARCHIVE_CANDIDATE` MUST 同时满足 done + `stale_days` + `recent_month_window`。
- R9：V1 MUST 支持 `approx`；`precise` MAY 存在，缺失时 MUST 回退 `approx`。
- R10：同文件刷新 MUST 使用单文件锁并具备重入合并语义。
- R11：刷新提交前 MUST 进行 `changedtick/mtime` 冲突检测。
- R12：V1 写回 MUST 为 `memory_only`，且 MUST 防止递归重入。
- R13：全量刷新 MUST 输出 `total/ok/fail/skipped_conflict/skipped_unloaded` 汇总，且满足守恒关系。
- R14：部分文件失败 MUST 不阻断其它文件刷新。
- R15：agenda 扩展 MUST 包含 `PROJECT+STUCK`、`PROJECT-STUCK`、`ARCHIVE_CANDIDATE`。
- R16：现有 `b/n/r` 输出结构 MUST 不回归。
- R17：`org_punch` keep-running 主流程 MUST 不回归。
- R18：标签改写 MUST 去重且幂等（二次 refresh 无 diff）。
- R19：`E_CFG_INVALID` 时系统 MUST 进入 `S5` 且仅允许恢复命令。
- R20：修复配置后执行 `:OrgNorangReload` MUST 可从 `S5` 回到 `S1`。
- R21：文档 MUST 覆盖命令、错误、回滚、兼容验证步骤。

### 测试映射

- T1 -> R1：执行 `:OrgNorangRefresh`，验证汇总输出。
- T2 -> R2/R20：构造非法配置进入 `S5`，修复后 `:OrgNorangReload` 恢复到 `S1`。
- T3 -> R3：`cleanup` dry-run 不改文件，`cleanup!` 仅删派生标签。
- T4 -> R4/R5：保存单文件，确认只改标签区。
- T5 -> R6/R7：构造含/不含 `NEXT` 子任务树，验证 `PROJECT/STUCK`。
- T6 -> R8：调整 `stale_days/recent_month_window`，验证候选标签变化。
- T7 -> R9：配置 `mode=precise` 且未实现时，验证回退 `approx` 与 warning。
- T8 -> R10/R12：高频保存同一文件，确认无递归风暴与重入错写。
- T9 -> R11/R13/R14：制造 `changedtick/mtime` 冲突，确认 `skipped_conflict` 统计。
- T10 -> R15：`agenda b` 中三类新增视图可见且可筛选。
- T11 -> R16：启用/禁用 `org_norang` 前后对比 `b/n/r` 既有块与行为一致。
- T12 -> R17：启用 `org_norang` 后执行 punch in/out keep-running，行为与旧版一致。
- T13 -> R18：同文件连续 refresh 两次，第二次无 diff。
- T14 -> R19：`S5` 状态下刷新命令被拒并返回 `E_CFG_INVALID`。
- T15 -> R21：按文档完成一次“启用-运行-回滚-清理”闭环。
- T16 -> R12/R13：构造“已加载+未加载”混合集合执行 `refresh_all`，验证仅已加载文件被处理、未加载文件记为 `skipped_unloaded`，且汇总守恒稳定。

## 开放问题（Open Questions）

- Q1：`precise` 的语法覆盖边界（`SCHEDULED/DEADLINE/CLOCK` 细则）是否在下一版本纳入 MUST？
- Q2：全量刷新是否需要新增 `fail_fast` 策略（当前仅 best-effort）？

## Plan

### 核心流程

1. 在 `orgmode` 启动路径接入 `org_norang.setup`。
2. 注册 `Refresh/Reload/Cleanup` 三类命令与 `BufWritePost`。
3. 以单文件锁 + 快照冲突检测执行刷新事务。
4. 以派生标签驱动 agenda 扩展，并保持 `b/n/r` 与 punch 不回归。

### 接口定义

- `require("org_norang").setup(opts)`
- `require("org_norang").refresh_all()`
- `require("org_norang").refresh_file(path_or_bufnr)`
- `require("org_norang").reload()`
- `require("org_norang").cleanup_derived_tags({ apply = false })`

### 文件变更明细（设计范围）

- `lua/org_norang/init.lua`：配置、命令、autocmd、状态管理。
- `lua/org_norang/parser.lua`：headline/TODO/tag 解析。
- `lua/org_norang/rules.lua`：派生标签判定。
- `lua/org_norang/refresh.lua`：刷新事务、锁、冲突检测、汇总。
- `lua/org_norang/cleanup.lua`：派生标签清理（dry-run/apply）。
- `lua/plugins/orgmode.lua`：接入 setup 与 agenda blocks。
- `lua/org_punch.lua`：仅协同校验，不改主流程。
- `docs/orgmode-norang-workflow.md`：命令、排错、回滚与验收说明。

### 验证策略

- 以 R1-R21 为唯一验收清单，逐条映射 T1-T15。
- 优先验证 blocking 相关条款：R8-R12、R16-R20。
- 明确“二次 refresh 无 diff”与“cleanup 可逆”为发布前门禁。

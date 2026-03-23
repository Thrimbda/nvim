# RFC: nvim-orgmode Legion 对齐审计协议（Alignment Audit Protocol）

## Abstract

本文定义可实现、可测试、可评审的 A/B/C 三基线对齐审计协议，用于回答：当前实现是否与 task 记录一致，且与 Legion 原文一致。RFC 产出差异矩阵、证据链、可执行门禁与最小计划；RFC 为后续执行唯一设计真源。

## Motivation

- 历史实现已迭代多轮，Baseline B（三文件）存在时序混杂，出现“实现与记录不同步”。
- 现有 RFC 评审结论为 FAIL，主要问题是判级过乐观、C 证据不可复现、门禁不可执行。
- 需要先收敛审计协议与证据，再决定是否进入实现修复。

## Goals & Non-Goals

### Goals

- G1: MUST 基于 Baseline A/B/C 并行比对给出结论。
- G2: MUST 覆盖 8 个审计主题域并形成差异矩阵。
- G3: MUST 对每个涉及 C 的矩阵项提供可复现证据（URL + 1-3 行原文摘录）。
- G4: MUST 给出可执行 Design Gate，含通过阈值、blocking 清零标准、回滚触发条件。

### Non-Goals

- NG1: 本 RFC 不修改业务代码。
- NG2: 本 RFC 不改写 Legion 原文，只做语义映射。
- NG3: 本 RFC 不替代完整功能验收，仅定义审计协议与收敛门禁。

## Definitions

- `Baseline A`: 当前仓库实现与本地文档事实（代码优先）。
- `Baseline B`: `.legion/tasks/nvim-orgmode-legion-implementation/{plan.md,context.md,tasks.md}`。
- `Baseline C`: Legion 原文 `skills/legion-workflow/references/orgmode-legion-workflow.md`。
- `一致`: 语义与可观测行为无实质冲突。
- `部分一致`: 主语义一致，但机制或覆盖面有差异。
- `不一致`: 核心行为冲突或证据不足以支撑原判级。

## Protocol Overview

端到端流程：

1. 收集 A/B/C 证据并固定路径。
2. 归一到 8 个主题域。
3. 逐域判级并附证据。
4. 生成不一致清单与 Open Questions。
5. 执行 Design Gate 判定 PASS/FAIL。

行为条款：

- R1: 审计 MUST 并行使用 A/B/C，不得缺任一基线。
- R2: 每条域结论 MUST 至少包含 1 条 A 证据路径。
- R3: 每条“不一致”结论 MUST 至少包含 1 条 B 或 C 证据路径。
- R4: 差异矩阵 MUST 覆盖 8 个主题域。
- R5: 判级 SHOULD 区分语义差异与实现机制差异。
- R6: 证据不足项 MUST 进入 Open Questions，不得硬判。

## State Machine

状态：`S0_INIT` -> `S1_COLLECT` -> `S2_NORMALIZE` -> `S3_COMPARE` -> `S4_CLASSIFY` -> `S5_DRAFT` -> `S6_GATE_READY`。

异常态：`S_ERR_NEED_INFO`。

- R7: `S0_INIT -> S1_COLLECT` MUST 在路径可访问时触发。
- R8: `S1_COLLECT -> S_ERR_NEED_INFO` MUST 在关键证据缺失时触发，并写入 `context.md`。
- R9: `S1_COLLECT -> S2_NORMALIZE` MUST 在 A/B/C 均具备最小证据后触发。
- R10: `S2_NORMALIZE -> S6_GATE_READY` MUST 严格按序，不得跳步。

## Data Model

### 审计主题域

```text
AuditDomain = {
  todo_flow,
  capture_handoff,
  custom_agenda,
  punch_default,
  stuck_rule,
  time_grid_timeline,
  memory_only_writeback,
  tests_ci
}
```

### 差异矩阵结构

```text
DiffRow {
  domain: AuditDomain,                  # MUST
  status: "一致"|"部分一致"|"不一致",   # MUST
  summary: string,                      # MUST
  evidenceA: [path:line],               # MUST >=1
  evidenceB: [path:line],               # SHOULD
  evidenceC: [url + 1..3 quote lines],  # 涉及 C 时 MUST
  decision: string                      # MUST
}
```

- R11: 对 C 未定义维度（如 CI）MAY 标注“工程增强”，但 MUST 明确“不参与 A/C 正负判级”。
- R12: 当 B 内部冲突时，MUST 先记录冲突，再以“最新可验证事实”判级。

## Error Semantics

错误码：

- `A_EVIDENCE_MISSING`: 关键证据缺失。
- `A_SCOPE_VIOLATION`: 使用 scope 外证据影响结论。
- `A_BASELINE_CONFLICT`: 同一基线内部冲突。
- `A_CLASSIFY_UNCERTAIN`: 证据不足无法判级。

- R13: `A_EVIDENCE_MISSING` SHOULD 补证重试；仍缺失 MUST 转 Open Questions。
- R14: `A_BASELINE_CONFLICT` MUST 记录冲突双方路径与取舍理由。
- R15: `A_CLASSIFY_UNCERTAIN` MUST 降级，不得继续给出确定性结论。

## Security Considerations

- R16: 输入 MUST 视为不可信文本；禁止拼接执行。
- R17: 证据引用 MUST 使用只读路径或公开 URL；不得包含凭证。
- R18: 读取大文件 SHOULD 采用分段策略，避免资源耗尽。
- R19: 所有 C 引用 MUST 绑定 URL 与原文摘录，防止二手转述漂移。

## Backward Compatibility & Rollout

- R20: 本 RFC 仅定义审计协议，不改运行时代码。
- R21: 收敛顺序 SHOULD 先“记录收敛”，后“实现调整”。
- R22: 任一域回归为不一致时 MUST 触发回滚到“记录收敛”阶段。

## 差异矩阵（A/B/C）

| 主题域 | 结论 | 说明 | 关键证据 |
|---|---|---|---|
| TODO 流程与状态触发 | 部分一致 | A 已实现 `TODO->NEXT` 与 `NEXT(project)->TODO`；但未见 C 中 TODO state tag triggers 全量落地。 | A: `lua/org_punch.lua:315`, `lua/plugins/orgmode.lua:43`；C: URL `skills/legion-workflow/references/orgmode-legion-workflow.md`，摘录: "Moving a task to WAITING adds a WAITING tag" / "Moving a task to HOLD adds WAITING and HOLD tags" / "Moving a task to NEXT removes WAITING, CANCELLED, and HOLD tags" |
| Capture 模板与 clock handoff | 部分一致 | A 有 `t/r/n/m/p/j` 与 handoff；C 还含 `h/w`，且强调 `:clock-in t :clock-resume t`。 | A: `lua/plugins/orgmode.lua:62`, `lua/org_capture_legion.lua:221`；C: URL `skills/legion-workflow/references/orgmode-legion-workflow.md`，摘录: "A new habit (h)" / "(\"w\" \"org-protocol\" entry" / "Capture mode now handles automatically clocking in and out ... :clock-in t ... :clock-resume t" |
| Custom Agenda（Stuck/Projects/Standalone/Archive） | 一致 | A 已提供 block 视图并覆盖 Stuck/Projects/Standalone/Archive。 | A: `lua/plugins/orgmode.lua:95`；C: URL `skills/legion-workflow/references/orgmode-legion-workflow.md`，摘录: "Single block agenda shows the following" / "Finding stuck projects" / "Findings tasks to be archived" |
| Punch in/out 与默认任务机制 | 一致 | A 有默认任务与 punch in/out，clock out 回父任务或默认任务语义。 | A: `lua/org_punch.lua:557`, `lua/org_punch.lua:622`；C: URL `skills/legion-workflow/references/orgmode-legion-workflow.md`，摘录: "I now use the concept of punching in and punching out" / "This clocks in a predefined task by org-id" / "clocking out automatically clocks time on a parent task or moves back to the predefined default task" |
| Stuck project 判定规则 | 一致 | A 的 STUCK 判定与 C 的 project/stuck 方向一致。 | A: `lua/org_legion/rules.lua:103`；C: URL `skills/legion-workflow/references/orgmode-legion-workflow.md`，摘录: "Only projects get tasks with NEXT keywords" / "stuck projects initiate the need for marking or creating NEXT tasks" |
| time grid 与 timeline | 部分一致 | A 有 daily time grid 与 `agenda t`；C 强调 time-grid 但未定义独立 timeline 命令。 | A: `lua/plugins/orgmode.lua:36`, `lua/plugins/orgmode.lua:159`；C: URL `skills/legion-workflow/references/orgmode-legion-workflow.md`，摘录: "If I want just today's calendar view then F12 a is still faster" / "especially if I want to view a week or month's worth of information, or check my clocking data" |
| memory_only 与自动写盘语义 | 不一致 | A 存在 memory-only 与未加载文件写回并存；B 记录也冲突，语义未收敛。 | A: `lua/plugins/orgmode.lua:272`, `lua/org_legion/refresh.lua:242`；B: `context.md:145`, `context.md:149` |
| tests_ci | 不一致（验证不足） | 现有可追溯证据主要是 `luafile` 最小校验；不足以证明 R* MUST 条款均被执行验证。 | A: `.github/workflows/org-smoke.yml:1`, `tests/smoke/run.sh:1`；B: `.legion/tasks/nvim-orgmode-legion-implementation/docs/test-report.md:15` |

## Task 记录与实现不一致点（B vs A）

以下冲突 MUST 先记录收敛，再做判级升级：

1. 进度字段冲突
   - 现状：审计时曾出现“6/6 完成”与“阶段 3 IN PROGRESS”并存；本轮已收敛为 `阶段 3 ✅ COMPLETE`。
   - 证据：历史问题记录见 `.legion/tasks/nvim-orgmode-legion-implementation/docs/rfc-review.md:19`；收敛后状态见 `.legion/tasks/nvim-orgmode-legion-implementation/tasks.md:26`。

2. walkthrough 的 RFC 路径错误
   - 现状：报告引用 `.legion/tasks/nvim-orgmode-legion-plugin/docs/rfc.md`，与当前 task id 不一致。
   - 证据：`.legion/tasks/nvim-orgmode-legion-implementation/docs/report-walkthrough.md:9`。

3. `tasks.md` 尾部时间戳损坏
   - 现状：审计时存在尾部孤立行时间戳损坏；本轮已修复为单一 `最后更新` 行。
   - 证据：历史问题记录见 `.legion/tasks/nvim-orgmode-legion-implementation/docs/rfc-review.md:21`；修复后见 `.legion/tasks/nvim-orgmode-legion-implementation/tasks.md:77`。

4. memory_only 历史口径冲突
   - 现状：B 同时存在“仅已加载”与“可处理未加载文件”两种叙述。
   - 证据：`.legion/tasks/nvim-orgmode-legion-implementation/context.md:145`、`.legion/tasks/nvim-orgmode-legion-implementation/context.md:149`。

## Testability

### R* 条款断言映射（tests_ci 判级依据）

| 条款 | 已测/未测 | 证据路径 |
|---|---|---|
| R1 | 未测 | 仅有文档声明，缺少自动化断言：`.legion/tasks/nvim-orgmode-legion-implementation/docs/rfc.md` |
| R2 | 未测 | 缺少“每条结论绑定 A 证据”的 CI 校验脚本 |
| R3 | 未测 | 缺少“不一致项必须含 B/C 证据”的自动检查 |
| R4 | 已测（静态） | 本 RFC 差异矩阵含 8 域；证据：`.legion/tasks/nvim-orgmode-legion-implementation/docs/rfc.md` |
| R5 | 未测 | 无判级一致性 lint/规则校验 |
| R6 | 未测 | 无 Open Questions 覆盖率检查 |
| R7 | 未测 | 无状态机入口自动化用例 |
| R8 | 未测 | 无 `S_ERR_NEED_INFO` 触发回归用例 |
| R9 | 未测 | 无“三基线最小证据”门槛测试 |
| R10 | 未测 | 无状态迁移顺序断言 |
| R11 | 未测 | 无“工程增强”分类自动判定 |
| R12 | 未测 | 无 B 冲突优先级判定测试 |
| R13 | 未测 | 无补证重试/转 Open Questions 测试 |
| R14 | 未测 | 无冲突双方路径记录断言 |
| R15 | 未测 | 无“证据不足禁止硬判”断言 |
| R16 | 未测（仅人工） | 缺少文档安全 lint；当前仅人工审阅 |
| R17 | 未测（仅人工） | 缺少 URL/路径白名单校验 |
| R18 | 未测 | 缺少大文件资源耗尽测试 |
| R19 | 已测（静态） | 本 RFC 已给出 C 的 URL+摘录；证据：本节上方矩阵 |
| R20 | 已测（静态） | 本次仅改文档与 task 三文件，未改业务代码 |
| R21 | 未测 | 无“先记录收敛后实现”流水线检查 |
| R22 | 未测 | 无“回归触发回滚”自动化检测 |

结论：`tests_ci` 当前 MUST 判为“不一致（验证不足）”，禁止升级为“部分一致”。

## Open Questions

1. `memory_only` 是否应拆分为 `buffer_only` 与 `refresh_unloaded_files` 两个显式策略名？
2. `time_grid` 与 `timeline` 的关系是否需要在产品语义上硬分层（同命令/异命令）？
3. 是否要补充一份机器可读规则文件（例如 `docs/audit-rules.json`）来执行 R1-R22 自动判定？
4. 对 `tests_ci`，是否将“静态审计”与“运行时验证”拆成两级门禁并分别出具 PASS 条件？

## Plan

### 核心流程

- P1: 锁定本 RFC 为审计唯一设计真源，先清理记录冲突。
- P2: 对 8 个域按 A/B/C 重新判级，证据不足统一进 Open Questions。
- P3: 仅当门禁 PASS 后，才允许进入后续实现阶段。

### 接口定义

- 输入 Envelope MUST 包含：`taskId/repoRoot/taskRoot/scope/docsDir/rfcPath`。
- 输出 SHOULD 包含：`rfc.md` 与审计报告（`review-code.md/review-security.md/test-report.md/report-walkthrough.md`）。
- 本轮 MAY 仅输出文档收敛，不触发业务代码变更。

### 文件变更明细

- 更新：`.legion/tasks/nvim-orgmode-legion-implementation/docs/rfc.md`
- 更新：`.legion/tasks/nvim-orgmode-legion-implementation/plan.md`
- 更新：`.legion/tasks/nvim-orgmode-legion-implementation/tasks.md`
- 更新：`.legion/tasks/nvim-orgmode-legion-implementation/context.md`

### 验证策略

- V1: 结构完整性（强制章节齐全）。
- V2: 条款可追溯（R1-R22 全部入表）。
- V3: 证据可复现（C 项必须 URL+摘录）。
- V4: 门禁可执行（阈值可计算，结果可判定）。

## Design Gate Checklist（可执行）

- Gate-1 证据完整率阈值：MUST >= 90%。计算口径为 `具备完整证据的域数/总域数`，完整证据定义为 A 必有，且若判“不一致”则 B/C 至少其一存在。
- Gate-2 阻塞项清零：MUST `blocking=0` 才可 PASS；任一 blocking 未关闭即 FAIL。
- Gate-3 回滚触发：任一域从“已一致/部分一致”回归到“不一致”或“证据不足”时，MUST 回退到“记录收敛”阶段（更新 task 三文件与矩阵后重新评审）。

当前判定：

- [x] RFC 生成完成
- [x] 对抗审查 PASS（见 `.legion/tasks/nvim-orgmode-legion-implementation/docs/rfc-review.md`）
- [x] Design Approved（用户在当前会话明确要求进入实现阶段）

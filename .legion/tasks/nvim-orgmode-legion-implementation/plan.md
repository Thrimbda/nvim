# nvim-orgmode-legion-implementation

TITLE: 对齐审计 RFC（Legion / Task / Implementation）
SLUG: orgmode-legion-alignment-audit-rfc

## 目标

围绕用户问题“现有实现是否与 task 记录及 Legion 原文一致”产出可评审 RFC，并作为后续执行唯一设计真源。

## 设计真源

- RFC: `.legion/tasks/nvim-orgmode-legion-implementation/docs/rfc.md`
- 任何后续实现或文档收敛 MUST 以该 RFC 条款（R1-R22）为准，不得绕过 Design Gate。

## 摘要

- 核心流程
  - 采用 A/B/C 三基线审计协议：收集证据 -> 8 域比对 -> 差异矩阵 -> 可执行门禁判定。
- 接口变更
  - 无运行时代码接口变更；仅新增审计协议输入/输出约束（Envelope + 报告产物）。
- 文件变更清单
  - 更新 RFC；同步收敛 task 三文件（plan/tasks/context）并修复记录冲突。
- 验证策略
  - 每条 MUST 条款映射“已测/未测 + 证据路径”；C 证据强制 URL + 原文摘录。

## 范围

- lua/plugins/orgmode.lua
- lua/org_punch.lua
- lua/org_capture_legion.lua
- lua/org_legion/**
- lua/config/options.lua
- lua/plugins/snacks.lua
- lua/tests/smoke/orgmode_smoke.lua
- tests/smoke/run.sh
- skills/legion-workflow/references/orgmode-legion-workflow.md
- .legion/tasks/nvim-orgmode-legion-implementation/{plan.md,context.md,tasks.md}
- .legion/tasks/nvim-orgmode-legion-implementation/docs/rfc.md

---

*创建于: 2026-02-08 | 最后更新: 2026-03-01 13:20*

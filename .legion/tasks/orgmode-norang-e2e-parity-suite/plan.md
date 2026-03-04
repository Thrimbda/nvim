# orgmode-norang-e2e-parity-suite

## 目标

设计并落地一个端到端测试套件，覆盖 norang 原文的关键行为并验证当前实现与 orgmode/orgmode.nvim 语义一致。

## 要点

- 基于 Norang 原文提炼 MUST 行为并映射到可执行断言
- 结合上游 orgmode/orgmode.nvim 能力边界，避免测试断言超出真实语义
- 在现有 smoke 框架中新增端到端用例与执行入口
- 产出可直接用于 PR 的说明文档

## 范围

- lua/tests/smoke/orgmode_smoke.lua
- tests/smoke/run.sh
- docs/orgmode-norang-workflow.md
- lua/org_punch.lua
- .legion/tasks/orgmode-norang-e2e-parity-suite/**

## 阶段概览

1. **阶段 0: 任务澄清与风险分级** - 2 个任务
2. **阶段 1: 设计与对抗审查** - 2 个任务
3. **阶段 2: 实现** - 1 个任务
4. **阶段 3: 验证与评审** - 2 个任务
5. **阶段 4: 报告** - 1 个任务

---

*创建于: 2026-03-04 | 最后更新: 2026-03-04*

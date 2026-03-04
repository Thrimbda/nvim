# 任务简报：Norang Workflow AI Skill

## 问题定义

仓库已有面向人的 Norang 工作流文档（`docs/orgmode-norang-workflow.md`），但缺少面向 AI agent 的可执行说明和可复用 skill 入口，导致后续协作中重复解释成本高、执行口径不一致。

本任务目标是将既有工作流规则产品化为项目根目录下的 skill，并补齐端到端交付产物（测试/评审/报告/PR body）。

## 验收标准

- 在项目根目录新增 `skills/norang-workflow/SKILL.md`，可直接作为 AI 执行说明。
- Skill 内容覆盖：前置检查、核心命令与快捷键、日常操作流程、回滚策略、排错清单、边界与禁区。
- Skill 明确“事实来源优先级”：以 `docs/orgmode-norang-workflow.md` 为真源，避免与现有实现冲突。
- 生成任务产物：
  - `docs/test-report.md`
  - `docs/review-code.md`
  - `docs/report-walkthrough.md`
  - `docs/pr-body.md`

## 前提假设

- `docs/orgmode-norang-workflow.md` 与当前仓库实现保持一致，可作为本任务事实来源。
- 本任务不修改核心运行时代码，仅新增/整理文档与 skill 资产。
- 受权限策略限制，无法直接加载 `skill-creator`，改为按既有 skill 规范手工落盘。

## 风险 / 规模 / 标签

- 风险：**Low**
- 规模：**非 Epic**
- 标签：`continue`

### 原因

- 变更范围集中在新增文档和 skill，不涉及运行时代码路径或外部合约。
- 失败可通过删除新增文件快速回滚，且不影响现有功能。
- 与已有 Norang 任务存在上下文连续性，采用 `continue` 标签标记。

## 验证计划

1. 检查 skill 文件结构与引用路径正确。
2. 由 `run-tests` 产出 `docs/test-report.md`（文档型变更以结构校验/可读性校验为主）。
3. 由 `review-code` 产出 `docs/review-code.md`，确认内容准确性与可维护性。
4. 由 `report-walkthrough` 产出交付总结与 PR body。

## 已知风险

- 若上游工作流文档后续变更，skill 可能出现语义漂移；需在后续任务中同步更新。
- AI 执行场景差异较大，部分按键/命令需保留“环境前提”说明，避免误用。

## 外部参考

- Norang workflow 说明：`docs/orgmode-norang-workflow.md`
- 相关实现：`lua/org_punch.lua`、`lua/org_capture_norang.lua`

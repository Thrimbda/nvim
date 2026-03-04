# 交付 Walkthrough：Norang Workflow AI Skill

## 目标与范围

- 目标：将既有 Norang 工作流文档产品化为 AI 可执行 skill，降低重复解释和执行口径偏差。
- 绑定 scope：`skills/norang-workflow/**` 与本任务文档产物，未触及运行时代码路径（如 `lua/**`）。
- 本次交付类型：Low 风险、文档型变更。

## 设计摘要

- 设计依据：`./.legion/tasks/norang-workflow-ai-skill/docs/design-lite.md`。
- 事实来源优先级：以 `docs/orgmode-norang-workflow.md` 为主真源，skill 作为可执行封装；若冲突以真源为准。
- 关键设计点：
  - 提供 preflight、命令矩阵、标准日常流程、故障恢复、回滚与安全边界。
  - 明确 AI 执行边界（可做/禁做）与人工确认门禁（cleanup apply 前必须明确确认）。
  - 保持最小变更策略：仅新增/完善文档与 skill，不引入功能变更。

## 改动清单（按模块/文件）

### 1) Skill 主文档

- 文件：`skills/norang-workflow/SKILL.md`
- 改动内容：
  - 新增 AI-facing 操作说明，覆盖 Source of truth、Scope and goals、Preflight checks。
  - 补齐 Command and key matrix（Punch/Clock/Capture/Agenda）与标准流程（start/during/end of day）。
  - 增加 Troubleshooting、Rollback and safety boundaries、Execution boundaries。
  - 对齐评审建议：明确 `<Leader>oc` 禁用、cleanup apply 需 explicit user confirmation、capture 分钟粒度说明。

### 2) 高频运行清单

- 文件：`skills/norang-workflow/references/quick-checklist.md`
- 改动内容：
  - 新增紧凑 runbook（Before start / Daily sequence / Recovery sequence）。
  - 恢复序列中强调先 dry-run，再在用户明确确认后执行 apply。

### 3) 质量与交付文档

- 文件：`./.legion/tasks/norang-workflow-ai-skill/docs/test-report.md`
  - 记录文档型验证结果（PASS）与检查覆盖项。
- 文件：`./.legion/tasks/norang-workflow-ai-skill/docs/review-code.md`
  - 记录代码评审结果（PASS，无 blocking）及非阻塞建议。

## 如何验证

### 验证命令

- 命令（见 test-report）：`python3 - <<'PY' ...`

### 预期结果

- 命令执行结果为 `PASS`。
- `skills/norang-workflow/SKILL.md` 与 `skills/norang-workflow/references/quick-checklist.md` 存在。
- `SKILL.md` 必含关键章节：
  - `## Source of truth`
  - `## Command and key matrix`
  - `## Standard operating flow`
  - `## Rollback and safety boundaries`
  - `## Execution boundaries for AI agents`
- 关键约束文本存在：`<Leader>oc` disabled、`explicit user confirmation`、`Last verified`。

### 证据引用

- 测试报告：`./.legion/tasks/norang-workflow-ai-skill/docs/test-report.md`
- 评审报告：`./.legion/tasks/norang-workflow-ai-skill/docs/review-code.md`

## 风险与回滚

- 风险等级：Low。
- 风险说明：
  - 文档与 skill 资产变更，不影响运行时代码执行路径。
  - 主要风险为后续真源文档变更导致语义漂移。
- 回滚方案：
  1. 删除 `skills/norang-workflow/`。
  2. 删除本任务文档产物（`docs/test-report.md`、`docs/review-code.md`、`docs/report-walkthrough.md`、`docs/pr-body.md`）。
  3. 不需要数据迁移或状态修复。
- 安全评审说明：本任务为 Low 风险文档型交付，不涉及认证、权限、密钥、支付、数据迁移等敏感变更，`review-security` 非必需。

## 未决项与下一步

- 未决项：
  - 评审建议中的长期维护触发条件（真源文档变更时自动提醒更新 skill）可在后续任务增强。
- 下一步：
  1. 使用 `docs/pr-body.md` 直接发起 PR。
  2. Merge 后在后续迭代中考虑增加“真源变化监测 + Last verified 更新策略”。

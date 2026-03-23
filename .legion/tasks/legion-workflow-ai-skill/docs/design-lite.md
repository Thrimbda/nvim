# Design Lite：Legion Workflow AI Skill

## 目标

将现有 Legion 工作流文档压缩为 AI 可执行的 skill 指南，降低重复解释与执行偏差。

## 输入与事实来源

1. 主真源：`skills/legion-workflow/references/orgmode-legion-workflow.md`
2. 交叉参考：`lua/org_punch.lua`、`lua/org_capture_legion.lua`
3. 任务约束：仅在 scope 内新增 skill 资产，不修改运行时代码

## 产出设计

- 新增：`skills/legion-workflow/SKILL.md`
- 内容结构：
  - 适用场景与目标
  - 执行前检查（默认任务 ID、关键配置入口）
  - 核心命令/快捷键映射
  - 推荐日常流程（Punch in -> Agenda -> Clock -> Capture -> Punch out）
  - 常见故障与恢复
  - 回滚策略与边界说明

## 关键决策

- 风险等级为 Low，采用 design-lite，不走 RFC 流程。
- 受权限策略影响，`skill-creator` 无法直接加载，按项目内已有 skill 结构手工编写。
- Skill 只做“执行说明产品化”，不在本任务内扩展新功能。

## 验证策略

- 文档结构完整性检查（章节齐全、路径可解析）。
- 由 `review-code` 检查内容准确性、可维护性与歧义。
- 由 `report-walkthrough` 生成可直接用于 PR 的说明。

## 回滚策略

- 若需回滚，删除 `skills/legion-workflow/` 与本任务 `.legion` 产物即可。

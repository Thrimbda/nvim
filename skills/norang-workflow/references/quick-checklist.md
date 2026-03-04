# Norang 快速检查清单

用于高频场景的紧凑版 runbook。

## 开始前

- 已设置并可解析 `vim.g.org_organization_task_id`。
- `<Leader>` 为 `<Space>`，org 前缀为 `<Leader>o`。
- 本仓库 capture 使用 `<Leader>X>`（`<Leader>oc` 已禁用）。
- 理解状态变更是 memory-first，必要时需要手动保存 buffer。

## 日常顺序

1. `<Leader>opI`（punch in）
2. `<Leader>oab`（block agenda）
3. `I` 或 `<Leader>oxi`（进入目标任务）
4. 被打断时用 `<Leader>X` capture
5. 任务切换用 `<Leader>opo`，收工用 `<Leader>opO`

## 恢复顺序

1. `:OrgNorangReload`（配置/错误态恢复）
2. `:OrgNorangRefresh`（标签/状态对齐）
3. `:OrgNorangCleanupDerivedTags`，随后仅在用户明确确认后执行 `:OrgNorangCleanupDerivedTags!`

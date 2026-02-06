# Code Review Report

## 结论
PASS

## Blocking Issues
- [ ] (none)

## 建议（非阻塞）
- `lua/org_punch.lua:108` - `org_clock_in`/`org_clock_out` 在没有活动时钟或未绑定默认映射时只会回退到按键，可能导致静默失败。建议在 `call_org_action` 失败后检测返回值并提示用户当前时钟状态。
- `lua/org_punch.lua:222` - `clock_out_keep_running` 在无活动时钟时仍会执行 `org_clock_out`，可增加守卫或提前提示，避免产生误导性的“keep running”行为。
- `lua/plugins/orgmode.lua:82` - 建议在 `organization_task_id` 为空时向用户提示如何设置 `vim.g.org_organization_task_id`，以降低首次配置成本（目前只在模块内 warn）。

## 修复指导
- 在 `org_clock_in`/`org_clock_out` 中，若 `call_org_action` 返回 false，则先检测 `orgmode` 是否有活动时钟（或捕获错误信息），再 `vim.notify` 说明需要配置默认映射或当前无时钟。
- 在 `clock_out_keep_running` 里，`org_clock_goto()` 失败时直接通知并返回，避免随后执行 `org_clock_out()`。
- 在 `orgmode` 配置阶段如果 `organization_task_id` 为空，输出指向 `docs/orgmode-norang-workflow.md` 的提示，让新用户知道需要设置默认任务 ID。

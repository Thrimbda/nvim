# Code Review Report

## 结论
PASS-WITH-CHANGES

## Blocking Issues
- [ ] (none)

## 建议（非阻塞）
- `lua/tests/smoke/orgmode_smoke.lua:143` - 测试通过直接调用 `trigger._state.listener(...)` 驱动逻辑，绕过了真实事件总线；建议补一条通过 `orgmode.events.dispatch(events.TodoChanged:new(...))` 的集成断言，避免“单元通过但集成断裂”漏检。
- `lua/plugins/orgmode.lua:202` - `require("org_legion.todo_triggers").setup()` 的返回值未处理；当 `orgmode.events` 不可用时会静默失效，建议至少 `vim.notify` 一次 warning，便于定位配置/加载顺序问题。
- `lua/org_legion/todo_triggers.lua:9` - 当前通过手工正则重写 headline 行来改标签，可维护性一般；orgmode 已提供 `headline:add_tag/remove_tag`，建议改为 API 级增删，降低对文本格式细节（尾随空格、标签对齐、边缘语法）的耦合。
- `skills/legion-workflow/references/orgmode-legion-workflow.md:42` - 文档已描述触发规则，但未注明“标签触发依赖 orgmode TodoChanged 事件”；建议补 1 行依赖说明和排障提示（如 setup 失败时行为退化）。

## 修复指导
1. 补集成测试：在 `lua/tests/smoke/orgmode_smoke.lua` 新增一段“真实事件派发”路径，示例：`event_manager.dispatch(events.TodoChanged:new(headline, 'TODO', false))`，然后断言标签变化。
2. 加 setup 失败可观测性：在 `lua/plugins/orgmode.lua` 对 `setup()` 返回 `(ok, err)` 做判断，`ok ~= true` 时用 `vim.notify(('todo_triggers disabled: %s'):format(err), vim.log.levels.WARN)`。
3. 收敛标签写入实现：在 `lua/org_legion/todo_triggers.lua` 将 `apply_tag_delta` 改为 `remove_tag` + `add_tag` 组合，最后调用一次 `headline:align_tags()`；保留现有标签顺序需求时，可先读 `get_own_tags()` 后按顺序批量操作。
4. 文档补依赖与排障：在 `skills/legion-workflow/references/orgmode-legion-workflow.md` 的“TODO 状态触发标签”段追加“依赖 todo_triggers.setup 成功注册事件监听”的说明，并给出快速自检步骤（切换 TODO 状态后观察标签是否自动同步）。

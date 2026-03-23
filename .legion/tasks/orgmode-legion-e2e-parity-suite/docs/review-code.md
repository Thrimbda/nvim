# 代码评审报告

## 结论
PASS

## 阻塞问题
- [ ] (none)

## 建议（非阻塞）
- `tests/smoke/run.sh:16` - smoke case 清单仍在 shell 中硬编码，与 `lua/tests/smoke/orgmode_smoke.lua:1096` 的 `CASES` 双处维护，后续新增/删减 case 时有漂移风险。
- `lua/tests/smoke/orgmode_smoke.lua:907` - 仍通过写入 `capture._state.capture_started_at` 驱动分钟粒度时长，这是对白盒内部状态的耦合；长期可考虑提供测试注入参数以降低脆弱性。
- `lua/org_punch.lua:633` - `punch_in/punch_out` 总是发通知，测试或批处理场景会引入噪音；可考虑提供 `silent` 或可配置通知级别开关。

## 修复指引
本轮复核中，上一轮 3 个阻塞项均已关闭：

1. `lua/org_punch.lua:5` 已移除硬编码默认任务 ID（改为空字符串），与“必须显式配置 ID”一致。
2. `skills/legion-workflow/references/orgmode-legion-workflow.md:27` 与实现一致，不再存在文档-行为契约冲突。
3. `lua/tests/smoke/orgmode_smoke.lua:914` 已将 capture pre-refile 断言收敛到目标 subtree（`get_subtree_lines(...)`），避免全文件误匹配。

当前无阻塞/高优先级问题；可按非阻塞建议逐步增强可维护性与测试稳健性。

## 变更内容
- 在 `lua/tests/smoke/orgmode_smoke.lua` 中完成 Legion parity smoke 更新，并落地 `PARITY_FAIL {json}` 协议。
- 新增 `clock_out_in_punch_mode_returns_to_parent` 与 `legion_e2e_integrated_flow`，覆盖父任务/默认任务回退与完整集成流程。
- 收紧 capture pre-refile 校验到源 subtree 范围，并更新 parity 边界文档。

## 变更原因
- 需要一个可靠的 fail-fast 对齐门禁，验证端到端 Legion 行为，而不仅是离散断言。
- 最近修复补齐了 keep-running 回退、配置默认值与 smoke runner 加固等正确性缺口。
- 这些改动使实现、文档与评审门禁回到一致且可合并状态。

## 实现方式
- 在 `lua/org_punch.lua` 中修复 `clock_out_keep_running`，使用基于 AST 的定位回退实现父任务恢复。
- 移除硬编码默认 `organization_task_id`（默认空值，除非显式配置）。
- 加固 `tests/smoke/run.sh`：增加 runtimepath 环境/路径校验，并将未固定 HOME fallback 限制为显式 opt-in（`ALLOW_UNPINNED_ORGMODE=1`）。

## 测试
- 命令：`bash tests/smoke/run.sh`
- 结果：PASS（`16/16`），包含新增 parity cases。
- 报告：`.legion/tasks/orgmode-legion-e2e-parity-suite/docs/test-report.md`
- 评审：code PASS（`.legion/tasks/orgmode-legion-e2e-parity-suite/docs/review-code.md`），security PASS（`.legion/tasks/orgmode-legion-e2e-parity-suite/docs/review-security.md`）

## 风险 / 回滚
- 剩余风险主要是时间边界 flake 可能性与 shell/Lua 双清单漂移。
- 安全风险态势已改善：runtimepath 与未固定依赖回退已改为 secure-by-default。
- 回滚方案：从 `tests/smoke/run.sh` 移除集成 case，回退 `lua/tests/smoke/orgmode_smoke.lua` 集成接线，保留原子 cases，并重新执行 smoke。

## 链接
- Task brief：`.legion/tasks/orgmode-legion-e2e-parity-suite/docs/task-brief.md`
- RFC：`.legion/tasks/orgmode-legion-e2e-parity-suite/docs/rfc.md`
- RFC review：`.legion/tasks/orgmode-legion-e2e-parity-suite/docs/rfc-review.md`
- Code review：`.legion/tasks/orgmode-legion-e2e-parity-suite/docs/review-code.md`
- Security review：`.legion/tasks/orgmode-legion-e2e-parity-suite/docs/review-security.md`
- Walkthrough：`.legion/tasks/orgmode-legion-e2e-parity-suite/docs/report-walkthrough.md`

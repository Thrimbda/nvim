# 实现走查：orgmode-norang-e2e-parity-suite

## 1) 目标与范围
- 目标：完成一个可用于 CI 的 Norang 对齐 E2E smoke 门禁，具备清晰失败语义与稳定回退行为。
- 范围内文件：
  - `lua/tests/smoke/orgmode_smoke.lua`
  - `lua/org_punch.lua`
  - `tests/smoke/run.sh`
  - `docs/orgmode-norang-workflow.md`
- 验收锚点：RFC 矩阵 `NP-001..NP-015`，其中 MUST 断言由可执行 smoke 检查覆盖。

## 2) 设计摘要（与 RFC 对齐）
- 设计来源：`.legion/tasks/orgmode-norang-e2e-parity-suite/docs/rfc.md`。
- 策略保持为混合模式：一个集成流程 + 原子辅助 cases，用于快速定位。
- 失败协议确定为 `PARITY_FAIL {json}`（v1），用于机器解析与按断言 ID 分诊。
- `clock_out` 回退语义已显式拆分并测试：`NP-006A`（回到父任务）与 `NP-006B`（回到默认任务）。

## 3) 变更清单（按模块/文件）

### `lua/tests/smoke/orgmode_smoke.lua`
- 新增 parity JSON 失败协议输出：`PARITY_FAIL {json}`。
- 新增 case：`clock_out_in_punch_mode_returns_to_parent`。
- 新增 case：`norang_e2e_integrated_flow`。
- 收紧 capture pre-refile 断言，仅作用于源 subtree（避免全文件误报）。

### `lua/org_punch.lua`
- 在 `clock_out_keep_running` 中通过基于 AST 的定位回退修复 punch 模式父任务回退。
- 移除硬编码默认 `organization_task_id`；现在默认空值，除非显式配置。

### `tests/smoke/run.sh`
- 在 Lua 侧 append 前，先通过环境/路径校验加固 runtimepath 追加流程。
- 默认关闭未固定版本的 HOME fallback；仅在 `ALLOW_UNPINNED_ORGMODE=1` 时启用。

### `docs/orgmode-norang-workflow.md`
- 更新 parity 边界章节，反映最终 MUST/SHOULD/OUT-OF-SCOPE 契约与已实现行为。

## 4) 验证
- 命令：`bash tests/smoke/run.sh`
- 期望：`All smoke cases passed.` 且最终汇总为 `PASS 16/16`。
- 最终结果：PASS `16/16`（见 `.legion/tasks/orgmode-norang-e2e-parity-suite/docs/test-report.md`）。
- 评审门禁：code PASS（`.legion/tasks/orgmode-norang-e2e-parity-suite/docs/review-code.md`），security PASS（`.legion/tasks/orgmode-norang-e2e-parity-suite/docs/review-security.md`）。

## 5) 风险与回滚
- 剩余风险：分钟边界时间敏感、shell/Lua 双清单维护漂移，以及有限白盒测试耦合。
- 安全态势：runner 路径采用 secure-by-default；未固定依赖回退需显式 opt-in。
- 回滚：
  - 从 `tests/smoke/run.sh` 移除集成 case。
  - 回退 `lua/tests/smoke/orgmode_smoke.lua` 中的集成流程接线，同时保留原子 cases。
  - 重新执行 `bash tests/smoke/run.sh`，确认辅助覆盖仍为绿色。

## 6) 未决项与后续步骤
- 未决：
  - 在更多 CI 稳定性数据后，是否将 `NP-011` 从 SHOULD 提升为 MUST。
  - 是否增加仅跑 parity 的快速 CI 通道，以便更快 bisect。
- 后续：
  1. 在 CI 中按断言 ID 聚合 `PARITY_FAIL` 以追踪趋势。
  2. 收敛 smoke case 的单一事实源，降低清单漂移风险。

## 链接
- Task brief：`.legion/tasks/orgmode-norang-e2e-parity-suite/docs/task-brief.md`
- RFC：`.legion/tasks/orgmode-norang-e2e-parity-suite/docs/rfc.md`
- RFC review：`.legion/tasks/orgmode-norang-e2e-parity-suite/docs/rfc-review.md`
- Test report：`.legion/tasks/orgmode-norang-e2e-parity-suite/docs/test-report.md`
- Code review：`.legion/tasks/orgmode-norang-e2e-parity-suite/docs/review-code.md`
- Security review：`.legion/tasks/orgmode-norang-e2e-parity-suite/docs/review-security.md`

# nvim-orgmode Legion 实现 Walkthrough 报告（最新改动）

## 1) 目标与范围

- 目标：按 Legion 口径完成本轮对齐修复，覆盖 TODO 状态触发标签、capture 模板补齐（w/h）、文档同步、smoke 扩展，并给出可审计交付结论。
- Scope 绑定：`lua/plugins/orgmode.lua`、`lua/org_legion/**/*.lua`、`lua/tests/smoke/orgmode_smoke.lua`、`tests/smoke/run.sh`、`skills/legion-workflow/references/orgmode-legion-workflow.md`、`.legion/tasks/nvim-orgmode-legion-implementation/docs/*`。
- 设计真源（RFC）：`.legion/tasks/nvim-orgmode-legion-implementation/docs/rfc.md`。

## 2) 设计摘要

- 设计依据：以 RFC 的 A/B/C 三基线与 Design Gate 为唯一判级口径，实施“先对齐语义，再补测试证据，再收敛交付文档”的最小改动策略。
- 本轮重点对齐项：
  - TODO 状态触发标签（WAITING/HOLD/CANCELLED 与 TODO/NEXT/DONE 的增删规则）
  - capture 模板覆盖（新增 `w` org-protocol、`h` habit）
  - 工作流文档与快捷键说明同步
  - smoke 回归覆盖新增 `todo_state_tag_triggers_legion`
- 相关产物：
  - 代码审查：`.legion/tasks/nvim-orgmode-legion-implementation/docs/review-code.md`
  - 安全审查：`.legion/tasks/nvim-orgmode-legion-implementation/docs/review-security.md`
  - 测试报告：`.legion/tasks/nvim-orgmode-legion-implementation/docs/test-report.md`

## 3) 改动清单（按模块/文件类型）

### Lua 代码

- `lua/org_legion/todo_triggers.lua`
  - 新增并接入 TODO 状态触发器，实现 WAITING/HOLD/CANCELLED 自动标签同步。
  - 对 `TODO/NEXT/DONE` 做标签清理，避免 WAITING/HOLD/CANCELLED 残留。
- `lua/plugins/orgmode.lua`
  - capture 模板新增 `w`（org-protocol）与 `h`（habit）并保持现有 Legion capture handoff 兼容。
  - 在 orgmode setup 后执行 `require("org_legion.todo_triggers").setup()`，启用状态触发监听。

### 测试与脚本

- `lua/tests/smoke/orgmode_smoke.lua`
  - 新增 `todo_state_tag_triggers_legion`，覆盖 TODO 状态流下标签增删断言。
- `tests/smoke/run.sh`
  - 将 `todo_state_tag_triggers_legion` 纳入 smoke 套件执行序列。

### 文档与交付物

- `skills/legion-workflow/references/orgmode-legion-workflow.md`
  - 更新 capture 模板清单（含 `w/h`）与 TODO 状态触发规则说明。
- `.legion/tasks/nvim-orgmode-legion-implementation/docs/report-walkthrough.md`
  - 依据最新 diff 重新生成（本文件）。

## 4) 如何验证（命令 + 预期）

- 运行命令：`bash tests/smoke/run.sh`
- 预期结果：
  - 终端输出所有 case PASS，最终 `All smoke cases passed.`
  - 总结应为 `14/14 case 通过`
  - 关键 case 必须 PASS：
    - `todo_state_tag_triggers_legion`
    - `capture_clock_handoff_resumes_previous`
    - `capture_pre_refile_injects_clock_line`
    - `legion_refresh_marks_stuck_project`
    - `legion_cleanup_apply_removes_derived_tags`

## 5) 测试与审查结论

- 测试结论：`PASS`
  - 证据：`.legion/tasks/nvim-orgmode-legion-implementation/docs/test-report.md`
  - 结果：`14/14` 冒烟用例通过。
- 代码审查结论：`PASS-WITH-CHANGES`
  - 证据：`.legion/tasks/nvim-orgmode-legion-implementation/docs/review-code.md`
  - 状态：无 blocking。
- 安全审查结论：`PASS-WITH-CHANGES`
  - 证据：`.legion/tasks/nvim-orgmode-legion-implementation/docs/review-security.md`
  - 状态：无 blocking/high。

## 6) Benchmark 结果或门槛说明

- benchmark 数据：本轮无独立性能基准数据。
- 原因：当前变更聚焦语义对齐与回归覆盖，仓库未提供稳定可复现的基准脚本。
- 交付门槛（替代 benchmark）：
  - smoke `14/14 PASS`
  - code/security review 均为 `PASS-WITH-CHANGES` 且 `blocking=0`

## 7) 可观测性（metrics/logging）

- 运行时可观测性：当前主要通过 `vim.notify` 与命令返回值暴露失败。
- 测试可观测性：smoke runner 按 case 输出 PASS/FAIL，失败时直接 `cquit 1` 快速中断。
- 已知缺口：
  - `todo_triggers.setup()` 失败时缺少显式告警（review 已给出非阻塞建议）。
  - TODO 触发自动改标过程暂无结构化审计日志（review-security 非阻塞建议）。

## 8) 风险与回滚

- 主要风险：
  - 触发器依赖 orgmode 事件系统，若加载顺序异常可能出现静默降级。
  - TODO 标签写入目前采用文本重写策略，边缘语法下有一致性风险（非阻塞）。
- 回滚方案：
  1. 在 `lua/plugins/orgmode.lua` 暂时移除/注释 `require("org_legion.todo_triggers").setup()`。
  2. 从 `org_capture_templates` 撤回 `w/h` 条目（如需最小回退）。
  3. 重新运行 `bash tests/smoke/run.sh` 确认核心能力不回归。

## 9) 未决项与下一步

- 未决项：
  - 将 `todo_state_tag_triggers_legion` 从“直接调用 listener”升级为“真实事件总线派发”集成断言。
  - 为 trigger setup 失败补充 warning 与健康状态可视化。
  - 将标签更新实现收敛为 headline/tag API，降低字符串拼接耦合。
- 下一步建议：
  1. 先补 setup 失败告警与 event-dispatch 集成测试，再做实现细化。
  2. 评估 smoke runner 增加单 case 超时，降低 CI 卡死风险。

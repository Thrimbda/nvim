# What

- 对齐 Norang 规则，新增 TODO 状态触发标签：`WAITING/HOLD/CANCELLED` 自动增删与 `TODO/NEXT/DONE` 清理逻辑。
- 补齐 capture 模板 `w`（org-protocol）与 `h`（habit），并保持现有 capture handoff 流程。
- 扩展 smoke：新增 `todo_state_tag_triggers_norang` 并纳入 `tests/smoke/run.sh`。
- 同步更新工作流文档与 walkthrough 报告。

# Why

- 修复实现与 Norang 原文在 TODO 触发与 capture 模板覆盖上的不一致。
- 为本轮对齐改动补齐可执行回归证据，确保交付口径可复核。

# How

- 在 `lua/org_norang/todo_triggers.lua` 实现并注册 `TodoChanged` 监听，按目标 TODO 状态执行标签 delta。
- 在 `lua/plugins/orgmode.lua` 增加 capture 模板 `w/h` 并启用 todo trigger setup。
- 在 `lua/tests/smoke/orgmode_smoke.lua` 新增状态流断言 case；在 `tests/smoke/run.sh` 加入执行列表。
- 在 `docs/orgmode-norang-workflow.md` 更新模板与触发规则说明。

# Testing

- `bash tests/smoke/run.sh`
- 结果：`PASS`（14/14）
- 关键 case：`todo_state_tag_triggers_norang`、`capture_clock_handoff_resumes_previous`、`capture_pre_refile_injects_clock_line`、`norang_refresh_marks_stuck_project`、`norang_cleanup_apply_removes_derived_tags`
- 审查：
  - code review: `PASS-WITH-CHANGES`（no blocking）
  - security review: `PASS-WITH-CHANGES`（no blocking/high）

# Risk / Rollback

- 风险：todo trigger 依赖 orgmode 事件系统；setup 失败时当前实现可能静默降级。
- 回滚：
  1. 关闭 `require("org_norang.todo_triggers").setup()` 接入。
  2. 撤回 capture `w/h` 模板。
  3. 重新运行 smoke 验证核心流程。

# Links

- RFC: `.legion/tasks/nvim-orgmode-norang-implementation/docs/rfc.md`
- Walkthrough: `.legion/tasks/nvim-orgmode-norang-implementation/docs/report-walkthrough.md`
- Test report: `.legion/tasks/nvim-orgmode-norang-implementation/docs/test-report.md`
- Code review: `.legion/tasks/nvim-orgmode-norang-implementation/docs/review-code.md`
- Security review: `.legion/tasks/nvim-orgmode-norang-implementation/docs/review-security.md`

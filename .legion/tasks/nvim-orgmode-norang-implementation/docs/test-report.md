# 测试验证报告（org/norang 聚焦）

## 执行信息

- 仓库根目录：`/Users/c1/.config/nvim`
- 执行时间：2026-03-01
- 执行命令：`bash tests/smoke/run.sh`

## 结果

**PASS**

- 总计：14/14 case 通过
- 关键 Norang 相关 case：
  - `norang_refresh_marks_stuck_project`: PASS
  - `norang_cleanup_apply_removes_derived_tags`: PASS
  - `todo_state_tag_triggers_norang`: PASS

## 全部用例结果

- `punch_in_requires_id`: PASS
- `punch_in_clocks_default_task`: PASS
- `punch_in_preserves_current_buffer`: PASS
- `punch_out_preserves_current_buffer`: PASS
- `clock_in_todo_task_switches_to_next`: PASS
- `clock_in_next_project_switches_to_todo`: PASS
- `clock_in_preserves_view_state`: PASS
- `clock_out_removes_zero_duration_clock`: PASS
- `clock_out_in_punch_mode_returns_to_default`: PASS
- `norang_refresh_marks_stuck_project`: PASS
- `norang_cleanup_apply_removes_derived_tags`: PASS
- `capture_clock_handoff_resumes_previous`: PASS
- `capture_pre_refile_injects_clock_line`: PASS
- `todo_state_tag_triggers_norang`: PASS

## 失败明细

- 无（本轮未出现失败用例）

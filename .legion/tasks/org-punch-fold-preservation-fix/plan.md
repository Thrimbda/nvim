# org-punch-fold-preservation-fix

## 目标

修复 org_punch 的 clock in/out 对折叠视图的破坏，并增加回归测试覆盖所有相关路径。

## 要点

- 找出所有未经过 view restore 的 clock/punch 路径
- 统一在相关入口恢复窗口视图与折叠状态
- 增加 smoke 回归测试，覆盖 punch in、普通 clock out、punch out 与 keep-running 路径

## 范围

- lua/org_punch.lua
- lua/tests/smoke/orgmode_smoke.lua
- .legion/tasks/org-punch-fold-preservation-fix/**

## 阶段概览

1. **阶段 0: 定位与设计** - 2 个任务
2. **阶段 1: 实现** - 1 个任务
3. **阶段 2: 验证** - 2 个任务

---

*创建于: 2026-03-09 | 最后更新: 2026-03-09*

# org-punch-fold-preservation-fix - 上下文

## 会话进展 (2026-03-09)

### ✅ 已完成

- 定位到 fold 回归并非单点 bug：`punch_in`、`punch_out`、普通 `clock_out_current_task` 等路径此前未统一经过 view restore。
- 已在 `lua/org_punch.lua` 统一将 public clock/punch 入口纳入 view restore，并补充 `foldmethod`/`foldexpr`/`foldcolumn` 等窗口级折叠选项恢复。
- 已在 smoke 中加入 fold 回归覆盖：`punch_in_preserves_current_buffer`、`punch_out_preserves_current_buffer` 增强为折叠断言，并新增 `clock_out_preserves_view_state`。
- 已执行 targeted fold smoke 与 `bash tests/smoke/run.sh` 全量验证，结果 PASS。


### 🟡 进行中

(暂无)

### ⚠️ 阻塞/待定

(暂无)

---

## 关键文件

(暂无)

---

## 关键决策

| 决策 | 原因 | 替代方案 | 日期 |
|------|------|----------|------|
| 优先在 `org_punch` 的公共入口统一恢复窗口视图，而不是依赖“尽量不写文件”来避免折叠错乱。 | fold 被打乱的核心原因是 clock/punch 动作会切换定位并改动 buffer，哪怕只做内存修改也可能触发折叠重算；统一 view restore 比减少写盘更可靠。 | 仅减少文件写回/仅修单一路径；已拒绝，因为无法覆盖 `punch_out`、普通 `clock_out` 等同类路径。 | 2026-03-09 |

---

## 快速交接

**下次继续从这里开始：**

1. (待填写)

**注意事项：**

- (待填写)

---

*最后更新: 2026-03-09 15:07 by Claude*

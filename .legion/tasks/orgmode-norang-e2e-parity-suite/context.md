# orgmode-norang-e2e-parity-suite - 上下文

## 会话进展 (2026-03-04)

### ✅ 已完成

- 创建新任务 orgmode-norang-e2e-parity-suite 并切换为 active
- 生成 docs/task-brief.md，明确问题定义、验收、假设、风险与验证计划
- 完成风险/规模分级：Medium + Epic，标签 epic/rfc:heavy
- RFC 已生成并通过二次对抗审查（docs/rfc.md + docs/rfc-review.md，结论 PASS）
- 实现 parity 失败协议 `PARITY_FAIL {json}`（v1）并接入 smoke 断言
- 新增原子 case `clock_out_in_punch_mode_returns_to_parent` 与集成 case `norang_e2e_integrated_flow`
- 修复 org_punch keep-running 父任务回退：在 clock_out_keep_running 中引入 AST 定位回退路径并通过严格断言
- 移除 org_punch 默认硬编码 organization_task_id，收敛到显式配置语义并与文档一致
- 加固 tests/smoke/run.sh：runtimepath 注入改为受控 Lua 校验；HOME fallback 改为 `ALLOW_UNPINNED_ORGMODE=1` 显式开启
- 更新工作流文档 parity 覆盖边界（MUST/SHOULD/OUT-OF-SCOPE）
- 执行 `bash tests/smoke/run.sh` 最终 16/16 PASS
- 完成 review-code 与 review-security 复审，结论均为 PASS
- 生成 report-walkthrough 与可直接复用的 pr-body


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
| 本任务按 Medium + Epic 执行，并采用 rfc:heavy 设计强度（先 RFC + review-rfc，再实现）。 | 覆盖范围跨多个模块且验收依赖外部规范（Norang 原文）与上游语义，若无先验设计会导致测试错测/漏测。 | design-lite 直接实现；已拒绝，因无法稳定定义“重要行为”与不可覆盖边界。 | 2026-03-04 |
| 将 smoke runner runtimepath 注入从 Ex 拼接迁移到受控 Lua 校验，并将 HOME 依赖回退改为显式 opt-in。 | 关闭命令注入与不受信任依赖默认加载风险，满足 security review blocking 收敛。 | 继续使用 +set rtp 和默认 HOME fallback；已拒绝（secure-by-default 不成立）。 | 2026-03-04 |
| 将 NP-006A 断言收紧为“存在父任务时必须回父任务”，并修复 org_punch 逻辑以满足该约束。 | Norang 工作流要求 keep-running 优先回到可执行父任务；放宽为 parent/default 任一会掩盖关键语义偏差。 | 保留宽松断言（parent 或 default 均通过）；已拒绝。 | 2026-03-04 |

---

## 快速交接

**下次继续从这里开始：**

1. 使用 `.legion/tasks/orgmode-norang-e2e-parity-suite/docs/pr-body.md` 作为 PR 描述提交评审
2. 评审时重点关注新增集成用例 `norang_e2e_integrated_flow` 与 `clock_out_in_punch_mode_returns_to_parent` 的稳定性
3. 如需后续加固，可按 review 建议收敛 runner case 列表单一来源与 capture 注入白盒耦合

**注意事项：**

- 最终验证命令：`bash tests/smoke/run.sh`，结果 PASS 16/16
- 门禁状态：RFC PASS、run-tests PASS、review-code PASS、review-security PASS

---

*最后更新: 2026-03-04 16:31 by Claude*

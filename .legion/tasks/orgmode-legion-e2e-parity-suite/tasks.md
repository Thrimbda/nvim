# orgmode-legion-e2e-parity-suite - 任务清单

## 快速恢复

**当前阶段**: 阶段 5 - 阶段 4: 报告
**当前任务**: (none)
**进度**: 8/8 任务完成

---

## 阶段 1: 阶段 0: 任务澄清与风险分级 ✅ COMPLETE

- [x] 生成 task-brief，明确问题定义、验收标准、假设与风险 | 验收: docs/task-brief.md 存在且包含风险分级与验证计划
- [x] 根据任务复杂度确定设计强度并形成设计门禁 | 验收: 任务标记包含风险等级与是否 epic/rfc:heavy

---

## 阶段 2: 阶段 1: 设计与对抗审查 ✅ COMPLETE

- [x] 编写 RFC，定义关键行为矩阵与端到端测试策略 | 验收: docs/rfc.md 覆盖行为映射、断言设计、回滚策略
- [x] 执行 RFC 对抗审查并收敛 blocking | 验收: docs/rfc-review.md 结论 PASS 或 blocking=0

---

## 阶段 3: 阶段 2: 实现 ✅ COMPLETE

- [x] 实现端到端测试用例并更新 smoke 入口 | 验收: 新增/更新测试在本地可运行且覆盖关键行为

---

## 阶段 4: 阶段 3: 验证与评审 ✅ COMPLETE

- [x] 执行测试并记录结果 | 验收: docs/test-report.md 生成并包含 PASS/FAIL 细节
- [x] 执行代码审查与必要的安全审查 | 验收: docs/review-code.md 生成，若 medium/high 或安全相关则生成 docs/review-security.md

---

## 阶段 5: 阶段 4: 报告 ✅ COMPLETE

- [x] 生成 walkthrough 与 PR body | 验收: docs/report-walkthrough.md 与 docs/pr-body.md 生成

---

## 发现的新任务

(暂无)
- [x] 实现 Legion 端到端集成 smoke case（含 NP-006A parent fallback）并更新 runner | 来源: rfc.md Milestone 2 / review 修复后继续执行
- [x] 执行 smoke 全量验证并写入 docs/test-report.md | 来源: 执行要求 step 6 run-tests
- [x] 完成代码评审与安全评审并落盘 docs/review-code.md / docs/review-security.md | 来源: 执行要求 step 6 review-code/review-security
- [x] 生成 walkthrough 与 PR body 文档 | 来源: 执行要求 step 7 report-walkthrough


---

*最后更新: 2026-03-04 16:28*

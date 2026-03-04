## Summary

### What

本 PR 交付 Norang workflow 的 AI skill 文档资产，新增并完善 `skills/norang-workflow/**`，并补齐任务级测试、评审与交付报告文档。

### Why

仓库已有面向人的工作流说明，但缺少可直接供 agent 执行的统一入口，导致重复解释成本高、执行口径不一致。本次交付将真源规则产品化为可复用 skill。

### How

以 `docs/orgmode-norang-workflow.md` 为事实真源，按 design-lite 路线新增 AI-facing 操作指南与 quick checklist，并通过轻量结构校验 + 文档评审闭环确保可用性与一致性。

## Validation

- Result: PASS
- Evidence: `./.legion/tasks/norang-workflow-ai-skill/docs/test-report.md`
- Method: 使用轻量 Python 断言检查目标文件存在性、关键章节完整性与约束文本（`<Leader>oc` disabled、`explicit user confirmation`、`Last verified`）
- 说明：本任务为文档型交付，未执行运行时代码回归测试，当前验证策略与风险等级匹配。

## Risks

- 风险等级：Low
- 主要风险：后续真源文档更新但 skill 未同步，可能产生语义漂移。
- 安全说明：本次不涉及认证/授权/密钥/支付/数据迁移/权限模型变更，`review-security` 非必需。

## Rollback

1. 删除 `skills/norang-workflow/` 新增资产。
2. 删除本任务文档产物：
   - `./.legion/tasks/norang-workflow-ai-skill/docs/test-report.md`
   - `./.legion/tasks/norang-workflow-ai-skill/docs/review-code.md`
   - `./.legion/tasks/norang-workflow-ai-skill/docs/report-walkthrough.md`
   - `./.legion/tasks/norang-workflow-ai-skill/docs/pr-body.md`
3. 无需数据库或运行时状态回滚。

## Artifacts

- Task brief: `./.legion/tasks/norang-workflow-ai-skill/docs/task-brief.md`
- Design (RFC-lite): `./.legion/tasks/norang-workflow-ai-skill/docs/design-lite.md`
- Test report: `./.legion/tasks/norang-workflow-ai-skill/docs/test-report.md`
- Code review: `./.legion/tasks/norang-workflow-ai-skill/docs/review-code.md`
- Walkthrough: `./.legion/tasks/norang-workflow-ai-skill/docs/report-walkthrough.md`

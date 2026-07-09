# org-agenda-norang-parity-fix Tasks

## 阶段 0: Brainstorm / Contract

- [x] 确认当前请求进入 Legion workflow。
- [x] 对照截图提炼 Norang agenda baseline 差异。
- [x] 物化 `plan.md`、`tasks.md`、`log.md` 与 design-lite。

## 阶段 1: Engineer

- [x] 进入 `git-worktree-pr` envelope。
- [x] 调整 `:Org agenda b` 的 block order、section headers 和 matchers。
- [x] 将 `PROJECT/STUCK/PROJECT_TASK/ARCHIVE_CANDIDATE` 改为虚拟 agenda 分类，不再由 refresh 写回 org 文件。
- [x] 补充结构测试，覆盖 `b` command 的 section order/header/matcher。
- [x] 补充虚拟分类测试，覆盖 refresh 不改写 org 文本和 agenda search 可命中虚拟标签。
- [x] 同步用户文档中的 block agenda 描述。

## 阶段 2: Verify

- [x] 运行 smoke 或等价最小验证命令。
- [x] 记录验证证据到 `docs/test-report.md`。

## 阶段 3: Review

- [x] 执行实现自查，检查 scope、回归风险和测试充分性。

## 阶段 4: Handoff / Wiki

- [x] 更新 `docs/report-walkthrough.md`。
- [x] 更新 `.legion/wiki/**` 当前真源。

## Done Criteria

- [x] 实现自查 PASS。
- [x] `report-walkthrough` 与 `legion-wiki` 已完成。
- [ ] PR lifecycle 已完成或阻塞原因已记录。

---

最后更新: 2026-07-09

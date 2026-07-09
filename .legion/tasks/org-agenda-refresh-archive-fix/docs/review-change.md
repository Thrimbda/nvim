# Review Change

## Decision

PASS

## Blocking Findings

无。

## Scope Review

- `lua/plugins/orgmode.lua`: 只修改 agenda refresh wrapper、Norang-style todo keywords/faces、`org_legion.todo.done` 配置，符合 contract。
- `lua/org_legion/init.lua`: 增加 refresh failure formatter、manual refresh summary details、done keyword default parity，符合 contract。
- `lua/org_legion/todo_triggers.lua`: 将 `PHONE` / `MEETING` 作为 done-state 清理 stale flow tags，属于 done keyword parity 的直接配套。
- `lua/tests/smoke/orgmode_smoke.lua` 与 `tests/smoke/run.sh`: 增加覆盖 archive completeness、warning details、formatter 和 trigger cleanup 的 smoke cases。
- `.legion/tasks/org-agenda-refresh-archive-fix/**`: 当前任务证据文档，符合 Legion workflow。

未修改真实 org 文件内容，未触碰主工作区 `lazy-lock.json`。

## Correctness Notes

- Archive completeness 依赖 `rules.compute()` 里的 `cfg.todo.done`，本变更把默认配置和插件配置同时扩展到 `DONE/CANCELLED/PHONE/MEETING`，避免只在 UI 或只在 matcher 一侧修复。
- Agenda wrapper 使用 `refresh_all({ notify = false })`，因此失败时不会先出现通用 refresh summary warning，再出现 agenda wrapper warning；wrapper 自己发出一条带 `format_refresh_failures()` 详情的 warning。
- Manual `OrgLegionRefresh` 仍走默认 notify，并通过 `format_refresh_summary()` 在原 count summary 后附带失败文件与 `error.code/message`。
- `PHONE` / `MEETING` trigger cleanup 不移除同名业务 tag，只移除 `WAITING/HOLD/CANCELLED` stale flow tags。

## Verification Review

`docs/test-report.md` 的证据足够覆盖当前 claim：

- targeted smoke 覆盖新增行为。
- full smoke 覆盖 punch/capture/refile/e2e 回归。
- `git diff --check` 通过。
- 真实 agenda 文件 refresh 输出 `total=22 ok=22 fail=0 skipped_conflict=0 skipped_unloaded=0`。

## Security Lens

未命中 security trigger。变更不涉及认证、权限、token、网络协议、secret、用户输入进入 privileged path、数据暴露或租户隔离。

## Residual Risk

本机 smoke 使用 unpinned orgmode fallback，因为仓库缺少 `.tests/deps/orgmode`。这是现有 smoke runner 的 opt-in 路径；风险已在 `docs/test-report.md` 记录。

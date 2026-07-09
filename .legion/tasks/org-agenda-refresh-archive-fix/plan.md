# org-agenda-refresh-archive-fix

## Contract

- `name`: Org agenda archive completeness and refresh diagnostics fix
- `taskId`: `org-agenda-refresh-archive-fix`
- `goal`: 修复 Norang-style agenda 打开前的 `org_legion refresh` warning 诊断不足，并补齐 `Tasks to Archive` 中缺失的 Emacs done-state 条目。
- `problem`: 用户打开 agenda 时看到 `org_legion refresh: total=22 ok=20 fail=2` 和 `org_legion refresh had 2 failures before agenda` 两个 warning，但没有文件级错误信息；同时 Emacs baseline 的 `Tasks to Archive` 包含 `PHONE` done-state 条目，nvim 只显示 `DONE` 条目，说明当前 done keyword 配置与 Norang baseline 不一致。

## Acceptance

- `org_todo_keywords` 包含 Norang-style capture keywords `PHONE` 和 `MEETING`，并把它们作为 done-state keywords 处理。
- `org_legion.todo.done` 同步包含 `PHONE` / `MEETING`，archive candidate 和 `-REFILE/` archive agenda query 能匹配旧的 `PHONE` / `MEETING` done entries。
- 打开 agenda 前的 refresh warning 能列出失败文件和错误原因，至少包含前几个失败条目的文件名与 `error.code/message`。
- `OrgLegionRefresh` 手动命令同样提供可定位的 failure summary。
- 全量 smoke 通过，新增测试覆盖 `PHONE` archive candidate、plugin setup keyword 配置、refresh failure notification details。

## Scope

- 允许修改 `lua/plugins/orgmode.lua` 的 keyword 配置和 refresh warning 文案。
- 允许修改 `lua/org_legion/**` 的 refresh summary / notification 诊断。
- 允许修改 smoke tests 和 runner。
- 允许新增本任务的 Legion 文档、walkthrough、wiki summary。

## Non-goals

- 不修改真实 org 文件内容。
- 不自动清理已有物化 `ARCHIVE_CANDIDATE` 标签。
- 不重做 agenda renderer 或其它 section 语义。
- 不处理非 org 文件、外部同步状态或 OneDrive 文件系统问题本身；本轮只让错误可定位并避免可解析文件被 keyword 配置漏掉。

## Assumptions

- Emacs baseline 中 `PHONE` / `MEETING` 属于 done-state todo keywords，而不是普通 tag。
- `PHONE` / `MEETING` capture templates 已经存在，因此 nvim 配置应能识别这些 headline keywords。
- refresh failure 的真实根因可能来自单个 org 文件内容或文件系统状态；修复应暴露诊断，不把失败静默吞掉。

## Constraints

- 使用 Legion workflow 和 git worktree PR lifecycle。
- 不碰主工作区已有 `lazy-lock.json` 本地修改。
- 不引入新依赖。

## Risks

- orgmode.nvim keyword syntax 若和 Emacs sequence 分组有差异，需用现有 smoke setup 验证。
- `PHONE` / `MEETING` 加入 done-state 后，可能影响 todo trigger 清理逻辑；本轮只确保它们不会被视为 active project task。
- refresh failure 诊断不能泄露文件内容，只输出路径和错误摘要。

## Design Summary

- 将 Norang capture keywords `PHONE` / `MEETING` 加入 orgmode setup 的 done keywords 和 faces。
- 将 org_legion 默认配置与插件 setup 的 `todo.done` 扩展为 `DONE/CANCELLED/PHONE/MEETING`。
- 为 refresh summary 增加失败详情格式化函数，在 `refresh_all` 通知和 agenda wrapper warning 中输出短摘要。
- 通过 smoke test 验证 `PHONE` archive candidate、agenda keyword setup，以及 refresh failure notification details。

## Phases

- `engineer`: 实现 keyword parity、refresh diagnostics 和测试。
- `verify-change`: 运行 targeted smoke、full smoke、`git diff --check`。
- `review-change`: 只读审查 scope、正确性和残余风险。
- `report-walkthrough`: 生成 reviewer-facing handoff 和 PR body。
- `legion-wiki`: 写回任务 summary 与 orgmode agenda parity pattern。

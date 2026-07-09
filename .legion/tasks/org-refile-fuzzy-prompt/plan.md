# org-refile-fuzzy-prompt

## Contract

- `name`: Org refile fuzzy prompt 修复
- `taskId`: `org-refile-fuzzy-prompt`
- `goal`: 让 orgmode refile 目标选择重新显示可 fuzzy 过滤的候选列表，达到用户截图中图一的交互体验。
- `problem`: 初版修复只删除了 `ui.input.use_vim_ui = true` 覆盖，让 refile 回到 orgmode 原生 `input()` completion。用户重启后仍看到单输入框，说明原 contract 的 UI 验收未满足：需要主动显示候选列表的 fuzzy picker，而不是仅有 completion function 的输入框。

## Acceptance

- 触发 org/agenda/capture refile 时，目标选择应打开可见候选列表/picker，而不是只显示单行 input prompt。
- 候选列表包含 agenda 文件和这些文件内未完成 headline destination，并能按输入文本 fuzzy 过滤。
- 选择文件 destination 时仍 refile 到文件根部；选择 headline destination 时仍 refile 到该 headline 下。
- 取消 picker 时不执行 refile，并保留 orgmode 原有取消语义。
- 不改变 orgmode 的 refile 移动语义、agenda 自定义视图、capture clock handoff 或 punch in/out 行为。
- 文档中关于 refile 输入体验的说明与实际配置一致。
- 本仓库 smoke 测试中与 orgmode/capture 相关的现有用例保持通过。

## Scope

- 修改 Neovim orgmode refile destination 选择 UI，使其显式使用 picker/list 候选。
- 更新本仓库 Legion orgmode 工作流说明里关于 refile 输入候选的描述。
- 补充任务级 RFC、验证记录、review 和交付摘要，记录初版验收未满足与二次修复。

## Non-Goals

- 不重写 orgmode.nvim 的 refile 移动实现。
- 不改变 orgmode agenda/capture command mapping。
- 不改变 agenda 文件范围、capture 模板、TODO keyword 或 clock/punch 逻辑。
- 不处理与 `blink.cmp` native fuzzy、treesitter 或其它补全栈相关的历史稳定性问题。

## Assumptions

- 用户截图图一代表期望体验：输入 refile destination 时可看到候选并通过 fuzzy 文本缩小范围。
- Snacks picker 已启用 `vim.ui.select` 接管，适合承载可见候选列表和 fuzzy filter。
- orgmode.nvim 的 `_get_autocompletion_files()` 与 `get_opened_unfinished_headlines()` 可复用来生成合法 destination 候选。
- 最小可控方案是覆盖 `orgmode.capture.get_destination()` 的 UI 入口，保留后续 `_refile_from_*` 移动逻辑不变。

## Constraints

- 必须按 Legion workflow 执行，并在隔离 worktree 中完成修改型开发任务。
- 保留主工作区已有的 `lazy-lock.json` 未提交改动，不读取为本任务变更来源，也不覆盖。
- 只改本任务范围内文件，避免引入新依赖。
- 初版 PR 已合并；本次必须作为 follow-up PR 完整交付，不能只停留在本地说明。

## Risks

- 覆盖 orgmode capture 对象方法依赖上游内部 API；orgmode.nvim 若改动 `_get_autocompletion_files()` 或 destination return shape，补丁需要同步调整。
- UI 类行为难以在 headless 测试中完整复现候选弹窗，需要结合配置断言和现有 smoke 测试降低回归风险。
- 若 picker 候选只包含文件而缺 headline，会仍低于图一期望；验证必须覆盖 headline candidate。

## Design Summary

- 采用标准 RFC：新增本地 `org_refile_picker` 模块，在 orgmode setup 后 patch `orgmode.capture.get_destination()`。
- 模块复用 orgmode 的合法 agenda file/headline 数据，构建 file + headline destination items，然后通过 `vim.ui.select` 展示。Snacks picker 会接管 `vim.ui.select`，提供图一式可见候选和 fuzzy filter。
- `get_destination()` 返回与 orgmode 原方法相同 shape：`{ file = OrgFile, headline? = OrgHeadline }` 或取消时 `false`，从而保留 `_refile_from_capture_buffer` / `_refile_from_org_file` 移动语义。
- 更新说明文档，明确 refile 目标选择打开 picker 候选列表。

## Phases

- `brainstorm`: 收敛并物化本任务 contract。
- `spec-rfc`: 记录 picker patch 设计与验证/回滚。
- `review-rfc`: 对抗审查设计是否可实现、可验证、可回滚。
- `engineer`: 实现 picker destination 选择和文档更新。
- `verify-change`: 运行配置断言与相关 smoke 测试。
- `review-change`: 审查范围、风险和验证证据。
- `report-walkthrough`: 产出 reviewer-facing 交付摘要。
- `legion-wiki`: 写回 wiki 当前事实。

## Design Index

- `docs/rfc.md`: 标准 RFC，记录初版失效原因与 picker 方案。
- `docs/review-rfc.md`: RFC 审查结论。

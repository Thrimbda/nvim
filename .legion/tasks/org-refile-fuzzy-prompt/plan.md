# org-refile-fuzzy-prompt

## Contract

- `name`: Org refile fuzzy prompt 修复
- `taskId`: `org-refile-fuzzy-prompt`
- `goal`: 让 orgmode refile 目标选择重新显示可 fuzzy 过滤的候选列表，达到用户截图中图一的交互体验。
- `problem`: 当前 `lua/plugins/orgmode.lua` 将 orgmode 输入配置为 `ui.input.use_vim_ui = true`，refile 会进入 Snacks `vim.ui.input` 单行输入框。该路径没有稳定呈现 orgmode refile 的候选列表，用户实际看到的是只有输入框的图二体验。

## Acceptance

- 触发 org/agenda/capture refile 时，目标输入能使用 orgmode 自带的 `autocomplete_refile()` 候选，并支持 fuzzy 文件目标匹配。
- 交互不再强制走 Snacks `vim.ui.input` 的裸输入框路径。
- 不改变 orgmode 的 refile 移动语义、agenda 自定义视图、capture clock handoff 或 punch in/out 行为。
- 文档中关于 refile 输入体验的说明与实际配置一致。
- 本仓库 smoke 测试中与 orgmode/capture 相关的现有用例保持通过。

## Scope

- 修改 Neovim orgmode 插件配置中影响 refile 输入 UI 的局部配置。
- 更新本仓库 Legion orgmode 工作流说明里关于 refile 输入候选的描述。
- 补充任务级 design-lite、验证记录、review 和交付摘要。

## Non-Goals

- 不重写 orgmode.nvim 的 refile 实现。
- 不新增 Telescope/Snacks picker 版 refile 流程。
- 不改变 agenda 文件范围、capture 模板、TODO keyword 或 clock/punch 逻辑。
- 不处理与 `blink.cmp` native fuzzy、treesitter 或其它补全栈相关的历史稳定性问题。

## Assumptions

- 用户截图图一代表期望体验：输入 refile destination 时可看到候选并通过 fuzzy 文本缩小范围。
- orgmode.nvim 当前本地版本的默认 `ui.input.use_vim_ui = false` 路径会使用 `vim.fn.input()` 和 custom completion，能调用 `autocomplete_refile()`。
- Snacks input 对 `vim.ui.input` 的 completion 呈现不满足当前需求，恢复 orgmode 原生输入路径是最小可回滚方案。

## Constraints

- 必须按 Legion workflow 执行，并在隔离 worktree 中完成修改型开发任务。
- 保留主工作区已有的 `lazy-lock.json` 未提交改动，不读取为本任务变更来源，也不覆盖。
- 只改本任务范围内文件，避免引入新依赖。

## Risks

- 恢复 orgmode 原生输入路径会让其它 orgmode 输入提示不再使用 Snacks input 的浮窗外观，但这是 orgmode 默认配置，且可通过单行配置回滚。
- UI 类行为难以在 headless 测试中完整复现候选弹窗，需要结合配置断言和现有 smoke 测试降低回归风险。
- 既有文档曾声称 Snacks input 支持候选，需要同步修正，避免后续维护者再次恢复错误假设。

## Design Summary

- 采用低风险 fast track：移除本仓库对 `ui.input.use_vim_ui = true` 的覆盖，让 orgmode 回到默认原生输入路径。
- 依赖 orgmode.nvim 已有的 `Capture:get_destination()` 与 `Capture:autocomplete_refile()`，不复制或 fork 上游 refile 逻辑。
- 更新工作流说明，说明 refile destination 使用 orgmode 原生 input completion，而不是 Snacks input。

## Phases

- `brainstorm`: 收敛并物化本任务 contract。
- `engineer`: 做最小配置和文档改动。
- `verify-change`: 运行配置断言与相关 smoke 测试。
- `review-change`: 审查范围、风险和验证证据。
- `report-walkthrough`: 产出 reviewer-facing 交付摘要。
- `legion-wiki`: 写回 wiki 当前事实。

## Design Index

- `docs/rfc.md`: low-risk design-lite。

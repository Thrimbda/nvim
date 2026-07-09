# Review Change: org-refile-fuzzy-prompt

## Decision

PASS。

## Blocking Findings

无。

## Scope Review

- In scope: `lua/plugins/orgmode.lua` 删除 `ui.input.use_vim_ui = true` 覆盖，符合 design-lite 的最小方案。
- In scope: `skills/legion-workflow/references/orgmode-legion-workflow.md` 更新 refile 输入说明，避免继续传播 Snacks input 可显示候选的错误假设。
- In scope: `.legion/tasks/org-refile-fuzzy-prompt/**` 记录 task contract、design-lite、验证和审查证据。
- 未发现实现层 scope 外变更；未新增依赖；未改 agenda/capture/punch 逻辑。

## Correctness Review

- 变更使用 orgmode.nvim 默认 `ui.input.use_vim_ui = false` 路径，契合 `Capture:get_destination()` 现有 completion 设计。
- 验证证据覆盖了配置覆盖消失、本地 orgmode 默认值、worktree spec-level setup opts、`Capture.autocomplete_refile()` fuzzy 行为，以及完整 smoke suite。
- 保留的限制是未做交互式像素截图验证；考虑到本次修复本质是恢复 orgmode 原生 input completion 路径，当前证据足以支撑交付。

## Maintainability Review

- 删除本地覆盖比引入自定义 picker 更容易维护，也降低未来跟随 orgmode.nvim 上游 refile 行为的偏离风险。
- 文档同步修正了历史错误说明，降低后续维护者再次恢复 `vim.ui.input` 覆盖的概率。

## Security Lens

未触发安全视角。变更不涉及 auth、permission、identity、session、token、信任边界、密钥、加密、webhook、用户可控输入进入高权限路径、数据暴露、隐私或租户隔离。

## Residual Risk

- 用户实际 TUI 的候选弹窗仍取决于 Neovim 原生命令行/input completion 设置，但本次已恢复 orgmode 默认且验证 fuzzy completion 函数存在。
- smoke runner 使用 unpinned 本地 orgmode runtime，因为仓库没有 `.tests/deps/orgmode`；这与当前仓库既有 runner 约束一致，已在 test report 中记录。

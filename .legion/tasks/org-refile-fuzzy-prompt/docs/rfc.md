# Design-lite: Org refile fuzzy prompt

## Context

orgmode.nvim 的 refile destination 选择通过 `Capture:get_destination()` 调用 `orgmode.ui.input.open()`。该输入函数会把 completion 注册为 `customlist,v:lua.orgmode.__input_completion`，其中 refile 的 completion 来源是 `Capture:autocomplete_refile()`。

本仓库当前覆盖了 orgmode 配置：

```lua
ui = {
  input = {
    use_vim_ui = true,
  },
},
```

这会把输入转交给 `vim.ui.input`，实际由 Snacks input 呈现为单行浮窗。用户截图显示该路径没有提供期望的 fuzzy 候选提示。

## Decision

恢复 orgmode 默认输入路径：移除本仓库对 `ui.input.use_vim_ui = true` 的覆盖。

选择这个方案的原因：

- 使用 orgmode.nvim 已有 refile fuzzy completion，不引入新逻辑。
- 改动极小，回滚简单。
- 避免把 refile 迁移到自定义 picker 后偏离上游 refile 行为。

## Alternatives Considered

- 保持 `vim.ui.input`，改 Snacks input 配置：风险是仍依赖 Snacks 对 completion 的弹窗触发行为，且用户已实际遇到候选不可见。
- 新增 Snacks picker refile：可以获得完整 picker UI，但需要复制 destination 解析、headline 过滤和 refile 调用路径，改动面明显变大。

## Verification

- 断言 orgmode 配置不再设置 `ui.input.use_vim_ui = true`。
- 断言本地 orgmode 默认值仍为 `false`。
- 运行与 capture/refile hook 相关的 smoke 用例，确保 capture clock handoff 行为未被破坏。
- 运行完整 smoke suite 或可行子集作为回归证据。

## Rollback

如需要恢复 Snacks input 浮窗，可重新添加：

```lua
ui = {
  input = {
    use_vim_ui = true,
  },
},
```

但在恢复前需要另行解决 Snacks input 对 refile completion 候选可见性的要求。

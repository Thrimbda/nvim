# RFC: Org refile fuzzy picker

## Context

上一轮修复删除了 `ui.input.use_vim_ui = true` 覆盖，运行时也确认 `orgmode.config.ui.input.use_vim_ui=false`。这说明配置已生效，但用户仍看到单输入框，因为 orgmode.nvim 的原生 refile 入口是：

```lua
Input.open('Enter destination: ', '', function(arg_lead)
  return self:autocomplete_refile(arg_lead, valid_destinations)
end)
```

这个路径有 completion function，但 UI 仍是 input prompt，不等于用户截图中有候选列表的 fuzzy picker。

## Goal

让 `<Leader>or` / agenda refile / capture refile 在选择 destination 时打开可见候选列表，并支持输入过滤；选择结果仍交给 orgmode 原有 refile 移动逻辑。

## Options

### Option A: 继续依赖 orgmode 原生 `Input.open`

- 优点：不 patch 上游内部方法。
- 缺点：已经被用户验证为不满足“候选列表提示”体验。
- 结论：拒绝。

### Option B: 调整 Snacks input completion 自动弹出

- 优点：改动可能较小。
- 缺点：仍受 `vim.ui.input` / completion popup 行为限制；不能自然展示完整 file + headline destination 列表。
- 结论：拒绝。

### Option C: 覆盖 `orgmode.capture.get_destination()` 使用 `vim.ui.select`

- 优点：直接得到可见候选列表；Snacks picker 已接管 `vim.ui.select`，可提供 fuzzy filtering；返回值 shape 可保持 `{ file, headline? }`，从而保留 orgmode refile 移动逻辑。
- 缺点：依赖 orgmode capture object 的内部方法 `_get_autocompletion_files()` 和 headline API，需要测试保护。
- 结论：采用。

## Decision

新增本地模块 `lua/org_refile_picker.lua`：

- `setup(capture)` 接收 `orgmode.capture` 对象。
- 保存原始 `capture.get_destination` 作为 fallback。
- 新的 `get_destination()` 使用 `capture:_get_autocompletion_files()` 取合法 agenda destination files。
- 候选包含：
  - 文件 root destination：`path/to/file.org/`
  - 未完成 headline destination：`path/to/file.org/<headline title>`
- 通过 `vim.ui.select(items, { prompt = "Refile subtree to", format_item = ... }, callback)` 打开 picker。
- callback 选择 item 时 resolve `{ file = item.file, headline = item.headline }`；取消时 resolve `false`。
- 若 `vim.ui.select` 不可用或候选构建失败，fallback 到原始 `get_destination()`。

`lua/plugins/orgmode.lua` 在 `capture.setup()` 之后调用 `require("org_refile_picker").setup(orgmode.capture)`。

## Verification

- Headless 单元式断言：
  - `org_refile_picker.build_items()` 为文件和 unfinished headline 都生成候选。
  - patch 后 `capture.get_destination()` 调用 `vim.ui.select`，选择 headline 后返回 `{ file, headline }`。
  - 取消 picker 返回 `false`。
- 运行完整 smoke suite，确保 capture handoff、pre-refile hook、punch/clock、Legion integrated flow 不回归。
- 运行 runtime 断言确认 `<Leader>or` 仍映射到 orgmode refile action。

## Rollback

删除 `require("org_refile_picker").setup(orgmode.capture)` 调用和 `lua/org_refile_picker.lua`，即可回到 orgmode 默认 `get_destination()`。由于 refile 移动逻辑没有被替换，rollback 不涉及数据迁移。

## Risks

- orgmode.nvim 内部 API 变化会影响 patch。缓解：模块保留 fallback，并用测试覆盖 candidate shape。
- 真实 UI 截图验证仍可能受 headless 环境限制。缓解：直接断言 `vim.ui.select` 被调用，且选择结果进入 orgmode 期望 return shape。
- 多个 headline 同名时，和 orgmode 原逻辑一样只靠 title 可能有歧义。当前任务不扩展 disambiguation，候选 label 会包含文件路径以降低混淆。

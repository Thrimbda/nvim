# Review Change: Org refile fuzzy picker

## Decision

PASS。

## Blocking Findings

无。

## Findings

- 实现覆盖的是 orgmode refile destination 的共同入口 `orgmode.capture.get_destination()`，因此 `<Leader>or`、agenda refile 与 capture refile 的目标选择都会进入同一个 picker 路径。
- 新模块只替换 destination 选择 UI，返回仍是 orgmode 原生 `_refile_from_capture_buffer()` / `_refile_from_org_file()` 期望的 `{ file, headline? }` 或取消时 `false`，没有重写移动语义。
- 候选构建包含文件 root destination 与未完成 headline destination，满足本次修正后的“可见候选列表”验收。
- `vim.ui.select` 在当前 Snacks 配置中默认由 Snacks picker 接管，能够提供可见列表与 fuzzy 过滤；若 select 不可用或候选构建失败，代码会 fallback 到 orgmode 原始 `get_destination()`。
- 新增 smoke 覆盖候选构建、选择 headline、取消 refile；完整 smoke suite 通过，未发现 capture clock handoff、pre-refile hook、punch/clock 或 Legion integrated flow 回归。

## Residual Risk

- 真实 TUI 弹窗未在 headless 环境截图验证；当前证据证明代码会调用 `vim.ui.select`，视觉呈现依赖 Snacks picker 接管。
- patch 依赖 orgmode.nvim 内部 `_get_autocompletion_files()` 和 headline API。模块保留 fallback，并用 smoke case 覆盖当前 return shape。

## Verification Reviewed

- `refile_picker_builds_file_and_headline_candidates`: PASS。
- `refile_picker_selects_and_cancels_destination`: PASS。
- worktree spec-level patch 断言：PASS，输出 `picker_patched true`。
- `ALLOW_UNPINNED_ORGMODE=1 bash tests/smoke/run.sh`: PASS，22 个 case 全部通过。
- `git diff --check`: PASS。
- `stylua --check ...`: 未运行成功，当前机器没有 `stylua`。

## Outcome

可以进入 reporter handoff、wiki 写回和 PR lifecycle。

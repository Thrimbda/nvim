# Report Walkthrough

## Profile

implementation

## Reviewer Summary

- 本次是 follow-up 修复：上一轮删除 `ui.input.use_vim_ui = true` 后，orgmode 仍显示单行 input prompt，未满足“图一式可见 fuzzy 候选列表”体验。
- 当前实现新增 `lua/org_refile_picker.lua`，在 orgmode setup 后 patch `orgmode.capture.get_destination()`，用 `vim.ui.select` 展示 refile destination 候选。
- Snacks picker 默认接管 `vim.ui.select`，因此 refile 目标选择会进入可见 picker，并支持按输入 fuzzy 过滤。
- 选择结果仍返回 orgmode 原始移动逻辑需要的 `{ file, headline? }`，取消返回 `false`。
- review-change 结论为 PASS，完整 smoke suite 通过。

## Scope

In scope:

- 替换 orgmode refile destination 选择 UI，使 `<Leader>or`、agenda refile 与 capture refile 共享可见 picker 候选。
- 候选包含 agenda 文件 root 与未完成 headline destination。
- 更新 smoke 测试、runner 和 orgmode Legion 工作流说明。
- 更新 task RFC、review、test report、walkthrough 与 PR body。

Out of scope:

- 不重写 orgmode.nvim 的 refile 移动逻辑。
- 不改变 agenda 文件范围、capture 模板、TODO keyword、clock 或 punch 行为。
- 不引入新的 fuzzy/search 依赖，不改 Snacks picker 全局配置。
- 不新增 HTML preview workflow。

## Evidence Map

| Claim | Evidence | Status |
|---|---|---|
| 原先修复不足，真实验收需要 visible picker | `plan.md`, `docs/rfc.md` | Current |
| 方案采用 `vim.ui.select` / Snacks picker 替换 destination UI | `docs/rfc.md`, `docs/review-rfc.md` | PASS |
| 实现只替换 destination 选择，保留 orgmode 移动语义 | `lua/org_refile_picker.lua`, `lua/plugins/orgmode.lua`, `docs/review-change.md` | PASS |
| 候选包含文件 root 与 unfinished headline | `lua/org_refile_picker.lua`, `lua/tests/smoke/orgmode_smoke.lua`, `docs/test-report.md` | PASS |
| 选择 headline 和取消 refile 行为正确 | `lua/tests/smoke/orgmode_smoke.lua`, `docs/test-report.md` | PASS |
| 既有 orgmode/capture/punch/Legion smoke 未回归 | `docs/test-report.md` | PASS |
| Reviewer 审查没有 blocking finding | `docs/review-change.md` | PASS |

## Delivery Path

1. Reopened brainstorm: 用户反馈 `<leader>or` 仍是旧 input，contract 改为显式 picker 候选。
2. Spec-rfc: 选择 patch `orgmode.capture.get_destination()` 使用 `vim.ui.select`。
3. Review-rfc: PASS，允许进入实现。
4. Engineer: 新增 `org_refile_picker`，接入 orgmode setup，补 smoke 测试和文档。
5. Verify-change: targeted smoke、spec-level patch 断言、完整 smoke suite 与 diff hygiene 通过。
6. Review-change: PASS。
7. Report-walkthrough: 当前 artifact，之后交给 wiki writeback 与 PR lifecycle。

## What Changed / What Was Decided

- `lua/org_refile_picker.lua`: 新增 picker 模块，构建 file + headline destination items，通过 `vim.ui.select` 打开 picker，并把选择结果转换成 orgmode 期望的 destination shape。
- `lua/plugins/orgmode.lua`: 在 `org_capture_legion.setup()` 后调用 `require("org_refile_picker").setup(require("orgmode").capture)`。
- `lua/tests/smoke/orgmode_smoke.lua`: 新增 refile picker smoke，覆盖候选构建、选择 headline 与取消。
- `tests/smoke/run.sh`: 将 `SMOKE_ROOT_DIR` prepend 到 runtimepath，确保 worktree 内新增 smoke case 不被主工作区旧模块遮蔽。
- `skills/legion-workflow/references/orgmode-legion-workflow.md`: 更新 refile 目标选择说明为 picker 候选列表。

## Verification / Review Status

- `refile_picker_builds_file_and_headline_candidates`: PASS。
- `refile_picker_selects_and_cancels_destination`: PASS。
- worktree spec-level patch 断言：PASS，输出 `picker_patched true`。
- `ALLOW_UNPINNED_ORGMODE=1 bash tests/smoke/run.sh`: PASS，22 个 smoke case 全部通过。
- `git diff --check`: PASS。
- `docs/review-rfc.md`: PASS。
- `docs/review-change.md`: PASS。
- `stylua --check ...`: 未运行成功，当前机器没有 `stylua`。

## Risks and Limits

- 真实 TUI 弹窗没有截图验证。当前 headless 证据证明 refile 会调用 `vim.ui.select`，实际视觉依赖 Snacks picker 接管。
- patch 依赖 orgmode.nvim 内部 `_get_autocompletion_files()` 和 headline API。模块保留 fallback，并用 smoke case 覆盖当前 return shape。
- 多个 headline 同名时，当前候选 label 包含文件路径但不额外显示 outline path。本任务不扩展 disambiguation。

## Reviewer Checklist

- [ ] 确认 `org_refile_picker` 的 destination return shape 与 orgmode refile 移动逻辑一致。
- [ ] 确认 fallback 不会在 picker 不可用时破坏原始 orgmode 行为。
- [ ] 确认新增 smoke 覆盖用户指出的“可见候选列表”入口，而不只是配置值。
- [ ] 确认 runner runtimepath 改为 prepend worktree 是合理的测试隔离修复。

## Render Handoff

当前仓库没有现成 HTML preview workflow。`docs/report-walkthrough.html` 采用 artifact-only / local render，原因和 reviewer path 记录在 `docs/render-handoff.md`。

## Next Stage

将 walkthrough 交给 `pr-html-render` 记录 render handoff，然后执行 `legion-wiki` 写回与 git-worktree-pr lifecycle。`docs/pr-body.md` 仅作为 PR 创建输入，不代表 checks、review、merge、cleanup 或主工作区 refresh 已完成。

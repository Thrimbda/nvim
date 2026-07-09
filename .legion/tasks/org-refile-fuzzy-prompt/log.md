# org-refile-fuzzy-prompt Log

## 2026-07-09

- 入口：用户要求修复 refile 只有单输入框、不提示 fuzzy search 的问题，并显式要求使用 Legion workflow。
- 入口判断：仓库存在 `.legion/`，请求属于修改型多步骤工程任务；没有指定既有 task id，进入 `brainstorm`。
- 现状：`lua/plugins/orgmode.lua` 当前设置 `ui.input.use_vim_ui = true`；orgmode 本地默认值是 `false`。orgmode 的 refile destination 已有 `autocomplete_refile()`，使用 `vim.fn.matchfuzzy` 生成候选。
- 决策：低风险 fast track，优先恢复 orgmode 原生 input completion 路径，而不是新增 Snacks/Telescope picker refile。
- Git envelope：主工作区已有未提交 `lazy-lock.json`，本任务在 `.worktrees/org-refile-fuzzy-prompt/`、分支 `codex/org-refile-fuzzy-prompt` 中实施，base ref 为 `origin/master`。
- 纠偏：初次 materialization 误落主工作区；已删除主工作区中由本任务创建的 task docs，并重新写入隔离 worktree。
- Engineer：删除 `lua/plugins/orgmode.lua` 中 `ui.input.use_vim_ui = true` 覆盖，让 refile 回到 orgmode 默认 input completion；同步更新 `skills/legion-workflow/references/orgmode-legion-workflow.md` 的 refile 输入说明。
- Verify-change：`rg` 确认配置覆盖消失；本地 orgmode 默认 `use_vim_ui=false`；worktree spec-level 断言 `cfg.ui == nil`；`Capture.autocomplete_refile("ntl")` 返回 `/org/ntnl.org/`；`ALLOW_UNPINNED_ORGMODE=1 bash tests/smoke/run.sh` 全部通过。
- Review-change：PASS。未发现 blocking findings、scope 外实现改动或安全触发条件；残余风险为未做交互式 UI 截图验证以及 smoke 使用 unpinned 本地 orgmode runtime。
- Report-walkthrough：生成 `docs/report-walkthrough.html`、`docs/report-walkthrough.md` 与 `docs/pr-body.md`。
- pr-html-render：仓库无现成 HTML preview workflow；新增 Pages preview 超出本任务 scope，因此记录 `docs/render-handoff.md`，本次采用 artifact-only / local render。
- Legion-wiki：新增 `.legion/wiki/tasks/org-refile-fuzzy-prompt.md`；更新 wiki index、log 和 `patterns.md`，记录 orgmode refile input completion 当前结论。

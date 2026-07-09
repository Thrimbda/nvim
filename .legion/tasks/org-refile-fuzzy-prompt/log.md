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
- Reopened：用户重启后反馈 `<leader>or` 仍是单输入框，指出上一轮未完成图一式 fuzzy search 候选列表。诊断确认当前运行时 `orgmode.config.ui.input.use_vim_ui=false` 且 `<Space>or` 指向 orgmode refile；问题是 orgmode 原生 `input()` completion 本身不会主动显示 picker/list 候选。
- Contract update：验收改为“refile 打开可见候选列表/picker，包含文件与未完成 headline destination，并能 fuzzy 过滤”；设计升级为 patch `orgmode.capture.get_destination()` 使用 `vim.ui.select` / Snacks picker。
- Git envelope：本次 follow-up 在 `.worktrees/org-refile-fuzzy-prompt/`、分支 `codex/org-refile-fuzzy-picker` 中实施，base ref 为 `origin/master`；主工作区仍有用户既有 `lazy-lock.json` 修改，保持不碰。
- Spec-rfc：重写 `docs/rfc.md` 为标准 RFC，采用 `org_refile_picker` patch `orgmode.capture.get_destination()` 的方案。
- Review-rfc：PASS，无 blocking findings；允许进入实现。
- Engineer：新增 `lua/org_refile_picker.lua`，在 orgmode setup 后 patch `orgmode.capture.get_destination()` 使用 `vim.ui.select`/Snacks picker 展示文件与 headline destination；更新 orgmode workflow 说明；新增 smoke 用例覆盖候选构建、选择 headline 和取消 refile。
- Verify-change：新增 picker targeted smoke 通过；worktree spec-level patch 断言输出 `picker_patched true`；修复 smoke runner 为 prepend `SMOKE_ROOT_DIR`，避免 worktree 被主配置旧 test module 遮蔽；`ALLOW_UNPINNED_ORGMODE=1 bash tests/smoke/run.sh` 全部 22 个 case 通过；`git diff --check` 通过；`stylua` 不可用。
- Review-change：PASS，无 blocking findings；确认实现替换的是 refile destination 共同入口，返回 shape 保持 orgmode 原生移动逻辑需要的 `{ file, headline? }` 或 `false`。
- Report-walkthrough：重写 `docs/report-walkthrough.md`、`docs/report-walkthrough.html` 与 `docs/pr-body.md` 为 follow-up picker 交付视角；HTML artifact 通过结构与质量门检查；`pr-html-render` 判定当前仍采用 artifact-only / local render，并更新 `docs/render-handoff.md`。
- Legion-wiki：更新 task summary 和 patterns，明确上一轮“原生 input completion”结论已被 supersede；当前有效模式是 patch destination selection 到 `vim.ui.select` / Snacks picker，同时保留 orgmode refile 移动语义。

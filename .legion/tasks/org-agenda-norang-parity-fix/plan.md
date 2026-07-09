# org-agenda-norang-parity-fix

## Contract

- `name`: Norang agenda parity fix
- `taskId`: `org-agenda-norang-parity-fix`
- `goal`: 以 Emacs 原生 Norang agenda 工作流为 baseline，修复 Neovim/orgmode.nvim block agenda 的 section 顺序、标题和任务归类，并把 `PROJECT/STUCK/PROJECT_TASK/ARCHIVE_CANDIDATE` 改成非物化的虚拟 agenda 分类。
- `problem`: 旧实现把 project/stuck/archive 等派生状态写回 org 文件，偏离 Emacs Org/Norang 的原生路线；当前 `:Org agenda b` 同时存在 section 顺序、标题与 project task 分类偏差。

## Acceptance

- `b` block agenda 的 section 顺序与截图 baseline 对齐：day agenda、`Tasks to Refile`、`Stuck Projects`、`Projects`、`Project Next Tasks`、`Project Subtasks`、`Standalone Tasks`、`Waiting and Postponed Tasks`、`Tasks to Archive`。
- Section 标题使用 Emacs baseline 语义，避免当前 `Refile`、`Next actions`、`Waiting`、`Hold`、`Archive Candidates` 这类偏离标题出现在 block view 中。
- Project 相关条目使用 `PROJECT` / `STUCK` / `PROJECT_TASK` 虚拟标签表达 Norang skip-function 语义，不把这些状态写回 org 文件。
- Standalone 与 waiting/hold 的 matcher 不把 project headline、refile inbox 或 archive candidate 错归到普通任务区。
- 更新或新增测试/静态断言，能在无真实私人 org 文件的情况下验证 custom command 结构、虚拟匹配和 refresh 不改写 org 文本。
- 保持现有 clock、capture、refile picker 行为不变；cleanup 继续只作为旧物化标签迁移工具。

## Assumptions

- 截图二是本轮唯一视觉 baseline；Norang 原始 Emacs 配置只作为语义背景，不强制逐行复刻 elisp。
- orgmode.nvim custom command 支持的 `agenda` / `tags` / `tags_todo` matcher 是本轮实现边界。
- 现有 `org_legion` 规则可以复用来计算 project、stuck project 和 archive candidate；本轮允许补一个 `PROJECT_TASK` 虚拟标签，专门区分项目内子任务。
- 用户当前 `lazy-lock.json` 改动不是本任务制造的，不纳入本轮修复。

## Constraints

- 修改必须通过 Legion workflow，并在稳定 contract 后进入 `git-worktree-pr` envelope。
- 不修改用户的私有 org 数据文件。
- 不把 Emacs skip function 移植成大块 Lua renderer；优先复用既有规则和 orgmode.nvim matcher，但分类必须在内存/查询层完成。
- 不引入新依赖，不更改 orgmode.nvim 上游 pin，除非后续证明配置层无法修复。

## Scope

- `lua/plugins/orgmode.lua`
- `lua/org_legion/**`
- `lua/tests/smoke/orgmode_smoke.lua`
- `tests/smoke/run.sh`
- `skills/legion-workflow/**`
- `.legion/tasks/org-agenda-norang-parity-fix/**`

## Non-Goals

- 不重做 Norang 全套 GTD workflow。
- 不修改 clock/punch/capture 的状态机。
- 不调整颜色主题、字体或截图中的 editor UI。
- 不对真实 `~/OneDrive/cone/**/*.org` 内容做迁移或批量修正。

## Risks

- orgmode.nvim matcher 语法与 Emacs tags/todo skip function 不完全等价，可能只能做到视觉和分类近似。
- 若 matcher 对 `TODO` keyword 查询支持有限，部分分类可能需要测试验证后微调。
- 当前 screenshot baseline 是某一天的数据；空 section 是否显示受 orgmode.nvim 行为影响，可能不能完全复制 Emacs 的空块表现。

## Design Summary

- 将 `b` custom command 改为 Norang block order，以 day agenda 作为首块。
- 用 `Tasks to Refile` 替代 `Refile`，并继续忽略 scheduled/deadline inbox 项。
- 保留 `PROJECT+STUCK` 作为 `Stuck Projects`，使用 `PROJECT-STUCK` 作为 `Projects`，并排除虚拟/旧物化标签继承以免项目子任务串入项目父节点区。
- 新增 `PROJECT_TASK` 虚拟标签，标记项目内 active 子任务。
- 新增 `Project Next Tasks`：匹配 `NEXT+PROJECT_TASK-REFILE`。
- 新增 `Project Subtasks`：匹配 `TODO+PROJECT_TASK-REFILE-ARCHIVE_CANDIDATE`，把处于 project subtree 的普通 TODO 子任务与 standalone task 分开。
- 将 waiting/hold 合并为 `Waiting and Postponed Tasks`。
- 将 archive section 标题改为 `Tasks to Archive`。
- 增加轻量结构测试与虚拟匹配测试，直接断言 `b` 命令 block order/header/matcher、refresh 不改写 org 文本、`PROJECT/STUCK/PROJECT_TASK` 可通过 agenda search 语义命中。

## Phases

- `brainstorm`: 收敛并物化本 contract。
- `engineer`: 在 worktree 中实现 agenda parity 修复与测试。
- `verify-change`: 运行 smoke/静态测试并记录结果。
- `review-change`: 审查修复是否满足 baseline 且未扩大 scope。
- `report-walkthrough`: 生成评审者 handoff。
- `legion-wiki`: 写回当前真源摘要。

## Design Index

- Design-lite: `docs/rfc.md`

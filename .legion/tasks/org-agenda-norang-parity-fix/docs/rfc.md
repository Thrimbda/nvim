# Design-lite: Norang agenda parity fix

## Decision

使用现有 orgmode.nvim `org_agenda_custom_commands` 和 `org_legion` 规则修复 block agenda 结构；补充一个 `PROJECT_TASK` 虚拟标签区分项目内子任务，并把 `PROJECT/STUCK/PROJECT_TASK/ARCHIVE_CANDIDATE` 从写回 org 文件的派生状态改为 agenda 查询时的内存分类。

## Baseline

用户提供的 Emacs 原生截图显示 Norang block agenda 顺序为：

1. day agenda
2. `Tasks to Refile`
3. `Stuck Projects`
4. `Projects`
5. `Project Next Tasks`
6. `Project Subtasks`
7. `Standalone Tasks`
8. `Waiting and Postponed Tasks`
9. `Tasks to Archive`

当前 nvim 截图与代码显示顺序为 `Refile` -> `Today` -> `Next actions` -> `Waiting` -> `Hold` -> `Stuck Projects` -> `Projects` -> `Standalone Tasks` -> `Archive Candidates`，因此 section order、标题和 project task 分类都偏离 baseline。

## Approach

- 把 day agenda 移到 `b` command 第一块，并移除 `Today` overriding header，让 orgmode.nvim 使用 day heading。
- 将 inbox block 标题改为 `Tasks to Refile`。
- 将 project blocks 调整为 Norang order：`Stuck Projects`、`Projects`、`Project Next Tasks`、`Project Subtasks`。
- 让 `PROJECT/STUCK/PROJECT_TASK/ARCHIVE_CANDIDATE` 不参与 tag inheritance，避免旧物化标签从 project 父节点和项目子任务互相串区。
- 新增 `PROJECT_TASK`：active 子任务只要位于 project 父节点下且自身不是 project，就在内存索引中获得该虚拟标签。
- 安装 `OrgFile.apply_search` adapter：普通 tags 查询走 orgmode.nvim 原生路径；只有查询包含虚拟标签时，才临时把当前 headline 的虚拟标签并入 search 输入。
- `:OrgLegionRefresh` 只重建内存索引，不再 `set_lines` 或 `writefile`；cleanup 保留为旧物化标签迁移工具。
- 将 WAITING 和 HOLD 合并为 `Waiting and Postponed Tasks`。
- 将 archive block 标题改为 `Tasks to Archive`。
- 为 custom command 增加结构级测试，避免真实 agenda 文件和日期影响断言。

## Verification

- 运行新增结构测试，验证 `b` custom command 的 block 顺序、标题、tag inheritance 排除和 matchers。
- 运行新增 project-task refresh 测试，验证项目父节点与项目子任务的虚拟标签分离，且 org 文本不被改写。
- 运行现有 smoke 套件或至少运行新增 case 与相关 org_legion case，确认没有破坏虚拟分类、cleanup 与基础 workflow。

## Rollback

本轮改配置、`org_legion` 虚拟索引/adapter、测试和文档；若 agenda 输出或 smoke 失败，回滚对应提交即可恢复旧视图与旧 refresh 行为。

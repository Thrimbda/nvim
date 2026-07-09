# Review Change: org-agenda-norang-parity-fix

## Decision

PASS

## Blocking Findings

无 blocking findings。

## Scope Review

改动保持在 contract 范围内：

- `lua/plugins/orgmode.lua`：Norang-style block agenda 顺序、标题、matcher；agenda 快捷键打开前刷新虚拟 agenda 索引。
- `lua/org_legion/**`：新增虚拟标签索引/search adapter 与 `PROJECT_TASK` 规则，避免仅依赖 `PROJECT` tag inheritance 导致项目父节点与子任务串区。
- `lua/tests/smoke/orgmode_smoke.lua` / `tests/smoke/run.sh`：新增 agenda 结构与 project-task refresh 覆盖。
- `skills/legion-workflow/**` 与 task docs：同步行为说明和证据。

未修改 clock、capture、refile picker、上游 orgmode pin 或用户私有 org 数据文件。

## Correctness Review

- `b` command 顺序与截图 baseline 对齐：day agenda -> Tasks to Refile -> Stuck Projects -> Projects -> Project Next Tasks -> Project Subtasks -> Standalone Tasks -> Waiting and Postponed Tasks -> Tasks to Archive。
- `PROJECT_TASK` 将 project child tasks 从 project parent 分类中拆出，配合 `org_tags_exclude_from_inheritance` 避免旧物化标签继承导致 `Projects` 区重复显示项目子任务。
- `OrgLegionRefresh` 现在只重建内存索引；`PROJECT/STUCK/PROJECT_TASK/ARCHIVE_CANDIDATE` 不再写回 org 文件，符合 Emacs Org/Norang 的动态 agenda 分类路线。
- `open_agenda_after_legion_refresh()` 让 `<F12>` / `<Leader>oab` / `<Leader>oan` / `<Leader>oas` 在打开依赖虚拟标签的 agenda 前刷新索引，修复 project 父节点未刷新导致错分的问题。
- `refresh_all` 失败时只 warning 并继续打开 agenda，符合现有 workflow 的非阻塞可用性取舍。

## Verification Review

验证证据充分：

- `agenda_block_matches_norang_baseline`: PASS，覆盖 block order/header/matcher/tag inheritance/keymap refresh。
- `legion_refresh_indexes_stuck_project`: PASS，覆盖 stuck project 虚拟标签、search 命中和 org 文本不被改写。
- `legion_refresh_indexes_project_tasks`: PASS，覆盖 project parent 与 project child 虚拟标签分离。
- `ALLOW_UNPINNED_ORGMODE=1 bash tests/smoke/run.sh`: PASS，完整 smoke 通过。
- `git diff --check`: PASS。

## Security Review

未命中 security trigger。改动不涉及 auth、权限、token、session、密钥、加密、协议边界、用户输入进入高权限路径、数据暴露或多租户隔离。

## Non-Blocking Notes

- `stylua` 在当前环境不可用，已在 test report 中记录为 skipped。
- Full smoke 使用本机 unpinned orgmode runtime，这是现有 runner 的显式 fallback，残余风险可接受。

# Test Report: org-agenda-norang-parity-fix

## 验证选择

本次改动同时触及 agenda 配置结构和 `org_legion` 虚拟标签/search adapter，因此验证分两层：

- Targeted smoke：直接证明 `b` block agenda 顺序、标题、matcher、虚拟标签 inheritance 排除，以及 `PROJECT/STUCK/PROJECT_TASK` 虚拟分类规则。
- Full smoke：确认 clock、capture、refile picker、todo trigger、virtual refresh/cleanup 等既有路径没有回归。

## Commands

```bash
ALLOW_UNPINNED_ORGMODE=1 bash tests/smoke/run.sh
```

Result: PASS

```text
WARN: using unpinned orgmode runtimepath: /Users/c1/.local/share/nvim/lazy/orgmode
PASS agenda_block_matches_norang_baseline
PASS legion_refresh_indexes_stuck_project
PASS legion_refresh_indexes_project_tasks
PASS legion_e2e_integrated_flow
All smoke cases passed.
```

```bash
git diff --check
```

Result: PASS

## Skipped / Notes

- `stylua` 未安装，无法运行 formatter check：`command -v stylua` 返回 exit code 1。
- `tests/smoke/run.sh` 没有可执行位，直接执行返回 `permission denied`；已使用 `bash tests/smoke/run.sh` 运行同一脚本。
- Full smoke 使用本机 unpinned orgmode runtime：`/Users/c1/.local/share/nvim/lazy/orgmode`。这是当前仓库 smoke runner 支持的显式 fallback。
- `git diff --check`: PASS。

## 结论

验证 PASS。新增测试覆盖 Norang block agenda baseline 结构、`PROJECT/STUCK/PROJECT_TASK` 虚拟分类、refresh 不改写 org 文本，以及完整 org workflow 回归。

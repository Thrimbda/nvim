# nvim-orgmode-norang-workflow

## 目标

Add a Norang-style orgmode workflow for Neovim with custom agenda views, punch in/out continuous clocking, and supporting docs/PR body.

## 要点

- Define custom agenda views (block/NEXT/REFILE) in orgmode config
- Implement punch in/out glue to keep clocks running with default task/parent fallback
- Update orgmode config and keymaps while preserving existing paths
- Document setup and daily usage for the workflow

## 范围

- lua/plugins/orgmode.lua
- lua/org_punch.lua
- docs/orgmode-norang-workflow.md

## 阶段概览

1. **Design-lite** - 2 个任务
2. **Implementation** - 3 个任务
3. **Verification & Review** - 2 个任务
4. **Reporting** - 1 个任务

---

*创建于: 2026-02-06 | 最后更新: 2026-02-06*

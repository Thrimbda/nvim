# nvim-orgmode-norang-plugin

## TITLE

Norang 工作流补齐协议：org_norang 派生标签与刷新机制

## SLUG

nvim-orgmode-norang-plugin

## 目标

在现有 nvim-orgmode 配置基础上新增 `org_norang` 插件，补齐 Norang 工作流中项目识别、卡住项目识别、归档候选与 block agenda 自动化能力。

## 设计真源

- RFC 文档是唯一设计真源：`.legion/tasks/nvim-orgmode-norang-plugin/docs/rfc.md`

## 摘要（执行导向）

- 核心流程：`setup -> BufWritePost 单文件刷新 / OrgNorangRefresh 全量刷新 -> 派生标签回写 -> agenda blocks 呈现`。
- 接口变更：新增 `org_norang` 模块接口（`setup/refresh_all/refresh_file`）与命令 `:OrgNorangRefresh`；`orgmode.lua` 接入新增 blocks。
- 文件变更清单：限定 `lua/plugins/orgmode.lua`、`lua/org_punch.lua`、`lua/org_norang/**`、`docs/orgmode-norang-workflow.md` 与 RFC 路径。
- 验证策略：以 RFC 的 R1-R15 规范条款映射手工断言（T1-T10），先跑 `approx`，再对照 `precise`。

## 范围

- lua/plugins/orgmode.lua
- lua/org_punch.lua
- lua/org_norang/**
- docs/orgmode-norang-workflow.md
- .legion/tasks/nvim-orgmode-norang-plugin/docs/rfc.md

## 阶段概览

1. **阶段 1: 调查与范围确认** - 1 个任务
2. **阶段 2: 设计循环（RFC + 审查）** - 2 个任务
3. **阶段 3: 设计门禁** - 1 个任务

---

*创建于: 2026-02-07 | 最后更新: 2026-02-07*

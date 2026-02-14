# nvim-orgmode Norang 实现 Walkthrough 报告

## 1) 变更概览（文件与能力）

### 目标与范围

- 目标：基于设计真源 RFC 落地 `org_norang`，完成命令、刷新协议、agenda 扩展、与 `org_punch` 协同，并形成可验证交付。
- 实现范围（绑定 Scope）：`lua/plugins/orgmode.lua`、`lua/org_punch.lua`、`lua/org_norang/**`、`docs/orgmode-norang-workflow.md`。
- 设计真源：`.legion/tasks/nvim-orgmode-norang-plugin/docs/rfc.md`。

### 代码与文档改动清单

- `lua/org_norang/init.lua`
  - 新增 `setup/refresh/reload/cleanup` 命令注册与状态管理。
  - 接入 `BufWritePost` 自动刷新（仅 agenda 范围）。
  - 配置校验失败统一进入 `S5/E_CFG_INVALID`。
- `lua/org_norang/parser.lua`
  - 提供 headline/TODO/tag 解析能力，服务派生标签计算。
- `lua/org_norang/rules.lua`
  - 实现 `PROJECT/STUCK/ARCHIVE_CANDIDATE` 的 `approx` 规则判定。
- `lua/org_norang/refresh.lua`
  - 实现单文件与全量刷新事务、路径级互斥、冲突检测（`changedtick/mtime`）、汇总统计。
  - 在 `memory_only` 下遵循仅处理已加载 buffer，未加载文件记 `skipped_unloaded`。
- `lua/org_norang/cleanup.lua`
  - 实现派生标签清理（dry-run/apply），并在 apply 路径增加锁与冲突检测。
- `lua/plugins/orgmode.lua`
  - 接入 `org_norang.setup`，扩展 `b` 视图：`PROJECT+STUCK`、`PROJECT-STUCK`、`ARCHIVE_CANDIDATE`。
- `lua/org_punch.lua`
  - 增加轻量协同校验提示；保持 keep-running 主流程不阻断。
- `docs/orgmode-norang-workflow.md`
  - 补充命令、排错、回滚与 cleanup 使用说明。

## 2) 关键实现决策（为什么这么做）

- 以 RFC 作为唯一设计真源，避免实现中口径漂移，确保 R1-R21 可追踪验收。
- 固定 V1 `memory_only`：避免隐式加载与自动写盘副作用，保持用户可控的二次保存模型。
- 全量刷新只处理已加载 buffer：与 RFC R12/R13/T16 对齐，未加载 agenda 文件统一记 `skipped_unloaded`。
- 强化错误态收敛：`setup/reload` 对非法 `opts` 做类型门禁，错误统一收敛 `S5/E_CFG_INVALID`，避免崩溃路径。
- cleanup apply 引入锁与快照冲突检测：避免覆盖用户最新修改，保障回滚操作安全性。

## 3) 验证结果摘要

### 测试结论

- 测试报告：`.legion/tasks/nvim-orgmode-norang-implementation/docs/test-report.md`。
- 执行方式：逐文件运行 `nvim --headless -u NONE '+set rtp+=.' '+luafile <FILE>' '+qa'`。
- 结果：7/7 PASS（`lua/org_norang/*.lua`、`lua/plugins/orgmode.lua`、`lua/org_punch.lua`）。
- 说明：本轮验证口径为“最小必选自动化 + RFC 手工断言清单”。

### 审查结论

- 代码评审：`.legion/tasks/nvim-orgmode-norang-implementation/docs/review-code.md`，结论 `PASS-WITH-CHANGES`，无 blocking。
- 安全评审：`.legion/tasks/nvim-orgmode-norang-implementation/docs/review-security.md`，结论 `PASS-WITH-CHANGES`，无 blocking。
- 关键闭环：此前安全 FAIL 路径（`setup/reload` 非 table opts）已关闭，验证为“不崩溃 + false + S5”。

### benchmark 结果或门槛说明

- 本次未提供独立 benchmark 数据。
- 原因：当前交付门槛聚焦协议正确性、语法可加载性与安全收敛；仓库尚无稳定的性能基准脚本。
- 现阶段门槛：以 RFC 语义一致性（R1-R21）与最小校验 PASS 作为上线前准入条件。

## 4) 审查结论与剩余风险

### 综合结论

- 当前实现可进入交付：核心能力落地、最小校验通过、代码/安全审查均无阻塞项。
- 结论级别：`PASS-WITH-CHANGES`（存在可改进项，但不阻断当前版本）。

### 可观测性现状

- 已具备 `vim.notify` 级别的运行时提示与错误回传。
- `observability.log_level` 已有配置校验，但日志分级过滤与持久化审计尚未完整闭环。

### 剩余风险

- 高频保存场景下，agenda 文件集合重复展开可能造成性能抖动（建议做缓存/失效机制）。
- `refresh.debounce_ms` 当前语义与实现仍有差距（需补齐去抖或文档声明未启用）。
- 审计追踪不足：缺少结构化持久日志，不利于事后归因。
- 极端情况下若内部状态被异常篡改（如 `M._user_opts` 非 table），`reload` 合并前仍建议做归一化保护。

### 回滚路径

- 关闭 `org_norang.setup` 与相关 agenda 扩展。
- 执行 `:OrgNorangCleanupDerivedTags`（先 dry-run，后 `!` apply）清理派生标签副作用。
- 验证仅派生标签被清理，用户标签保持不变。

## 5) 下一步建议（可执行）

1. 在 `refresh.lua` 增加 agenda 集合缓存与失效策略，降低高频触发下 glob 开销。
2. 在 `init.lua` 落地按 buffer/path 的 debounce，真正消费 `refresh.debounce_ms`。
3. 统一日志出口并接入 `log_level` 过滤，补充可选 JSONL 审计记录（命令、错误码、phase 迁移、时间戳）。
4. 为 `setup/reload` 增加回归用例（`nil/table/string/number`），固化“无崩溃 + 错误码一致 + phase 收敛”。
5. 补充轻量 benchmark 脚本（大 agenda 文件集）并设定基线阈值，形成后续版本性能门禁。

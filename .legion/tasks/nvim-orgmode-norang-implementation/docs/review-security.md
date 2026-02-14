# Security Review Report

## 结论
PASS-WITH-CHANGES

本次复审重点结论（针对 setup/reload 非 table opts 防御）：
- `lua/org_norang/init.lua:249` 已在 `setup(opts)` 入口做类型门禁，`opts` 非 table 时稳定返回 `false` 并进入 `S5/E_CFG_INVALID`。
- `lua/org_norang/init.lua:291` 已在 `reload(opts)` 入口做类型门禁，`opts` 非 table 时稳定返回错误，不触发 `vim.tbl_deep_extend` 崩溃路径。
- 实测（headless）`setup("bad")`、`reload("bad")` 均为“无崩溃 + false + phase=S5”，此前 FAIL 条件已消除。

## Blocking Issues
- [ ] 无（本轮未发现阻塞级安全问题）。

## 安全建议（非阻塞）
- `lua/org_norang/init.lua:296` [Tampering/Denial of Service] - `reload(opts)` 依赖 `M._user_opts` 为 table；若被外部运行时篡改为非 table，`vim.tbl_deep_extend` 仍可能异常。建议在 merge 前增加 `type(M._user_opts) == "table"` 归一化保护。
- `lua/org_norang/init.lua:279` [Repudiation] - 当前仅 `vim.notify`，缺少持久化审计轨迹（调用来源/错误码/时间戳）。建议提供可选结构化日志输出，便于追溯与归责。
- `lua/org_norang/refresh.lua` [Denial of Service] - agenda glob 在超大目录下可能带来性能抖动。建议增加匹配上限、超限告警和短路策略。

## 修复指导
1. 在 `reload` 合并配置前做状态归一化：`if type(M._user_opts) ~= "table" then M._user_opts = {} end`，防止内部状态被异常值污染后导致崩溃。
2. 为 `setup/reload` 增加回归用例：覆盖 `opts=nil/table/string/number`，断言“不崩溃 + 错误码一致 + phase 收敛”。
3. 增加可选审计通道（例如 JSONL）：记录命令名、配置校验失败原因、phase 迁移与时间戳。
4. 对 agenda 文件发现流程设置可配置阈值，超过阈值时只告警并跳过全量扩展。

## STRIDE 检查结果
- Spoofing（伪造）：无法评估（该模块无独立认证/凭证处理流程）。
- Tampering（篡改）：通过（外部输入 `opts` 的主要类型篡改路径已被入口校验拦截）。
- Repudiation（抵赖）：需改进（缺少持久化审计日志）。
- Information Disclosure（信息泄露）：通过（未见硬编码密钥；错误信息未暴露敏感数据）。
- Denial of Service（拒绝服务）：通过（此前由非 table opts 导致的初始化崩溃路径已关闭）。
- Elevation of Privilege（权限提升）：无法评估（无明确鉴权边界/权限域）。

## 额外检查
- 协议/状态机绕过：未发现可由非 table `opts` 触发的绕过路径，错误态可收敛至 `S5/E_CFG_INVALID`。
- 默认安全姿势（secure-by-default）：通过（`writeback=memory_only`、cleanup 默认 dry-run）。
- 依赖风险（CVE/过时版本）：无法评估（本轮未执行依赖清单与 CVE 扫描）。
- 密钥/凭证硬编码：未发现（仅发现普通语义变量 `token`，非凭证）。
- SUBTREE_ROOT 越界改动：未发现（按任务 scope 复核，未见越界改动证据）。

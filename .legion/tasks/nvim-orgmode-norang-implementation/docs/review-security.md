# Security Review Report

## 结论
PASS-WITH-CHANGES

本轮针对 `changedFiles` 与 `scope` 进行复核：未发现 scope 越界改动；未发现 blocking/high 级别安全问题。

## Blocking Issues
- [ ] 无（本轮未发现 blocking/high）。

## 安全建议（非阻塞）
- `lua/plugins/orgmode.lua:202` [Tampering] - `require("org_norang.todo_triggers").setup()` 的返回值未处理，若事件系统不可用会静默降级，导致“TODO 状态 -> 标签同步”策略被绕过（fail-open）。建议至少记录 `vim.notify` 警告并暴露健康状态。
- `lua/org_norang/todo_triggers.lua:79` [Repudiation] - 自动标签变更缺少审计痕迹（谁触发、何时触发、旧值/新值）。建议增加可选 debug/audit 日志（最小字段：todo_before/todo_after/tags_before/tags_after/file/line）。
- `lua/org_norang/todo_triggers.lua:40` [Tampering] - 依赖正则剥离行尾标签，若遇到非预期 tag 字符集或异常尾注，可能出现标签归一化偏差（数据完整性风险）。建议改为基于 headline/tag API 的结构化更新，避免字符串级拼接。
- `tests/smoke/run.sh:35` [Denial of Service] - headless case 执行未设置单 case 超时，异常插件状态可能导致 CI 卡死。建议为每个 case 增加超时包装（例如 `timeout`）和失败快照输出。
- `lua/tests/smoke/orgmode_smoke.lua:6` [Information Disclosure] - 测试内置固定 UUID（`DEFAULT_TASK_ID`）虽非敏感凭证，但建议在文档中明确“测试标识非生产密钥”，防止误用到真实数据。

## 修复指导
1. 对 `todo_triggers.setup()` 结果做强制检查：失败时记录高可见度告警，并在状态页或命令输出中暴露“触发器未启用”。
2. 在 `todo_triggers` 增加结构化审计（可配置开关，默认关闭）：至少记录触发动作、文件路径、headline 行号与标签差异。
3. 用结构化节点更新替代正则拼接，确保标签处理与 orgmode 解析语义一致，降低异常文本导致的数据篡改风险。
4. 为 smoke runner 增加单测超时与诊断输出，避免拒绝服务式阻塞（卡死占用 runner）。

## STRIDE 检查结果
- Spoofing（伪造）：无法评估（本次改动不含认证/凭证流程）。
- Tampering（篡改）：通过（未见直接外部输入注入执行），但存在 fail-open 与字符串归一化完整性风险（见非阻塞建议）。
- Repudiation（抵赖）：需改进（自动变更缺少持久化审计）。
- Information Disclosure（信息泄露）：通过（未发现硬编码密钥/凭证；错误提示未暴露敏感数据）。
- Denial of Service（拒绝服务）：通过（无明显资源放大路径），但测试执行存在超时保护缺口（非阻塞）。
- Elevation of Privilege（权限提升）：无法评估（无独立鉴权边界与权限模型变更）。

## 额外检查
- 协议/状态机绕过：发现潜在 fail-open（触发器 setup 失败时未显式告警），建议收敛为 fail-closed 或可观测降级。
- 默认安全姿势（secure-by-default）：总体可接受（memory-only 路径不自动写盘），建议补全失败可观测性。
- 依赖风险（CVE/过时版本）：无法评估（本轮变更未涉及依赖版本升级，也未执行 CVE 扫描）。
- 密钥/凭证硬编码：未发现。
- Scope 越界改动：未发现（`changedFiles` 均在声明 `scope` 内）。

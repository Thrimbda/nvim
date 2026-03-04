# 项目作战手册

## [约定] Parity failure payload 必须是可机器解析的 JSON
- 来源任务：`orgmode-norang-e2e-parity-suite`（2026-03-04）
- 规则：parity assertions 失败时应输出 `PARITY_FAIL {json}`。
- 必填字段：`v`、`id`、`phase`、`case`、`expected`、`actual`。
- 理由：保证 CI 稳定解析，并支持基于 ID 的分诊。

## [约定] Smoke runner 的 runtimepath 设置必须 secure-by-default
- 来源任务：`orgmode-norang-e2e-parity-suite`（2026-03-04）
- 规则：避免将不可信路径注入 Neovim Ex 命令。
- 使用受控 Lua 追加路径并做校验（`isdirectory`、禁用字符）。
- 回退到 `$HOME` 的未固定 orgmode 路径必须显式 opt-in（`ALLOW_UNPINNED_ORGMODE=1`）。

## [陷阱] 父任务回退测试不应接受默认任务回退
- 来源任务：`orgmode-norang-e2e-parity-suite`（2026-03-04）
- 现象：若测试允许 `parent OR default`，`clock_out_keep_running` 可能“假绿”。
- 规则：保持 NP-006A 严格（存在父任务时必须回父任务），NP-006B 专门覆盖默认任务回退分支。

# 安全评审报告

## 结论
PASS

## 阻塞问题
- [ ] (none)

## 建议（非阻塞）
- 已关闭项确认：`tests/smoke/run.sh:19` 已通过 `safe_path()` + `vim.opt.rtp:append()` 受控注入 runtimepath，且对 `|\r\n\t` 与目录存在性做校验，上一轮命令注入风险（Tampering/EoP）已关闭。
- 已关闭项确认：`tests/smoke/run.sh:9` 仅在 `ALLOW_UNPINNED_ORGMODE=1` 时才允许回退到 `$HOME` 路径，默认拒绝并退出，上一轮 secure-by-default 缺陷（Spoofing/Tampering）已关闭。
- `lua/org_punch.lua:91`：`expand_org_files()` 仍可能在超大目录树触发高 I/O 扫描。建议增加文件数量/耗时上限，并在超限时给出可审计告警（DoS）。
- `lua/org_punch.lua:623`：`keep_clock_running` 为进程级状态，建议增加状态迁移审计字段（action, pre_state, post_state, error_code）以提升可追溯性（Repudiation）。
- 依赖与供应链：本次范围未包含 lockfile/CVE 明细，建议在 CI 增加 `osv` 或等效扫描，并对 orgmode 来源版本做门禁。

## 修复指引
1. 维持当前 secure-by-default：CI 保持 `ALLOW_UNPINNED_ORGMODE=0`，仅在本地排障时临时启用。
2. 为 `expand_org_files()` 增加扫描预算（max_files/max_ms）与超限错误码，避免目录异常导致阻塞。
3. 为 punch/clock 关键状态变更补充结构化日志与失败计数，便于后续审计、告警与回归定位。

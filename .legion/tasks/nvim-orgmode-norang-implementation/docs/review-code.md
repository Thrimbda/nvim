# Code Review Report

## 结论
PASS-WITH-CHANGES

> 基于有限信息的评审：本次按你给定范围复审当前工作区实现，已审查文件：
> `lua/org_norang/init.lua`、`lua/org_norang/parser.lua`、`lua/org_norang/rules.lua`、`lua/org_norang/refresh.lua`、`lua/org_norang/cleanup.lua`、`lua/plugins/orgmode.lua`、`lua/org_punch.lua`、`docs/orgmode-norang-workflow.md`。

## Blocking Issues
- [ ] (none)

## 建议（非阻塞）
- `lua/org_norang/refresh.lua:43` - `is_agenda_file()` 每次调用都会重新 `expand_agenda_files()` 构建集合；在 `BufWritePost` 高频触发下会重复 glob，建议做缓存或增量失效，降低运行时开销。
- `lua/org_norang/init.lua:10` - `refresh.debounce_ms` 已配置校验但未看到实际节流逻辑，字段语义与行为存在偏差；建议实现 debounce 或在文档明确“当前版本未启用”。
- `lua/org_norang/init.lua:31` - `observability.log_level` 当前仅校验未参与日志过滤，建议统一通知出口按级别裁剪，保持配置一致性。

## 修复指导
1. 已关闭的上版 blocking 结论
   - agenda 边界：`BufWritePost` 回调已通过 `refresh.is_agenda_file(M._cfg, args.buf)` 做范围过滤（`lua/org_norang/init.lua:211`），`refresh_file` 也在入口拒绝非 agenda 文件（`lua/org_norang/refresh.lua:219`），该 blocking 已关闭。
   - 配置类型校验：`validate_cfg` 已补全关键字段类型守卫，并在 `setup` 中用 `pcall(validate_cfg, ...)` 吸收异常统一落入 `E_CFG_INVALID/S5`（`lua/org_norang/init.lua:67`、`lua/org_norang/init.lua:248`），该 blocking 已关闭。
2. 建议改进项的具体落地方式
   - agenda 集合缓存：在 `refresh.lua` 维护 `cfg` 级 memo（如按 `org_agenda_files` hash 缓存 `agenda_file_set`），在 reload/setup 后失效重建。
   - debounce：在 `BufWritePost` 回调层引入 `vim.defer_fn` + 按 buffer/path 去抖 map，读取并使用 `refresh.debounce_ms`。
   - log_level：封装统一 `notify(cfg, msg, level)` 过滤函数（按 `error/warn/info/debug`），让 `rules.lua` 的 precise 降级提示也走同一出口。

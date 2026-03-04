# 测试报告

## 命令
`bash tests/smoke/run.sh`

## 结果
PASS

## 摘要
- 最终时间戳：`2026-03-04 16:26:15 CST`。
- 最终覆盖数量：`16/16` 个 smoke cases 通过。
- 套件以 `All smoke cases passed.` 结束。
- 已覆盖关键对齐路径：punch in/out 行为、clock 状态迁移、Norang refresh/cleanup、capture handoff 与集成 e2e 流程。

## 失败项（如有）
- 无。

## 说明
- 选择该命令的原因：这是用户明确指定，且是本范围内规范、低成本的 smoke runner 入口。
- 考虑过的替代方案：直接调用 headless Lua/plenary（例如 `nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory lua/tests/smoke" -c qa`），但当前 wrapper 是更可靠的对齐检查入口。

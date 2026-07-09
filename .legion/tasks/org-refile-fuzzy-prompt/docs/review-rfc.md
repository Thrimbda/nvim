# Review RFC: Org refile fuzzy picker

## Decision

PASS。

## Blocking Findings

无。

## Review Notes

- 设计明确区分了上一轮失败原因：`use_vim_ui=false` 只恢复 orgmode 原生 `input()` completion，不会主动显示候选 picker。
- 采用 `vim.ui.select` 的方案能直接满足“可见候选列表”验收，并利用 Snacks picker 已有 fuzzy filtering。
- RFC 保留 orgmode 原有 `_refile_from_capture_buffer` / `_refile_from_org_file` 移动逻辑，只替换 destination 选择 UI，scope 可控。
- 回滚路径明确：删除 `org_refile_picker` 模块和 setup 调用即可回到 orgmode 默认 `get_destination()`。
- 验证计划覆盖文件候选、headline 候选、取消行为、mapping 保持和完整 smoke suite，足以支撑实现。

## Non-Blocking Suggestions

- 实现时应导出或保留可测试的 `build_items()`，避免只能通过真实 UI 验证候选构建。
- fallback 到原始 `get_destination()` 时应避免吞掉异常，至少让默认 orgmode 行为可继续工作。

## Implementation Gate

允许进入 `engineer`。

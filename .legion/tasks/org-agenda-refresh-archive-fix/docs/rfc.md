# Design-lite: Archive Done Keyword Parity and Refresh Diagnostics

## Context

PR #12 修复了 archive matcher 和月份规则，但配置仍只把 `DONE` / `CANCELLED` 当 done-state。Norang workflow 的 capture keywords 包含 `PHONE` / `MEETING`，这些在 Emacs baseline 中会进入 archive candidates。

同时，agenda wrapper 在 refresh 失败时只报告失败数量，用户无法知道是哪两个文件导致 `fail=2`。

## Decision

- 扩展 orgmode 和 org_legion 的 done keywords：`DONE`, `CANCELLED`, `PHONE`, `MEETING`。
- 保持 active keywords 不变：`TODO`, `NEXT`, `WAITING`, `HOLD`。
- 为 refresh summary 增加失败摘要格式化，通知中输出最多 3 个失败文件与错误原因。
- 保持 agenda 可用性：refresh 失败仍不阻止打开 agenda，但 warning 必须可定位。

## Verification

- 增加 smoke case 验证 `PHONE` / `MEETING` keyword 配置和 `PHONE` archive candidate。
- 增加 smoke case 验证 agenda wrapper 和 `OrgLegionRefresh` 通知包含失败文件名和错误消息。
- 运行 full smoke 与 `git diff --check`。

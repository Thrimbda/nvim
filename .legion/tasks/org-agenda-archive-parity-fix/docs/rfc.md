# Design-lite: Norang Archive Candidate Parity

## Context

PR #11 修复了 block agenda 顺序、项目虚拟标签和 project task 分类，但 `Tasks to Archive` 仍用近似规则表达 Norang archive skip function。Norang baseline 的 archive block 使用 `tags "-REFILE/"`，再由 `bh/skip-non-archivable-tasks` 过滤。

## Decision

采用低风险 design-lite：

- 保持 `ARCHIVE_CANDIDATE` 为内部虚拟标签。
- 将 archive candidate 规则改为 Norang 月份前缀规则：done-state todo 只有在子树里没有本月或上月 `YYYY-MM-` 时间戳时才可归档。
- agenda archive block 使用 `-REFILE/` matcher，并通过自定义 block option 请求 virtual search adapter 执行 archive candidate filter。

## Alternatives

- 继续直接匹配 `ARCHIVE_CANDIDATE`：实现简单，但偏离 Emacs baseline，且用户会把实现标签当作业务标签。
- 移植完整 elisp skip function：语义最像，但会把 orgmode.nvim matcher 逻辑变成一套并行 renderer，改动过大。

## Verification

- 增加 targeted smoke case：DONE with current month timestamp、DONE with last month timestamp 不匹配；old DONE 匹配；TODO 不匹配；REFILE DONE 不匹配。
- 运行 `ALLOW_UNPINNED_ORGMODE=1 bash tests/smoke/run.sh`。
- 运行 `git diff --check`。

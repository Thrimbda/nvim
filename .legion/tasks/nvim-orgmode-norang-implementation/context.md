# nvim-orgmode-norang-implementation - 上下文

## 会话进展 (2026-02-08)

### ✅ 已完成

- 实现阶段已启动：用户通过 /legion-impl 确认进入编码。
- 已创建任务产物目录：.legion/tasks/nvim-orgmode-norang-implementation/docs 与 reports。
- 完成 org_norang 五个模块实现（init/parser/rules/refresh/cleanup），含命令注册、刷新协议、冲突检测、cleanup dry-run/apply。
- 完成 orgmode 集成：接入 org_norang.setup，并扩展 b 视图新增 PROJECT+STUCK / PROJECT-STUCK / ARCHIVE_CANDIDATE。
- 完成 org_punch 轻量协同校验提示：TODO 语义不一致仅告警，不阻断主流程。
- 完成文档更新：补充 OrgNorang 命令、memory_only 语义、cleanup 回滚与排错说明。
- 执行最小校验：对 lua/org_norang/*.lua、lua/plugins/orgmode.lua、lua/org_punch.lua 逐个运行 nvim --headless -u NONE +"luafile ..."，7/7 成功加载。
- 输出测试报告：.legion/tasks/nvim-orgmode-norang-implementation/docs/test-report.md（结论 PASS，附 RFC T1-T16 手工验证步骤）。
- 已完成验证与审查产物生成：test-report/review-code/review-security。
- 已修复 agenda 边界：BufWritePost 与 refresh_file 仅处理 org_agenda_files 范围内文件。
- 已补全配置类型校验：非法类型稳定落入 E_CFG_INVALID/S5。
- 已为 cleanup apply 增加路径锁与 changedtick/mtime 冲突检测。
- 已完成修复后语法回归校验（headless luafile 通过）。
- 已修复安全复审 FAIL：setup 先校验后注册自动刷新，非法配置路径不再触发字段下钻崩溃。
- 已增强 notify 防御式访问，observability 类型异常不会导致错误分支再次崩溃。
- 已为 refresh/cleanup 锁加入异常安全释放（xpcall），避免 lock.busy 残留。
- 已完成修复后二次语法校验通过。
- 2026-02-12 重新执行最小校验：对 7 个改动 Lua 文件逐个运行 `nvim --headless -u NONE '+set rtp+=.' '+luafile <FILE>' '+qa'`，结果 7/7 PASS；已覆盖写回 docs/test-report.md。
- 已完成最终代码复审：docs/review-code.md 结论 PASS-WITH-CHANGES（无 blocking）。
- 已完成最终安全复审：docs/review-security.md 结论 PASS-WITH-CHANGES（无 blocking）。
- 已生成 walkthrough 报告：docs/report-walkthrough.md。
- 已实现 refresh_unloaded_files 开关并默认开启，OrgNorangRefresh 现在可处理未加载 agenda 文件。
- 已更新文档说明新语义与开关行为。
- 已完成语法回归校验（headless luafile 通过）。
- 已依据 norang 文档 Custom Agenda Setup 补齐 Standalone Tasks 区块，解决 TODO 叶子任务在 block agenda 不可见问题。
- 已更新工作流文档，新增 Standalone Tasks 的匹配表达式说明。
- 已完成 orgmode.lua 语法回归校验（headless luafile 通过）。
- 已新增 Stuck Projects 独立议程命令 `:Org agenda s` 与快捷键 `<Leader>oas`。
- 已同步更新工作流文档中 agenda 命令与快捷键说明。
- 已完成语法校验（luafile lua/plugins/orgmode.lua 通过）。
- 已修复 stuck projects 判定偏差：项目子任务现在按 Norang 口径使用“任意 TODO 关键词（含 done 状态）”识别项目。
- 已修复 NEXT 例外：带 WAITING 标签的 NEXT 不再解除 STUCK。
- 已完成针对用户样例文件 ~/OneDrive/cone/course.org 的验证，根节点判定结果为 PROJECT=1 STUCK=1。
- 定位根因：org_agenda_files 通配模式在 refresh 展开阶段被 vim.fn.expand 提前展开，导致后续 glob 输入异常，匹配集合可能为空。
- 已修复 refresh 展开逻辑：仅做 HOME 展开，不提前展开通配；并保留旧模式 `/**/*` 的回退匹配兼容。
- 已将默认 agenda 模式从 `~/OneDrive/cone/**/*` 调整为 `~/OneDrive/cone/**/*.org`（orgmode 与 org_norang 一致）。
- 已针对用户样例文件 `/Users/c1/OneDrive/cone/course.org` 执行刷新验证，结果 `ok=true changed=true`，并写入 `:PROJECT:STUCK:` 标签。
- 已完成全量语法回归校验（org_norang + orgmode 配置）。
- 已在 orgmode 配置启用并显式配置 agenda time grid（daily），使自定义日视图显示 Emacs 风格时间线。
- 已新增独立时间线命令 `:Org agenda t` 与快捷键 `<Leader>oat`。
- 已更新使用文档并补充“无具体时间戳不会占时间槽”的行为说明。
- 已完成语法校验（luafile lua/plugins/orgmode.lua 通过）。


### 🟡 进行中

(暂无)


### ⚠️ 阻塞/待定

(暂无)


---

## 关键文件

(暂无)

---

## 关键决策

| 决策 | 原因 | 替代方案 | 日期 |
|------|------|----------|------|
| 实现阶段严格以已通过复审的 RFC 为唯一设计真源，不在实现过程中扩展规范口径。 | 避免设计与实现漂移，确保 R1-R21/T1-T16 可追踪验收。 | 边实现边调整规范；但会造成验收口径不稳定和返工风险。 | 2026-02-08 |
| V1 refresh_all 严格遵守 memory_only：仅处理已加载 buffer，对未加载 agenda 文件统计为 skipped_unloaded | 与 RFC R12/R13/T16 一致，避免隐式加载带来的副作用与性能抖动 | 隐式 bufload 全量处理；已拒绝（违反 RFC 边界） | 2026-02-08 |
| 本轮验证采用“最小必选自动化 + RFC T1-T16 手工步骤清单”作为交付口径。 | 仓库缺少可直接执行的完整自动化测试入口，且用户明确要求最小校验至少包含 headless luafile。 | 等待新增完整测试框架后再做全自动回归；当前会阻塞交付。 | 2026-02-11 |
| 优先修复审查 blocking/high，再进行最终复审与报告。 | 保证实现阶段输出可进入交付，避免带已知高风险缺陷继续推进。 | 先生成 walkthrough 再补修；但会导致报告与代码状态不一致。 | 2026-02-08 |
| 在保持 RFC 口径不变前提下，优先关闭审查 blocking/high，再进行最终报告输出。 | 确保交付物满足正确性与安全门禁，避免带高风险缺陷进入报告阶段。 | 保留审查问题并仅记录风险；但不满足实现阶段闭环目标。 | 2026-02-08 |
| 根据用户新增需求调整刷新策略：支持全量识别并刷新 org_agenda_files 中未加载文件，并提供开关 refresh.refresh_unloaded_files（默认 true）。 | 用户明确要求“所有都能被识别并刷新”，且允许做开关但默认开启。 | 保持仅已加载 buffer 刷新（旧行为，默认 skipped_unloaded 增高）；不满足用户新需求。 | 2026-02-12 |
| 在 block agenda 中新增 Standalone Tasks 块，匹配 `+TODO="TODO"-PROJECT-REFILE`。 | norang 标准流程包含 Standalone Tasks 视图；当前用户 TODO 任务因缺少该块而不可见。 | 仅依赖 Next/Projects 视图；无法覆盖 TODO 叶子任务。 | 2026-02-12 |
| 在保留 block agenda 的前提下增加独立 Stuck Projects 入口。 | 符合 Norang 实际使用习惯，便于快速聚焦卡住项目而不必每次打开完整 block agenda。 | 仅保留 b 视图中的 Stuck Projects 区块；发现与操作效率较低。 | 2026-02-12 |
| 将项目判定从“有活动子任务”改为“有任意 TODO 关键字子任务”，并将 WAITING+NEXT 视为不可解除 stuck。 | 与 Norang 原始定义保持一致，修复用户样例 course.org 被漏判问题。 | 继续仅统计 active 子任务；会把仅含 DONE 子任务的项目误判为非项目。 | 2026-02-12 |
| 避免在 agenda 文件发现阶段对通配模式调用 `vim.fn.expand`，改为仅 `~` 展开后交由 `vim.fn.glob` 处理。 | `expand` 会提前展开通配，破坏 glob 输入语义，导致匹配集错误。 | 继续使用 `expand` 并尝试后处理字符串；复杂且不稳定。 | 2026-02-12 |
| 通过 `org_agenda_time_grid.type = {'daily'}` 去掉 `require-timed` 约束，确保日视图稳定显示时间线。 | 用户需要类似 Emacs 的固定时间线展示，不应依赖当天是否存在 timed 条目。 | 保留默认 `require-timed`；会在无 timed 条目时隐藏时间线，体验不符合需求。 | 2026-02-12 |

---

## 快速交接

**下次继续从这里开始：**

1. 如需继续优化，可按 review-code/review-security 的非阻塞建议进行性能与可观测性增强。
2. 如需提交代码，请执行 git add/commit，并可基于 report-walkthrough 组织提交说明。

**注意事项：**

- 当前实现与 RFC 关键条款已对齐，且无审查 blocking。
- 本轮未新增自动化单元测试框架，验证基线为最小自动化校验 + 手工步骤清单。

---

*最后更新: 2026-02-14 12:22 by Claude*

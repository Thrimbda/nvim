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
- 完成 org-mode 相关代码整体审查（orgmode 配置、org_punch、org_norang refresh/cleanup/rules、文档）。
- 已修复 org_punch agenda 文件发现：改为仅 HOME 展开 + 通配兼容，不再因 expand+glob 组合导致匹配为空。
- 已修复 org_norang cleanup agenda 文件发现：与 refresh 逻辑统一（HOME 展开 + `/**/*` 兼容 + 目录回退）。
- 已收敛 organization_task_id 为单一入口：仅通过 `vim.g.org_organization_task_id` 传入，避免空字符串覆盖模块默认。
- 已更新文档：agenda 命令列表与默认任务 ID 配置语义同步。
- 已完成回归验证：语法校验通过；org_punch 默认任务 ID 查找通过；cleanup 文件发现总数恢复。
- 已对照 Norang 文档补齐 clock-in 状态切换：TODO task -> NEXT，NEXT project -> TODO。
- 已修复 org_punch 调用 orgmode.action 未等待 Promise 的问题，避免 clock 动作与后续状态切换竞态。
- 已接管 org/agenda clock-in 映射（`<Leader>oxi` 与 agenda `I`）统一走 org_punch 包装逻辑。
- 已验证行为：headless 用例通过（`** TODO Task 1` clock in 后变 `** NEXT Task 1`；`* NEXT Project` clock in 后变 `* TODO Project`）。
- 已补充文档：time grid 的 time block 来源于时间戳，clock 数据通过 agenda `R` 查看 clock report。
- 已修复 punch_in 误报成功：当默认任务 clock-in 失败（缺 ID/找不到 ID）时，punch_in 返回 false 且 keep_clock_running 回退为 false。
- 已将 organization_task_id 单一入口写入 `lua/config/options.lua`，当前默认值与实际 org 文件 ID 对齐。
- 已完成回归验证：`vim.g.org_organization_task_id` 读取为配置值；无 ID 时 `punch_in` 输出明确错误并返回 false。
- 已修复 clock_out 零时长清理：clock_out 后若刚关闭的 CLOCK 为 `0:00`，自动删除该 CLOCK 行；若 LOGBOOK 变空则同步删除空 drawer。
- 已统一 clock-out 入口：禁用 orgmode 默认 org/agenda clock_out 映射，改由 org_punch 包装器处理（Org `<Leader>oxo` / Agenda `O`）。
- 已完成回归验证：即时 clock in + clock out 后，不再保留 `0:00` CLOCK 记录。
- 已新增冒烟测试文件 `lua/tests/smoke/orgmode_smoke.lua`，覆盖 7 个关键场景（punch in/out、TODO/NEXT 自动切换、0:00 CLOCK 清理、norang refresh/cleanup）。
- 已新增批量执行脚本 `tests/smoke/run.sh`，按 case 顺序逐个执行并在失败时立即退出。
- 已新增 CI 工作流 `.github/workflows/org-smoke.yml`：安装 Neovim、按 lazy-lock commit 拉取 orgmode、执行 smoke 脚本。
- 已本地逐个执行全部 smoke case，全部通过。
- 已模拟 GitHub Actions 环境（克隆固定 orgmode commit + 运行脚本）并验证全通过。
- 已修复 punch_in 触发 fold 全收起问题：`with_view_restored` 现在恢复窗口 fold 相关选项（foldlevel/foldenable/foldmethod/foldexpr/foldtext）。
- 已验证回归：构造跨文件 punch_in 场景，foldlevel 从 99 保持到 99，不再被 org ftplugin 的 startup folded 覆盖。
- 已执行 smoke 脚本回归（7 个 case）并全部通过。
- 已定位并修复 punch in/out 造成 fold/高亮副作用的根因：默认任务 clock-in 原实现通过当前窗口切换 buffer，会触发 ftplugin 与窗口状态污染。
- 默认任务 clock-in 现改为无切窗路径：直接通过 orgmode files/clock API 对目标 headline 操作，不再 `edit` 到默认任务文件。
- punch_out 去除了 `org_clock_goto` 跳转，直接对活动时钟执行 clock_out，避免窗口切换带来的语法/折叠异常。
- 补充回归用例：新增 `punch_in_preserves_current_buffer`、`punch_out_preserves_current_buffer` 两个 smoke case。
- 扩展后的 smoke 套件（9 个 case）已全部通过。


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
| 先输出审查结论与优化建议，再由用户决定是否进入补丁修复。 | 当前用户请求是“整体 review”，优先提供可执行问题清单与优先级。 | 直接落地修复；可能超出本次 review 请求边界。 | 2026-02-12 |
| organization_task_id 统一由 `vim.g.org_organization_task_id` 作为唯一指定入口，插件层只在非空时透传给 org_punch。 | 消除双来源覆盖冲突，避免未配置时空字符串覆盖导致 punch in 失败。 | 保留 org_punch 硬编码默认 ID；会造成环境耦合与多用户配置冲突。 | 2026-02-12 |
| 不将 CLOCK 记录直接渲染为时间线 time block，而是遵循 orgmode 语义：时间线展示时间戳，clock 通过 report 展示。 | 与 Norang/Org 行为一致，避免将日志数据误作计划数据，降低副作用。 | 将 clock-in 自动写入 SCHEDULED 时间戳以强制占位；会污染计划字段且偏离原流程。 | 2026-02-12 |
| 保留 organization_task_id 的单一配置入口为 `vim.g.org_organization_task_id`，并在仓库默认 options 中提供有效值。 | 既满足“单一入口”约束，又避免未配置导致 punch_in 静默失败。 | 恢复 org_punch 内置硬编码默认 ID；会与单一入口目标冲突。 | 2026-02-12 |
| 将 `0:00` 清理逻辑放在 org_punch 的 clock_out 包装层，而不是改动 orgmode.nvim 源码。 | 最小侵入且可控，能同时覆盖 punch/out 与手动 clock-out 映射路径。 | 直接改 orgmode.nvim 上游逻辑；会增加维护成本且升级风险更高。 | 2026-02-12 |
| CI 依赖不走完整 LazyVim 启动链，改为 headless + `-u NONE` + 显式 runtimepath 注入（repo + orgmode）。 | 显著降低依赖体积与不确定性，确保 smoke 测试稳定、快速、可复现。 | 在 CI 启动完整 nvim 配置并同步全部插件；更慢且外部依赖更多。 | 2026-02-12 |
| 保持“切到默认任务 clock-in 再切回”的流程不变，仅补充窗口选项恢复层，避免改动 orgmode 行为边界。 | 最小改动即可消除 fold 副作用，风险低且兼容现有 punch 逻辑。 | 改为不切窗直接操作底层文件对象；实现复杂且更容易引入新竞态。 | 2026-02-12 |
| 将 punch 默认任务路径从“切窗 + 光标定位 + clock_in”改为“数据层定位 + clock_in”，并保持用户当前窗口不变。 | 从源头消除窗口局部状态污染（fold/highlight/layout）风险。 | 继续使用切窗方案并修补更多窗口选项恢复；复杂且脆弱。 | 2026-02-12 |

---

## 快速交接

**下次继续从这里开始：**

1. 如需继续优化，可按 review-code/review-security 的非阻塞建议进行性能与可观测性增强。
2. 如需提交代码，请执行 git add/commit，并可基于 report-walkthrough 组织提交说明。

**注意事项：**

- 当前实现与 RFC 关键条款已对齐，且无审查 blocking。
- 本轮未新增自动化单元测试框架，验证基线为最小自动化校验 + 手工步骤清单。

---

*最后更新: 2026-02-27 13:04 by Claude*

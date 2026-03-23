# nvim-orgmode-legion-implementation - 任务清单

## 快速恢复

**当前阶段**: 阶段 3 - 阶段 3: 报告 ✅ COMPLETE
**当前任务**: (none)
**进度**: 10/10 任务完成

---

## 阶段 1: 阶段 1: 实现 ✅ COMPLETE

- [x] 新增 org_legion 模块（init/parser/rules/refresh/cleanup）并接入命令与自动刷新 | 验收: 模块可加载，命令可注册，核心路径无语法错误
- [x] 更新 orgmode 配置接入 org_legion 与扩展 agenda blocks | 验收: 保持 b/n/r 兼容并新增 PROJECT/STUCK/ARCHIVE_CANDIDATE 视图
- [x] 更新 org_punch 协同校验与文档说明 | 验收: punch 行为不回归，文档覆盖新命令与回滚路径

---

## 阶段 2: 阶段 2: 验证与审查 ✅ COMPLETE

- [x] 执行测试/校验并记录结果 | 验收: 生成 docs/test-report.md，覆盖关键手工断言
- [x] 执行代码审查与安全审查 | 验收: 生成 docs/review-code.md 与 docs/review-security.md

---

## 阶段 3: 阶段 3: 报告 ✅ COMPLETE

- [x] RFC 生成完成（对齐审计 RFC） | 验收: 生成 docs/rfc.md，包含 A/B/C 基线、差异矩阵、最小实现计划与 Design Gate Checklist
- [x] 生成 walkthrough 报告与变更说明 | 验收: 生成 docs/report-walkthrough.md，包含下一步与风险备注
- [x] RFC 二次审查完成（复核上轮 blocking 关闭状态） | 验收: 生成 docs/rfc-review.md，结论 PASS 且明确 `blocking=0`
- [x] 用户批准设计（Design Approved） | 验收: 用户明确确认 RFC 方案后，方可进入 /legion-impl

---

## 发现的新任务

(暂无)
- [x] 修复代码审查 blocking：限制 refresh 仅处理 agenda files，并补全配置类型校验保证 E_CFG_INVALID/S5 语义稳定 | 来源: docs/review-code.md
- [x] 修复安全评审 high：cleanup apply 增加锁与 changedtick/mtime 冲突检测，避免覆盖新改动 | 来源: docs/review-security.md
- [x] 修复安全复审 FAIL：调整 setup 执行顺序与错误分支防御，保证非法配置稳定进入 S5/E_CFG_INVALID | 来源: docs/review-security.md
- [x] 支持全量刷新未加载 agenda 文件，增加 refresh.refresh_unloaded_files 开关并默认开启 | 来源: 用户需求变更 2026-02-12
- [x] 按 legion 文档补齐 Standalone Tasks 议程块，确保 TODO 叶子任务在 block agenda 可见 | 来源: 用户反馈 + skills/legion-workflow/references/orgmode-legion-workflow.md#CustomAgendaViewSetup
- [x] 补齐 Stuck Projects 独立议程入口（agenda s）和快捷键，便于按 Legion 流程单独查看卡住项目 | 来源: 用户反馈 2026-02-12
- [x] 修复 stuck project 判定：项目子任务包含 DONE/CANCELLED 也应识别为项目，且 WAITING 标签的 NEXT 不解除 STUCK | 来源: 用户反馈 ~/OneDrive/cone/course.org 误判
- [x] 修复 org_agenda_files 通配展开缺陷：避免 vim.fn.expand 提前展开通配导致匹配集为空，确保 course.org 可被识别 | 来源: 用户反馈 stuck project 仍未识别
- [x] 补齐 Emacs 风格时间线：启用 agenda time grid，并新增 `:Org agenda t` 日视图时间线入口 | 来源: 用户需求 2026-02-12
- [x] 修复 org_punch 的 agenda 文件发现逻辑（expand+glob 组合导致匹配为空，默认任务 ID 查找失败） | 来源: review 2026-02-12
- [x] 统一 organization_task_id 来源，避免 orgmode.lua 传空字符串覆盖 org_punch 默认值 | 来源: review 2026-02-12
- [x] 修复 org_legion cleanup 的 agenda 文件发现逻辑，与 refresh 保持一致的 home 展开与通配兼容 | 来源: 用户请求 bugfix 2026-02-12
- [x] 实现 Legion clock-in 状态切换：TODO task -> NEXT，NEXT project -> TODO | 来源: 用户反馈 clock in 后未自动切换 NEXT
- [x] 接管 org/agenda clock-in 映射并统一走 org_punch 包装器，保证状态切换逻辑一致 | 来源: 用户反馈 clock in 行为不一致
- [x] 补充文档说明：时间线 time block 来源于时间戳，clock 记录通过 agenda 的 R 查看报告 | 来源: 用户反馈 clock in 后时间线无 time block
- [x] 修复 punch_in 误报成功：默认任务 clock-in 失败时返回 false 并回退 keep_clock_running=false | 来源: 用户反馈 punch in 无法 clock in
- [x] 在单一入口设置 organization_task_id：写入 lua/config/options.lua 并校正文档 | 来源: 用户反馈 punch in 无法 clock in
- [x] 修复 clock_out 未清理 0:00 记录：统一 org/agenda clock-out 入口到 org_punch，并在 clock_out 后自动删除零时长 CLOCK 行 | 来源: 用户反馈 2026-02-27
- [x] 新增 org-mode 冒烟测试集（7 个 case）与本地批量运行脚本 tests/smoke/run.sh | 来源: 用户请求：设计单测冒烟并逐个运行
- [x] 新增 GitHub Actions 工作流 .github/workflows/org-smoke.yml，在 CI 中按 lazy-lock 固定 commit 拉取 orgmode 并执行冒烟测试 | 来源: 用户请求：setup github action
- [x] 修复 punch_in 导致窗口 fold 状态丢失：with_view_restored 恢复 foldlevel/foldenable/foldmethod/foldexpr/foldtext | 来源: 用户反馈 punch in 后所有标题折叠
- [x] 修复 punch in/out 的窗口副作用：默认任务 clock-in 改为无切窗路径，punch_out 去除 org_clock_goto 跳转 | 来源: 用户反馈 punch 后 fold/高亮异常
- [x] 增强冒烟测试：新增 punch_in/punch_out 保持当前 buffer 的回归用例，防止再次引入窗口污染 | 来源: 回归防护 2026-02-27
- [x] 补齐 org_capture_templates 多类型模板（todo/respond/note/meeting/phone/journal），修复 capture 只显示 task 问题 | 来源: 用户反馈 capture 类型异常 2026-02-27
- [x] 修正 journal capture 目标路径到 diary.org datetree，并补齐 Legion capture clock handoff（开始 capture 暂停当前 clock，结束后恢复） | 来源: 用户反馈 journal 位置与 clock 行为不符原文
- [x] 将 journal 目标路径参数化：在 orgmode 配置顶端增加 org_diary_file 并支持 vim.g.org_diary_file 覆盖 | 来源: 用户反馈 diary path 应在顶端可配置
- [x] 修复 capture 条目未 clock-in：在 capture on_pre_refile 注入 LOGBOOK/CLOCK 记录，并保留 clock-resume 语义 | 来源: 用户反馈 journal/meeting/其他 capture 未 clock in
- [x] 增强冒烟测试覆盖 capture 语义：新增 handoff 恢复和 pre-refile CLOCK 注入用例 | 来源: 回归防护 2026-02-27
- [x] 修复 capture clock 时长与清理逻辑：分钟粒度计时（跨分钟记 1 分钟）且 0 分钟不写入 capture CLOCK | 来源: 用户反馈 diary 末尾 1 分钟被记为 0 + 0:00 条目残留
- [x] 修复 capture handoff 暂停时钟路径：改用 org_punch clock_out 包装，继承 0:00 清理语义 | 来源: 用户反馈 todo.org 残留 0:00 条目
- [x] 修复 punch 模式下普通 clock_out 不回默认任务：clock_out_current_task 在 keep_clock_running=true 时自动走 keep-running 分支 | 来源: 用户反馈 punch in 状态 clock out 未回 default task
- [x] 启用 refile 输入候选列表体验：orgmode 使用 vim.ui.input，snacks input 模块显式 enabled | 来源: 用户反馈 refile 无 fuzzy 候选列表
- [x] 修复 oxi 导致标题/折叠状态错乱：clock_in_current_task 增加视图恢复并避免同文件状态切换触发写盘 | 来源: 用户反馈 2026-03-01
- [x] 新增回归冒烟用例 clock_in_preserves_view_state，防止 oxi 再次污染 fold 展开状态 | 来源: 回归防护 2026-03-01
- [x] 落实无自动写盘约束：重构 org_punch clock 路径为内存缓冲区修改（移除 OrgFile:update 写盘链路） | 来源: 用户要求 clock 修改由手动保存
- [x] 调整 smoke 测试断言以匹配 memory-only 语义（优先读取已加载 buffer 而非磁盘文件） | 来源: 无自动写盘改造后的测试回归
- [x] 修复 capture resume 路径自动写盘：clock_in_snapshot 移除 OrgFile:update，改为隐藏 buffer 内存修改 | 来源: 用户强调所有 clock 修改需手动保存
- [x] 按 Legion 口径修复不一致项（TODO 状态触发、capture 模板覆盖、memory_only 语义收敛）并更新使用文档 | 来源: 用户新增实现指令 2026-03-01
- [x] 重新执行 review-code 与 review-security，若有 blocking 则先修复 | 来源: 用户新增实现指令 2026-03-01
- [x] 生成并更新 walkthrough 报告与 PR body 建议 | 来源: 用户新增实现指令 2026-03-01
- [x] 按 Legion 规则补齐 TODO 状态触发标签（WAITING/HOLD/CANCELLED）并接入 orgmode 配置 | 来源: 用户实现指令 2026-03-01
- [x] 补齐 capture 模板 w/h 并更新工作流文档模板清单 | 来源: 用户实现指令 2026-03-01
- [x] 新增 TODO 状态触发 smoke 用例并更新 tests/smoke/run.sh 执行列表 | 来源: 用户实现指令 2026-03-01


---

*最后更新: 2026-03-01 19:45*

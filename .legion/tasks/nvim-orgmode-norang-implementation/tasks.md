# nvim-orgmode-norang-implementation - 任务清单

## 快速恢复

**当前阶段**: (unknown)
**当前任务**: (none)
**进度**: 6/6 任务完成

---

## 阶段 1: 阶段 1: 实现 ✅ COMPLETE

- [x] 新增 org_norang 模块（init/parser/rules/refresh/cleanup）并接入命令与自动刷新 | 验收: 模块可加载，命令可注册，核心路径无语法错误
- [x] 更新 orgmode 配置接入 org_norang 与扩展 agenda blocks | 验收: 保持 b/n/r 兼容并新增 PROJECT/STUCK/ARCHIVE_CANDIDATE 视图
- [x] 更新 org_punch 协同校验与文档说明 | 验收: punch 行为不回归，文档覆盖新命令与回滚路径

---

## 阶段 2: 阶段 2: 验证与审查 ✅ COMPLETE

- [x] 执行测试/校验并记录结果 | 验收: 生成 docs/test-report.md，覆盖关键手工断言
- [x] 执行代码审查与安全审查 | 验收: 生成 docs/review-code.md 与 docs/review-security.md

---

## 阶段 3: 阶段 3: 报告 🟡 IN PROGRESS

- [x] 生成 walkthrough 报告与变更说明 | 验收: 生成 docs/report-walkthrough.md，包含下一步与风险备注

---

## 发现的新任务

(暂无)
- [x] 修复代码审查 blocking：限制 refresh 仅处理 agenda files，并补全配置类型校验保证 E_CFG_INVALID/S5 语义稳定 | 来源: docs/review-code.md
- [x] 修复安全评审 high：cleanup apply 增加锁与 changedtick/mtime 冲突检测，避免覆盖新改动 | 来源: docs/review-security.md
- [x] 修复安全复审 FAIL：调整 setup 执行顺序与错误分支防御，保证非法配置稳定进入 S5/E_CFG_INVALID | 来源: docs/review-security.md
- [x] 支持全量刷新未加载 agenda 文件，增加 refresh.refresh_unloaded_files 开关并默认开启 | 来源: 用户需求变更 2026-02-12
- [x] 按 norang 文档补齐 Standalone Tasks 议程块，确保 TODO 叶子任务在 block agenda 可见 | 来源: 用户反馈 + https://doc.norang.ca/org-mode.html#CustomAgendaViewSetup
- [x] 补齐 Stuck Projects 独立议程入口（agenda s）和快捷键，便于按 Norang 流程单独查看卡住项目 | 来源: 用户反馈 2026-02-12
- [x] 修复 stuck project 判定：项目子任务包含 DONE/CANCELLED 也应识别为项目，且 WAITING 标签的 NEXT 不解除 STUCK | 来源: 用户反馈 ~/OneDrive/cone/course.org 误判
- [x] 修复 org_agenda_files 通配展开缺陷：避免 vim.fn.expand 提前展开通配导致匹配集为空，确保 course.org 可被识别 | 来源: 用户反馈 stuck project 仍未识别
- [x] 补齐 Emacs 风格时间线：启用 agenda time grid，并新增 `:Org agenda t` 日视图时间线入口 | 来源: 用户需求 2026-02-12
- [x] 修复 org_punch 的 agenda 文件发现逻辑（expand+glob 组合导致匹配为空，默认任务 ID 查找失败） | 来源: review 2026-02-12
- [x] 统一 organization_task_id 来源，避免 orgmode.lua 传空字符串覆盖 org_punch 默认值 | 来源: review 2026-02-12
- [x] 修复 org_norang cleanup 的 agenda 文件发现逻辑，与 refresh 保持一致的 home 展开与通配兼容 | 来源: 用户请求 bugfix 2026-02-12
- [x] 实现 Norang clock-in 状态切换：TODO task -> NEXT，NEXT project -> TODO | 来源: 用户反馈 clock in 后未自动切换 NEXT
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


---

*最后更新: 2026-02-27 13:04*
6-02-26 23:09*

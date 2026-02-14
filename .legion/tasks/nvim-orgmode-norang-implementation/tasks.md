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


---

*最后更新: 2026-02-14 12:22*

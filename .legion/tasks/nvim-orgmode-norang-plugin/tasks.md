# nvim-orgmode-norang-plugin - 任务清单

## 快速恢复

**当前阶段**: 阶段 2 - 设计循环（RFC + 审查）
**当前任务**: RFC 最终复审完成（R-1 已关闭）
**进度**: 5/5 任务完成

---

## 阶段 1: 调查与范围确认 ✅ COMPLETE

- [x] 梳理当前 orgmode/punch 配置与 suggestion 差异，形成约束与风险清单 | 验收: context.md 记录差异、约束、风险与 Scope

---

## 阶段 2: 设计循环（RFC + 审查） ✅ COMPLETE

- [x] 产出 RFC 初稿（架构、规则、接口、迁移与验证） | 验收: docs/rfc.md 生成且覆盖核心设计维度
- [x] 执行 review-rfc 审查并输出问题清单 | 验收: docs/rfc-review.md 生成并给出 PASS/PASS-WITH-CHANGES/FAIL
- [x] 按复审意见完成最后收敛并获得 PASS | 验收: 复审残留 R-1 关闭，结论升级为 PASS

---

## 阶段 3: 设计门禁 ✅ COMPLETE

- [x] 将 RFC 路径写入 plan.md 并给出下一步与阻塞项 | 验收: plan/context/tasks 更新完成
- [x] 完成 RFC 最终复审并输出结论 | 验收: `docs/rfc-review.md` 结论为 PASS，context/tasks 已回写

---

## 发现的新任务

- [x] 收敛 `precise` 策略（降级为 MAY 或补全语法闭合） | 来源: rfc-review blocking-1
- [x] 统一 `ARCHIVE_CANDIDATE` 的条款/算法/配置口径 | 来源: rfc-review blocking-2
- [x] 增加刷新并发安全协议（锁、冲突检测、写回语义） | 来源: rfc-review blocking-3
- [x] 设计可回滚清理命令（仅派生标签，支持 dry-run） | 来源: rfc-review blocking-4
- [x] 增补 b/n/r 与 punch 不回归规范条款及验收映射 | 来源: rfc-review major-5
- [x] 明确 `memory_only` 下 `refresh_all` 对未加载文件的处理策略并补充测试映射 | 来源: rfc-review 复审残留 R-1

---

*最后更新: 2026-02-07 by OpenCode*

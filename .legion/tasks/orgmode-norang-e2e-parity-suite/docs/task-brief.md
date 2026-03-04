# 任务简报：Norang E2E 对齐套件

## 问题定义

当前仓库已有多组 org/norang smoke 用例，但尚缺一个“按 Norang 原文流程串联”的端到端校验入口。目标是在单个 E2E 场景中覆盖关键行为，并以可执行断言验证实现是否忠于：

1. Norang 工作流原文（https://doc.norang.ca/org-mode.html）
2. 上游 orgmode/org-mode.nvim 的能力边界
3. 本仓库当前实现（org_punch/org_capture_norang/org_norang + orgmode 配置）

## 验收标准

- 新增至少 1 个端到端 smoke case，串联验证以下关键行为：
  - Punch in 默认任务与 keep-running 语义
  - Clock in TODO task -> NEXT；Clock in NEXT project -> TODO
  - TODO state tag triggers（WAITING/HOLD/CANCELLED 清晰增删）
  - Capture handoff（暂停当前时钟、完成后恢复）
  - Capture 记录有效 CLOCK（非 0:00）
  - derived tags refresh/cleanup（PROJECT/STUCK/ARCHIVE_CANDIDATE）
- 用例通过 `tests/smoke/run.sh` 可执行并纳入默认 smoke 执行清单。
- 补充文档，明确该 E2E 用例覆盖的 Norang 关键行为与边界。

## 前提假设

- 不在本任务实现 UI 像素级断言（agenda buffer 视觉布局、窗口移动动画等）；仅校验可稳定自动化的行为语义。
- 以 headless Neovim 运行 smoke 作为标准验证入口。
- 以现有 TODO keywords 与 capture 模板口径为当前真源（TODO/NEXT/WAITING/HOLD | DONE/CANCELLED；t/r/n/m/p/w/h/j）。

## 风险 / 规模

- 风险：**Medium**
- 规模：**Epic**
- 标签：`epic`, `rfc:heavy`

### 原因

- 涉及多模块协同（orgmode 配置 + org_punch + org_capture_norang + org_norang + smoke harness）。
- 验收口径来自外部规范（Norang 原文）且需与上游 orgmode 语义兼容，设计错误会导致测试“错测”。
- 变更主要在测试与文档层，可回滚，但覆盖范围大，故判定 Medium + Epic。

## 验证计划

1. 新增端到端 smoke case 并接入 `tests/smoke/run.sh`。
2. 本地执行 `bash tests/smoke/run.sh`，要求全量 PASS。
3. 产出 `docs/test-report.md`，记录新增 case 与关键断言覆盖映射。
4. 通过 `review-code`（必需）与 `review-security`（按 Medium + 外部语义依赖执行）收敛风险。

## 已知风险

- Norang 原文与 orgmode.nvim 行为存在历史差异时，测试需优先断言“本仓库宣称支持的行为”，并在 RFC 中明确不覆盖项。
- capture/clock 用例存在时间粒度抖动风险（分钟边界），需使用稳定断言（例如避免依赖精确秒数）。

## 外部参考

- Norang 原文：https://doc.norang.ca/org-mode.html
- Org manual（capture templates）：https://orgmode.org/manual/Capture-templates.html
- Org manual（stuck projects）：https://orgmode.org/manual/Stuck-projects.html
- orgmode.nvim doc：`.tests/deps/orgmode/doc/orgmode.txt`

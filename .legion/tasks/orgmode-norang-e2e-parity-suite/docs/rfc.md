# RFC：端到端 Norang 对齐 Smoke 套件

> **配置档位**：RFC Heavy（Epic/高风险）  
> **状态**：草案  
> **负责人**：agent/user  
> **创建时间**：2026-03-04  
> **最后更新**：2026-03-04

---

## 执行摘要
- **问题**：当前 smoke 测试验证的是离散的 Norang 行为，但没有一个端到端、Norang 风格的工作流对齐门禁，无法在 CI 中快速失败。
- **决策**：新增一个集成的 headless Neovim 流程测试与辅助断言，并维护一个显式行为矩阵，绑定三个基线：仓库实现、orgmode.nvim 边界、Norang 参考工作流。
- **为何现在做**：该任务属于 Epic/Medium-risk，且依赖外部语义；没有成文证据模型就容易“测错对象”。
- **影响**：提升对 punch、clock、capture handoff、TODO tag trigger 与 derived-tag 生命周期与声明的 Norang 行为保持一致的信心。
- **风险**：时间边界抖动、过度断言 UI 行为、以及 Norang 文章与 orgmode.nvim 能力不一致。
- **发布方式**：在 smoke harness 中落地矩阵 + 集成 case；仅保留确定性断言；纳入默认 `tests/smoke/run.sh`。
- **回滚方式**：从 runner 移除集成 case，保留辅助 case；若出现 CI 噪音或误报则回退文档映射。

---

## 1. 背景 / 动机
- 仓库在 `lua/tests/smoke/orgmode_smoke.lua` 已有聚焦型 smoke case，但缺少一个从 punch-in 到 capture handoff 再返回、能镜像 Norang 日常流程的单场景测试。
- task brief 要求一个可执行的对齐门禁，并锚定在：
  1) Norang 原文（`https://doc.norang.ca/org-mode.html`），
  2) orgmode.nvim 行为边界（`.tests/deps/orgmode/doc/orgmode.txt`），
  3) 本仓库实际模块（`lua/org_punch.lua`、`lua/org_capture_norang.lua`、`lua/org_norang/init.lua`、`lua/org_norang/todo_triggers.lua`）。
- 缺少此门禁会导致语义回归仍可能通过离散测试。

## 2. 目标
- 新增一个集成 E2E smoke case，在 `nvim --headless` 下验证 Norang 关键序列。
- 保留并扩展辅助断言，使每个关键行为都有稳定、可自动化的证据。
- 显式编码 MUST 与 SHOULD 优先级，并将每条映射到证据与断言策略。
- 产出失败诊断信息，能定位断言 ID、行为类别与实际偏差。

## 3. 非目标
- 像素/UI 布局校验（agenda 窗口位置、视觉折叠动画、提示渲染细节）。
- 人工交互式验证步骤。
- 重写 orgmode.nvim 内部实现或追求 Emacs Org 全量对齐。
- 扩展到清单外文件。

## 4. 约束
- **执行**：必须在 headless Neovim 运行，并可通过 `tests/smoke/run.sh` 调用。
- **确定性**：断言必须在分钟边界附近稳定，避免秒级精度检查。
- **范围**：修改限制在 `lua/tests/smoke/orgmode_smoke.lua`、`tests/smoke/run.sh`、`docs/orgmode-norang-workflow.md` 与任务文档。
- **兼容性**：断言应遵循 orgmode.nvim 文档行为；仓库特有行为可扩展但不能与基线 B 冲突。
- **运维**：失败输出必须能在 CI 日志中被机器解析。

## 5. 定义 / 术语表
- **Baseline A**：当前仓库行为（实现 + 当前 smoke harness）。
- **Baseline B**：orgmode.nvim 文档定义的能力与边界。
- **Baseline C**：Norang 工作流意图（外部参考行为）。
- **Parity assertion**：在 A/B/C 约束下必须/应当同时成立的可测试陈述。
- **Integrated flow case**：在一个测试中串联 punch、clock 迁移、capture handoff 与 derived-tag refresh。

---

## 6. 源基线与证据模型

### 6.1 基线
- **A（Repo）**：`lua/org_punch.lua`、`lua/org_capture_norang.lua`、`lua/org_norang/init.lua`、`lua/org_norang/todo_triggers.lua`、`lua/tests/smoke/orgmode_smoke.lua`、`tests/smoke/run.sh`、`docs/orgmode-norang-workflow.md`。
- **B（orgmode.nvim）**：`.tests/deps/orgmode/doc/orgmode.txt` 中 TODO 状态、clocking、capture 与映射相关章节。
- **C（Norang）**：`https://doc.norang.ca/org-mode.html` 中工作流期望（持续 clocking、NEXT 语义、capture/punch 约定）。

### 6.2 证据层级
1. **可执行证据优先**：smoke case 中的 headless 断言。
2. **实现证据其次**：仓库模块内函数级行为。
3. **文档证据再次**：orgmode.nvim 文档与 Norang 文档用于意图/边界。

### 6.3 冲突处理规则
- 若 A 与 C 不一致，仅当 **A 与 B 一致且在仓库文档中有明确声明** 时，套件才断言 A。
- 若 C 建议的行为不被 B 支持，则标记为自动化对齐的 OUT-OF-SCOPE，并在 Open Questions 或文档边界说明中记录。
- 矩阵行必须声明 `BoundaryType`：
  - `B-public`：断言直接锚定 orgmode.nvim 文档公开行为。
  - `A-extension`：断言验证仓库在 orgmode.nvim 之上的封装/扩展行为。

---

## 7. 方案设计

### 7.1 高层架构
- 保持现有 smoke harness 形态（`run(case_name)` 分发），新增一个集成 case，例如 `norang_e2e_integrated_flow`。
- 保留辅助 case 作为原子化诊断（每个 case 只覆盖一个行为）。
- 在 runner（`tests/smoke/run.sh`）中把集成 case 放在 Norang 相关 case 附近，保持确定性顺序。

### 7.2 端到端流程（集成 Case）
1. 准备临时 org 文件，包含默认任务 ID、项目/任务树与 capture 目标。
2. `punch_in` -> 校验 `keep_clock_running=true` 且默认任务有活动时钟。
3. 在 TODO 任务上执行 `clock_in_current_task` -> 校验 TODO->NEXT。
4. 在 keep-running 模式执行 `clock_out_current_task` -> 同时校验两条分支：父任务回退（`NP-006A`）与默认任务回退（`NP-006B`）。
5. 开始 capture handoff -> 校验活动时钟被暂停。
6. 模拟 capture 经过 >=1 分钟并触发 pre-refile hook -> 校验注入 LOGBOOK + 非零 CLOCK 行。
7. 完成 handoff -> 校验之前的时钟恢复。
8. 应用 TODO trigger 序列 WAITING/HOLD/CANCELLED/TODO -> 校验 tag 增删语义。
9. 执行 derived-tag refresh/cleanup 断言 -> 校验 `PROJECT/STUCK/ARCHIVE_CANDIDATE` 生命周期。
10. Punch out -> 校验时钟停止且无 0 时长残留。

### 7.3 辅助断言
- 保留并复用聚焦 case，便于定位根因：
  - Punch 前置条件检查。
  - Clock in 时 TODO/NEXT 状态迁移。
  - Capture handoff + pre-refile clock 注入。
  - Derived tag refresh/cleanup 行为。
- 集成 case 应调用共享 helper 函数，避免重复行扫描逻辑。

### 7.4 确定性策略
- 仅使用临时文件和内存 buffer；不依赖用户 org 文件。
- 对 capture 时长设置 `capture_started_at = os.time() - 61`（或等效实现）强制分钟差 >= 1。
- 断言结构性结果（`non-zero CLOCK`、tag 存在/缺失），而非精确时间戳。
- 避免真实 sleep。

### 7.5 失败诊断格式
- 将断言失败统一为单行 JSON 载荷：
  - `PARITY_FAIL {"v":1,"id":"NP-006B","phase":"clock","case":"norang_e2e_integrated_flow","expected":"clock title=Organization","actual":"clock title=nil"}`
- 保留现有 `FAIL <case_name>: ...` 外层包装，但消息文本中只嵌入一个 `PARITY_FAIL {...}` 载荷。
- 解析器约定：
  - regex 预过滤：`^PARITY_FAIL\s+\{.*\}$`
  - 必须执行 JSON decode；decode 失败视为无效 parity 失败记录。
  - 必填键：`v:number`、`id:string`、`phase:string`、`case:string`、`expected:string`、`actual:string`。
- 推荐 phase 键：`setup`、`punch`、`clock`、`capture`、`tags`、`refresh`、`cleanup`、`teardown`。
- 兼容性规则：载荷值可包含 `|`、`:`、空格与转义换行；解析器必须仅依赖 JSON decode。

---

## 8. 行为矩阵（Parity Assertions）

| ID | 行为陈述 | 优先级 | BoundaryType | CaseName | 证据指针 | 计划自动化断言策略 |
|---|---|---|---|---|---|---|
| NP-001 | 未配置 `organization_task_id` 时 `punch_in` 失败，并回滚 keep-running 状态。 | MUST | A-extension | `punch_in_requires_id` | `lua/org_punch.lua`, `lua/tests/smoke/orgmode_smoke.lua` | 设置空 ID，调用 `punch_in`，断言 return=false 且 `keep_clock_running=false`。 |
| NP-002 | 使用有效默认 ID 执行 punch in，会在默认任务启动活动时钟并开启 keep-running。 | MUST | A-extension | `punch_in_clocks_default_task` | `lua/org_punch.lua`, `docs/orgmode-norang-workflow.md` | 用含 `:ID:` 的临时 org，调用 `punch_in`，断言存在活动 CLOCK 行且 flag=true。 |
| NP-003 | 对 TODO 叶子任务执行 clock in，状态从 TODO -> NEXT。 | MUST | A-extension | `clock_in_todo_task_switches_to_next` | `lua/org_punch.lua`, `docs/orgmode-norang-workflow.md` | 光标放在 TODO 叶子任务，调用 `clock_in_current_task`，断言标题前缀为 `NEXT`。 |
| NP-004 | 对 NEXT 项目执行 clock in，状态从 NEXT -> TODO。 | MUST | A-extension | `clock_in_next_project_switches_to_todo` | `lua/org_punch.lua`, `docs/orgmode-norang-workflow.md` | 光标放在含 TODO 子任务的 NEXT 节点，clock in 后断言项目标题为 `TODO`。 |
| NP-005 | Clock out 会移除 `0:00` CLOCK 记录。 | MUST | A-extension | `clock_out_removes_zero_duration_clock` | `lua/org_punch.lua`, `docs/orgmode-norang-workflow.md` | 立即 clock in/out，扫描文件或 buffer，断言不存在 `=> 0:00`。 |
| NP-006A | 在 punch 模式且存在 TODO 父任务时，从当前任务 clock out 应恢复到父任务。 | MUST | A-extension | `clock_out_in_punch_mode_returns_to_parent` (new) | `lua/org_punch.lua` (`find_parent_project_line_in_current_buffer`) | 构造父子 fixture，`punch_in` -> 子任务 `clock_in` -> `clock_out`，断言活动时钟标题 == 父任务标题。 |
| NP-006B | 在 punch 模式且不存在 TODO 父任务时，从当前任务 clock out 应恢复到默认任务。 | MUST | A-extension | `clock_out_in_punch_mode_returns_to_default` | `lua/org_punch.lua`, Norang workflow intent URL | 构造无 TODO 父任务的叶子 fixture，`punch_in` -> `clock_in` -> `clock_out`，断言活动时钟标题 == 默认任务。 |
| NP-007 | Capture handoff 在 capture 期间暂停活动时钟，并在结束后恢复之前时钟。 | MUST | A-extension | `capture_clock_handoff_resumes_previous` | `lua/org_capture_norang.lua`, `docs/orgmode-norang-workflow.md` | 启动活动时钟，调用 `begin_capture_clock_handoff` 后再 `finish_capture_clock_handoff`，断言先为 nil 后恢复原标题。 |
| NP-008 | 当耗时 >=1 分钟时，capture pre-refile 会注入 LOGBOOK + 非零 CLOCK 行。 | MUST | A-extension | `capture_pre_refile_injects_clock_line` | `lua/org_capture_norang.lua`, `.tests/deps/orgmode/doc/orgmode.txt` (capture hooks) | 强制 started_at 早于当前 60s，调用 `on_pre_refile`，断言存在 LOGBOOK 且 `CLOCK ... => x:yy` 非 `0:00`。 |
| NP-009 | TODO trigger：WAITING 添加 WAITING；HOLD 添加 WAITING+HOLD；CANCELLED 添加 CANCELLED 并清除 WAITING/HOLD。 | MUST | A-extension | `todo_state_tag_triggers_norang` | `lua/org_norang/todo_triggers.lua`, `docs/orgmode-norang-workflow.md` | 驱动 todo 状态迁移并逐状态校验 tag 集合增删。 |
| NP-010 | 迁移到 TODO/NEXT/DONE 时清除 WAITING/HOLD/CANCELLED 标签。 | MUST | A-extension | `todo_state_tag_triggers_norang` | `lua/org_norang/todo_triggers.lua`, `docs/orgmode-norang-workflow.md` | 应用状态迁移，断言需移除标签不在本节点 tag 列表中。 |
| NP-011 | Derived tag refresh 会把无 next action 的项目标记为 `PROJECT:STUCK`（仓库 approx-mode 约定）。 | SHOULD | A-extension | `norang_refresh_marks_stuck_project` | `lua/org_norang/init.lua`, `lua/org_norang/refresh.lua`, `docs/orgmode-norang-workflow.md` | 对构造项目运行 `refresh_file`，断言该行包含派生标签。 |
| NP-012 | Derived tag cleanup apply 仅移除派生标签（`PROJECT/STUCK/ARCHIVE_CANDIDATE`）。 | MUST | A-extension | `norang_cleanup_apply_removes_derived_tags` | `lua/org_norang/init.lua`, `docs/orgmode-norang-workflow.md` | 执行 cleanup apply，断言派生标签被移除，用户自定义标签若存在则保留。 |
| NP-013 | Punch 与 clock 操作在 headless 执行中保持当前 buffer/view 状态。 | SHOULD | A-extension | `clock_in_preserves_view_state` + `punch_in_preserves_current_buffer` + `punch_out_preserves_current_buffer` | `lua/org_punch.lua` (`with_view_restored`) | 操作前记录 buffer 路径/折叠状态，操作后断言不变。 |
| NP-014 | Smoke runner 以非交互方式执行 parity suite，并纳入默认清单。 | MUST | B-public | `tests/smoke/run.sh` case list | `tests/smoke/run.sh`, `.tests/deps/orgmode/doc/orgmode.txt` | 确保 case 名出现在 `CASES`；`bash tests/smoke/run.sh` 运行无提示交互。 |
| NP-015 | 包装层使用的 orgmode.nvim clock 接口遵循文档映射/语义（`I/O`、`<Leader>oxi/oxo`、clock report）。 | SHOULD | B-public | `norang_e2e_integrated_flow` (new) | `.tests/deps/orgmode/doc/orgmode.txt` (Clocking sections), `lua/org_punch.lua` | 集成流程中校验活动时钟生命周期符合 orgmode clock API 结果（活动标题出现/消失迁移）。 |

优先级策略：
- **MUST**：失败即阻塞合并。
- **SHOULD**：可临时隔离，但必须显式绑定 issue 与 owner。

---

## 9. 数据模型 / 接口
- **断言 ID 规范**：`NP-###`（跨重构保持稳定）。
- **Case 接口**：`lua/tests/smoke/orgmode_smoke.lua` 中 `M.run(case_name)`；未知 case 必须硬失败。
- **失败载荷契约**：
  - 载荷格式：`PARITY_FAIL {json}`，其中 `{json}` 遵循 v1 schema。
  - 必填 JSON 字段：`v`、`id`、`phase`、`case`、`expected`、`actual`。
  - 可选 JSON 字段：`context`（object）、`hint`（string）。
  - 兼容当前输出行：`FAIL <case>: <message>`；解析器提取其中的 `PARITY_FAIL {json}` 子串。
- **兼容策略**：
  - 既有 case 名持续有效。
  - 集成 case 为增量添加。
  - 后续行为新增采用追加新 ID；已废弃 ID 永不复用。

## 10. 错误语义
- **可恢复失败**：单条断言不匹配；该 case 进程以非零退出，其他运行不受影响。
- **不可恢复配置错误**：缺失 orgmode runtime path 或 case 未知；runner 立即退出。
- **重试语义**：
  - CI 可对失败 case 重跑一次以识别 flakes。
  - 仅当失败与时间相邻且输入不变重跑通过时，才判定可疑 flake。
- **幂等性**：每个 case 必须创建隔离临时文件，且不留下持久副作用。

---

## 11. 备选方案

### 方案 A：仅保留原子辅助 smoke cases（不做集成流）
- 优点：调试更简单，flake 风险低。
- 缺点：无法发现跨模块 handoff 回归。
- 未采纳原因：task acceptance 明确要求至少一个端到端 Norang 流程。

### 方案 B：构建 UI 驱动 agenda/capture E2E（交互按键回放）
- 优点：更贴近用户体验。
- 缺点：flake 风险高，违反非交互约束，CI 可移植性差。
- 未采纳原因：超出范围，且在 headless 运行下不具确定性。

### 方案 C：基于快照的完整 org buffer golden-file 对比
- 优点：回归检测面更广。
- 缺点：对无害格式/顺序变更过于脆弱，维护成本高。
- 未采纳原因：语义对齐场景信噪比低。

### 最终决策
- 选择**混合方案**：一个集成语义流 + 若干聚焦辅助 case。
- 原因：
  - 覆盖跨模块工作流正确性。
  - 保持可调试性与 headless 执行确定性。
  - 与验收标准和任务范围直接对齐。
- 明确放弃：
  - 完整 UI 对齐断言。
  - 整个 buffer 的 golden 快照。

---

## 12. 迁移 / 发布 / 回滚

### 12.1 迁移计划
- 数据迁移：**无**（仅测试/文档）。
- 步骤：
  1. 在 `lua/tests/smoke/orgmode_smoke.lua` 增加由矩阵驱动的集成 case。
  2. 在 `tests/smoke/run.sh` 增加 case 入口。
  3. 更新 `docs/orgmode-norang-workflow.md` 的对齐边界与测试映射。

### 12.2 发布计划
- 无需 feature flag。
- 发布阶段：
  1. 本地执行 `bash tests/smoke/run.sh`。
  2. 在默认 smoke CI job 启用。
  3. 按断言 ID 监控 1 周失败情况（owner：org smoke maintainer）。
- 验收指标：
  - MUST 断言 100% 通过。
  - 无交互提示依赖。
  - 连续两次 CI 运行不出现重复时间边界 flake。

### 12.3 回滚计划
- 回滚触发：
  - 在稳定提交上可复现误报。
  - CI 时长显著回归或 flake 激增。
- 可执行回滚步骤：
  1. 编辑 `tests/smoke/run.sh`，从 `CASES` 中移除 `norang_e2e_integrated_flow`（或等效集成 case）。
  2. 回退 `lua/tests/smoke/orgmode_smoke.lua` 中的集成 case 函数（保留辅助 cases）。
  3. 更新 `docs/orgmode-norang-workflow.md`，说明当前临时回滚状态。
  4. 执行 `bash tests/smoke/run.sh`，确认辅助 cases 仍通过。
  5. 确认日志不再包含集成 case 启动行（`==> smoke: norang_e2e_integrated_flow`）。
- 回滚后一致性：
  - 原子对齐检查仍保留；仅关闭跨模块集成门禁。
  - CI 运行时长回到集成前基线（+/- 10%）。

---

## 13. 可观测性
- **日志**：
  - Case 启动：`==> smoke: <case>`（现有 runner）。
  - Pass：`PASS <case>`。
  - Fail：在既有 `FAIL <case>` 行中包含 `PARITY_FAIL {json}`。
- **指标（由 CI 推导）**：
  - 每个 case 的通过率。
  - 按断言 ID 统计失败次数。
  - 每个 case 运行时长（可选 shell timing wrapper）。
- **告警**：
  - 同一 MUST ID 在主分支连续 2 次运行失败时告警。
- **排障入口**：
  - `lua/tests/smoke/orgmode_smoke.lua` case 函数。
  - 矩阵证据中引用的模块函数。
  - `tests/smoke/run.sh` 的 runner 调用入口。

---

## 14. 安全考量
- **滥用/输入校验**：临时文件输入是受控测试夹具；无不可信网络输入。
- **权限**：测试仅操作本地临时文件与仓库内 runtime path。
- **资源耗尽**：避免无限等待；限制异步等待上限（已使用 `:wait(2000)`）。
- **命令安全**：Lua smoke cases 不额外执行 shell（除测试 runner 调用外）。
- **数据敏感性**：不需要 secrets；确保失败日志不额外泄露用户 home 路径（超出现有 runtimepath 诊断范围）。

---

## 15. 向后兼容
- 现有 smoke 入口与 case 名保持不变。
- 新增集成 case 为增量能力；辅助 cases 继续提供细粒度失败定位。
- 文档改动仅澄清边界；RFC 范围内不要求生产模块行为变更。

---

## 16. 验证计划
- 映射规则：每条 MUST/SHOULD 矩阵行至少映射到 smoke case 中一个自动化断言。
- 必跑命令：
  - `bash tests/smoke/run.sh`
- 本地调试可选命令：
  - `nvim --headless -u NONE "+set rtp+=$ORGMODE_RTP" "+set rtp+=$PWD" "+lua require('tests.smoke.orgmode_smoke').run('norang_e2e_integrated_flow')" +"qa!"`
- 通过标准：
  - 所有 MUST ID 通过。
  - SHOULD ID 通过，或已显式关联 issue 跟踪。
  - 至少一个故意触发失败可被 JSON parity-failure parser 正确解析。

---

## 17. 里程碑
- **里程碑 1：矩阵 + 诊断契约**
  - 范围：在 smoke 代码/文档中加入行为矩阵注释/ID 映射与 `PARITY_FAIL` 格式方案。
  - 验收：
    - 每个 MUST ID 至少映射到一个具体 `CaseName`；
    - 失败载荷符合 JSON v1 协议（`PARITY_FAIL {json}`）且 parser 可解析。
  - 回滚影响：无，需要时仅文档回退。
- **里程碑 2：集成流程 Case**
  - 范围：在 `lua/tests/smoke/orgmode_smoke.lua` 实现 `norang_e2e_integrated_flow` 并注册到 `CASES`。
  - 验收：case 在 headless 下通过；覆盖 punch->clock->capture->tags->refresh 序列。
  - 回滚影响：移除单个 case 条目与函数。
- **里程碑 3：Runner + 文档集成**
  - 范围：在 `tests/smoke/run.sh` 添加 case；更新 `docs/orgmode-norang-workflow.md` 的对齐边界与矩阵引用。
  - 验收：全量 smoke 通过；文档解释 MUST/SHOULD/OUT-OF-SCOPE。
  - 回滚影响：从 runner 移除 case 并回退文档新增内容。

---

## 18. 明确的范围外项
- Agenda/capture 窗口布局、分屏方向、光标动画一致性。
- Keymap 可视化提示/帮助 buffer 内容顺序。
- 具体时间戳文本到 locale/秒级的格式一致性。
- 超出临时 fixture 文件的真实用户文件系统集成。

---

## 19. 待决问题
- [ ] 在 CI 环境稳定性数据确认后，是否将 NP-011（`PROJECT/STUCK` refresh）从 SHOULD 升级为 MUST？
- [ ] 是否需要一个仅重跑 parity-integrated case 的专用 CI job，以便更快定位回归？

---

## 20. 计划（文件改动点 + 验证步骤）
- `lua/tests/smoke/orgmode_smoke.lua`
  - 新增集成 case 函数并复用 helper。
  - 确保失败信息包含断言 ID。
- `tests/smoke/run.sh`
  - 将集成 case 加入 `CASES` 默认序列。
- `docs/orgmode-norang-workflow.md`
  - 增加 parity-suite 覆盖与显式边界章节。
- `.legion/tasks/orgmode-norang-e2e-parity-suite/docs/rfc.md`
  - 作为矩阵与发布策略的单一事实源。

验证步骤：
1. 运行 `bash tests/smoke/run.sh`。
2. 确认集成 case 输出 PASS，且无交互提示。
3. 本地临时故意破坏一条断言，验证 `PARITY_FAIL {json}` 格式可解析后再恢复。

---

## 21. 参考资料
- Task brief：`.legion/tasks/orgmode-norang-e2e-parity-suite/docs/task-brief.md`
- 仓库工作流文档：`docs/orgmode-norang-workflow.md`
- Smoke harness：`lua/tests/smoke/orgmode_smoke.lua`、`tests/smoke/run.sh`
- 仓库模块：`lua/org_punch.lua`、`lua/org_capture_norang.lua`、`lua/org_norang/init.lua`、`lua/org_norang/todo_triggers.lua`
- Orgmode 文档：`.tests/deps/orgmode/doc/orgmode.txt`
- Norang 参考：`https://doc.norang.ca/org-mode.html`
- Org manual 参考：
  - `https://orgmode.org/manual/Capture-templates.html`
  - `https://orgmode.org/manual/Stuck-projects.html`

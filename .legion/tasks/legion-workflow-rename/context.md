# legion-workflow-rename - 上下文

## 会话进展 (2026-03-13)

### ✅ 已完成

- 将旧 Skill、Lua 模块与相关 `.legion` 任务目录统一重命名为 `legion` 方案。
- 把原工作流说明移动到 `skills/legion-workflow/references/orgmode-legion-workflow.md`，并让 Skill 改为引用内部 reference。
- 全仓库替换剩余旧工作流命名字样，更新 README、代码、测试与 `.legion` 历史记录。
- 执行 `bash tests/smoke/run.sh`，全部 smoke case 通过。
- 按用户反馈复查 `skills/legion-workflow/**`，确认当前 Skill 包内已无 `norang` / `Norang` 残留。
- 按用户要求重新执行 `bash tests/smoke/run.sh` 复检，全部 smoke case 通过。
- 复现了用户反馈：默认任务 `:ID:` 在 `todo.org` 与 `todo-charles.org` 重复，且由于 OneDrive 符号链接路径不一致，`punch_in` 未优先命中当前 buffer。
- 修复 `lua/org_punch.lua`：路径标准化改为 realpath，对重复 `organization_task_id` 优先选择当前 buffer，并在重复场景给出提示。
- 新增 smoke 用例 `punch_in_prefers_current_buffer_when_id_is_duplicated`，覆盖重复 ID 回归。
- 清理 `skills/legion-workflow/SKILL.md` 与 `skills/legion-workflow/references/orgmode-legion-workflow.md` 的说明与示例缩进，并补充重复 ID 说明。
- 重新执行 `bash tests/smoke/run.sh`，全部 smoke case 通过。


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
| 用户若仍在 diff 中看到 `norang`，优先区分当前 `skills/legion-workflow/**` 内容与已删除旧路径 `skills/norang-workflow/**` 的历史差异。 | 本轮复查显示现行 Skill 文件已清理完成，残留感知更可能来自未暂存的重命名 diff。 | 继续盲目替换当前 Skill 内容；但会增加噪音且无法解释用户看到的旧内容来源。 | 2026-03-13 |
| 当多个 agenda 文件复用同一个 `organization_task_id` 时，`org_punch` 应优先选择当前 buffer 的匹配 headline。 | 用户实际仓库存在重复 ID；若仍按 glob 首个匹配选择，会把 CLOCK 打到错误文件，表现为当前 Organization 没有开始计时。 | 直接报错要求用户先清理重复 ID；更严格但会打断现有工作流，因此先采用“当前 buffer 优先 + warning”的兼容策略。 | 2026-03-17 |

---

## 快速交接

**下次继续从这里开始：**

1. (待填写)

**注意事项：**

- (待填写)

---

*最后更新: 2026-03-17 14:51 by Claude*

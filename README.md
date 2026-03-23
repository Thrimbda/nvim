# 💤 LazyVim for 0xc1

我的 LazyVim 配置，基于 [LazyVim](https://www.lazyvim.org/)。

## External Binaries

Required by installed plugins/features:

- `git` (gitsigns.nvim, diffview.nvim, snacks.nvim git features)
- `gh` (snacks.nvim GitHub/PR pickers)
- `node` (github/copilot.vim)
- `deno` (toppair/peek.nvim build/runtime)

## 安装 Legion Workflow Skill（给人类和 AI）

本仓库内置了一个可复用 Skill：`skills/legion-workflow/SKILL.md`。

### 人类安装（推荐：skills.sh CLI）

参考 `skills.sh` CLI 文档：<https://skills.sh/docs/cli>

在仓库根目录执行：

```bash
npx skills add https://github.com/Thrimbda/nvim --skill legion-workflow -a opencode -a claude-code
```

可选（全局安装到用户目录）：

```bash
npx skills add -g https://github.com/Thrimbda/nvim --skill legion-workflow -a opencode -a claude-code
```

安装后可检查：

```bash
npx skills list
```

### AI 侧使用方式

安装完成后，在会话中直接加载并使用：

- OpenCode：`skill({ name: "legion-workflow" })`
- 通用提示词：`请加载 legion-workflow skill，并按其中流程执行。`

### 手动安装（不使用 skills.sh）

将 `skills/legion-workflow/` 复制到任一 agent 的技能目录：

- OpenCode（项目级）：`.opencode/skills/legion-workflow/`
- OpenCode（全局）：`~/.config/opencode/skills/legion-workflow/`
- Claude Code（项目级）：`.claude/skills/legion-workflow/`
- Claude Code（全局）：`~/.claude/skills/legion-workflow/`

确保目标目录内存在 `SKILL.md`。

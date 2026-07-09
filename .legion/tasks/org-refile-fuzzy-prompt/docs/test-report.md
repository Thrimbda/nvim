# Test Report: org-refile-fuzzy-prompt

## 结论

PASS。变更已验证为：worktree 的 orgmode spec 不再设置 `ui.input.use_vim_ui = true`，本地 orgmode 默认输入路径仍为 `use_vim_ui = false`，并且 orgmode refile 的 `autocomplete_refile()` 可通过 fuzzy 输入返回候选目标。完整 smoke suite 通过，未发现 capture/punch/agenda 相关回归。

## 命令与结果

### 1. 配置覆盖消失断言

```sh
rg -n "use_vim_ui\\s*=\\s*true" lua/plugins/orgmode.lua skills/legion-workflow/references/orgmode-legion-workflow.md
```

- Result: exit 1，无匹配。
- 证明力：目标配置文件和更新后的说明文档里不再存在 `use_vim_ui = true` 覆盖。

### 2. orgmode 默认值断言

```sh
nvim --headless -u NONE '+set rtp+=/Users/c1/.local/share/nvim/lazy/orgmode' '+lua local d=require("orgmode.config.defaults"); assert(d.ui.input.use_vim_ui == false, "orgmode default use_vim_ui changed"); print("orgmode_default_use_vim_ui", tostring(d.ui.input.use_vim_ui))' '+qa!'
```

- Result: exit 0，输出 `orgmode_default_use_vim_ui false`。
- 证明力：移除本仓库覆盖后会回落到 orgmode.nvim 当前本地版本的原生 input completion 路径。

### 3. worktree spec-level 断言

```sh
nvim --headless -u NONE '+set rtp^=/Users/c1/.config/nvim/.worktrees/org-refile-fuzzy-prompt' '+lua local cfg; package.loaded["orgmode"] = { setup = function(opts) cfg = opts end, action = function() return { wait = function() end } end }; package.loaded["org_legion.todo_triggers"] = { setup = function() return true end }; package.loaded["org_legion"] = { setup = function() return true end }; package.loaded["org_punch"] = { setup = function() end, punch_in = function() end, punch_out = function() end, clock_out_keep_running = function() end, clock_in_current_task = function() end, clock_out_current_task = function() end }; package.loaded["org_capture_legion"] = { setup = function() end, capture_prompt = function() end }; local spec = dofile("lua/plugins/orgmode.lua")[1]; spec.config(); assert(cfg and cfg.ui == nil, "orgmode spec should not set ui.input"); print("worktree_spec_ui", tostring(cfg.ui))' '+qa!'
```

- Result: exit 0，输出 `worktree_spec_ui nil`。
- 证明力：直接加载本分支的 `lua/plugins/orgmode.lua`，确认传给 `orgmode.setup()` 的配置不再包含 `ui.input` 覆盖。

### 4. orgmode refile fuzzy 候选函数断言

```sh
nvim --headless -u NONE '+set rtp+=/Users/c1/.local/share/nvim/lazy/orgmode' '+lua local Capture = require("orgmode.capture"); local files = { ["/org/ntnl.org/"] = true, ["/org/tasks.org/"] = true, ["/org/someday.org/"] = true }; local result = Capture.autocomplete_refile(Capture, "ntl", files); assert(vim.tbl_contains(result, "/org/ntnl.org/"), vim.inspect(result)); print("autocomplete_refile", table.concat(result, ","))' '+qa!'
```

- Result: exit 0，输出 `autocomplete_refile /org/ntnl.org/`。
- 证明力：orgmode refile 的候选函数对非连续输入 `ntl` 返回 `ntnl.org/`，验证 fuzzy 匹配能力存在。

### 5. smoke suite

```sh
ALLOW_UNPINNED_ORGMODE=1 bash tests/smoke/run.sh
```

- Result: exit 0，全部 20 个 smoke case 通过，最终输出 `All smoke cases passed.`。
- 备注：`.tests/deps/orgmode` 不存在，因此按 runner 提示显式设置 `ALLOW_UNPINNED_ORGMODE=1`，使用 `/Users/c1/.local/share/nvim/lazy/orgmode`。
- 证明力：覆盖 punch、clock、capture handoff、capture pre-refile hook、todo tag trigger、Legion integrated flow 等既有 orgmode 行为，降低局部配置调整带来的回归风险。

## 无效验证尝试

- `tests/smoke/run.sh` 直接执行返回 exit 126，因为脚本没有 executable bit；改用 `bash tests/smoke/run.sh` 后通过。
- `nvim --headless -u init.lua` 的运行时配置断言曾读取主工作区 `/Users/c1/.config/nvim`，不是 worktree 配置，因此不作为本任务证据。
- `nvim --headless -u NONE +source init.lua` 命中 Lazy headless 内部状态错误，不作为本任务证据。

## Skips / Limitations

- 未做像素级 UI 截图验证。refile 候选弹窗属于交互式命令行/input completion 行为，当前 headless 验证用配置路径、上游 fuzzy function 和完整 smoke suite 证明核心语义。

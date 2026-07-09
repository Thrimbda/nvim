# Test Report: org-refile-fuzzy-prompt follow-up

## 结论

PASS。本次 follow-up 已验证为：refile destination 选择会通过 patched `orgmode.capture.get_destination()` 调用 `vim.ui.select`，候选包含文件 root 与 unfinished headline，选择 headline 会返回 orgmode 期望的 `{ file, headline }` destination，取消会返回 `false`。完整 smoke suite 通过，包含新增的 refile picker 用例。

## 命令与结果

### 1. 新增 picker targeted smoke

```sh
ORGMODE_RTP=/Users/c1/.local/share/nvim/lazy/orgmode \
SMOKE_ROOT_DIR=/Users/c1/.config/nvim/.worktrees/org-refile-fuzzy-prompt \
nvim --headless -u NONE \
  '+lua ... vim.opt.rtp:prepend(SMOKE_ROOT_DIR); vim.opt.rtp:append(ORGMODE_RTP)' \
  '+lua require("tests.smoke.orgmode_smoke").run("refile_picker_builds_file_and_headline_candidates")' \
  '+lua require("tests.smoke.orgmode_smoke").run("refile_picker_selects_and_cancels_destination")' \
  '+qa!'
```

- Result: exit 0。
- Output:
  - `PASS refile_picker_builds_file_and_headline_candidates`
  - `PASS refile_picker_selects_and_cancels_destination`
- 证明力：直接验证候选构建包含文件和 headline；验证 picker 选择 headline 返回 destination，取消返回 `false`。

### 2. worktree spec-level patch 断言

```sh
ORGMODE_RTP=/Users/c1/.local/share/nvim/lazy/orgmode \
nvim --headless -u NONE \
  '+lua vim.opt.rtp:prepend("/Users/c1/.config/nvim/.worktrees/org-refile-fuzzy-prompt"); vim.opt.rtp:append(vim.env.ORGMODE_RTP); local orgmode = require("orgmode"); orgmode.setup({ org_agenda_files = {}, org_default_notes_file = "/tmp/refile.org", mappings = { disable_all = true }, notifications = { enabled = false } }); require("org_refile_picker").setup(orgmode.capture); assert(orgmode.capture._org_refile_picker_original_get_destination ~= nil, "picker patch missing"); print("picker_patched", tostring(orgmode.capture._org_refile_picker_original_get_destination ~= nil))' \
  '+qa!'
```

- Result: exit 0，输出 `picker_patched true`。
- 证明力：确认模块能 patch orgmode capture 对象，而不是只存在于静态代码里。

### 3. 完整 smoke suite

```sh
ALLOW_UNPINNED_ORGMODE=1 bash tests/smoke/run.sh
```

- Result: exit 0。
- Output: 全部 22 个 smoke case 通过，包含：
  - `PASS refile_picker_builds_file_and_headline_candidates`
  - `PASS refile_picker_selects_and_cancels_destination`
  - `PASS legion_e2e_integrated_flow`
  - `All smoke cases passed.`
- 备注：`.tests/deps/orgmode` 不存在，因此按 runner 提示显式设置 `ALLOW_UNPINNED_ORGMODE=1`，使用 `/Users/c1/.local/share/nvim/lazy/orgmode`。
- 证明力：覆盖新增 picker 行为以及既有 punch、clock、capture handoff、capture pre-refile hook、todo trigger、Legion integrated flow。

### 4. diff hygiene

```sh
git diff --check
```

- Result: exit 0。
- 证明力：没有 whitespace error。

## 无效验证尝试

- `stylua --check lua/org_refile_picker.lua lua/plugins/orgmode.lua lua/tests/smoke/orgmode_smoke.lua` 返回 exit 127：当前机器没有 `stylua`。
- 第一次完整 smoke 运行时，runner 仍把 `SMOKE_ROOT_DIR` append 到 runtimepath，导致 worktree 内新增 case 被主工作区旧 `lua/tests/smoke/orgmode_smoke.lua` 遮蔽并显示 `unknown smoke case`。本次实现将 runner 改为 prepend `SMOKE_ROOT_DIR` 后重跑，完整 smoke 通过。
- `nvim --headless` 直接加载默认主配置时仍读取主工作区当前代码，不代表 worktree 分支结果；worktree 验证使用 spec-level 断言与 runner prepend 方式。

## Skips / Limitations

- 未做真实 TUI 截图验证。当前 headless 验证通过拦截 `vim.ui.select` 证明会打开 select/picker 路径；实际视觉由 Snacks picker 接管 `vim.ui.select` 后呈现。

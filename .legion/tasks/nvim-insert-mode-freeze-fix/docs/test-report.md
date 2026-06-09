# Test Report: nvim-insert-mode-freeze-fix

## Summary

Result: PASS for the reopened native-artifact repair.

The user suspected the issue started after `lazy-lock.json` took effect. The staged lockfile had updated many plugins, including insert-path candidates such as `LazyVim`, `blink.cmp`, `mini.pairs`, `opencode.nvim`, and `orgmode`. The implementation action was to synchronize the installed plugin state to the staged lockfile and rebuild/check `blink.cmp`.

After the user reported the failure still reproduced, macOS DiagnosticReports showed the stronger root cause: repeated `SIGKILL (Code Signature Invalid)` / `CODESIGNING Invalid Page` crashes when Neovim mapped native artifacts. The mapped sizes matched `blink.cmp`'s native fuzzy dylib and tree-sitter parser `.so` files.

## Commands

```sh
nvim --headless '+Lazy! restore' '+Lazy! build blink.cmp' '+qa!'
```

Result: exit 0. Lazy restored installed plugins to the lockfile versions and ran the `blink.cmp` build task.

```sh
expect -c 'spawn env TERM=xterm-256color nvim .legion/tasks/nvim-insert-mode-freeze-fix/tmp/post-restore-type.txt; sleep 2; send "i"; sleep 1; send "hello world"; sleep 2; send "\033:qa!\r"; expect { eof { exit [lindex [wait] 3] } timeout { exit 124 } }'
```

Result: exit 0. The default Neovim path entered insert mode, typed text, left insert mode, and exited.

```sh
expect -c 'spawn env TERM=xterm-256color nvim .legion/tasks/nvim-insert-mode-freeze-fix/tmp/post-restore-org.org; sleep 3; send "i"; sleep 1; send "* TODO hello"; sleep 2; send "\033:qa!\r"; expect { eof { exit [lindex [wait] 3] } timeout { exit 124 } }'
```

Result: exit 0. The org buffer path entered insert mode, typed text, left insert mode, and exited.

```sh
nvim --headless .legion/tasks/nvim-insert-mode-freeze-fix/tmp/post-headless.txt +'lua local keys=vim.api.nvim_replace_termcodes("ihello world<Esc>",true,false,true); vim.api.nvim_feedkeys(keys,"xt",false); vim.defer_fn(function() print("mode="..vim.api.nvim_get_mode().mode.." line="..vim.api.nvim_get_current_line()); vim.cmd("qa!") end,1000)'
```

Result: exit 0 with `mode=n line=hello world`.

## Why These Checks

- `Lazy restore` directly validates the user's lockfile hypothesis by forcing installed plugin checkouts to match `lazy-lock.json`.
- The `expect` checks exercise a real TUI path with actual `i`, typing, `<Esc>`, and `:qa!`, which is closer to the reported insert-mode workflow than headless-only checks.
- The org buffer smoke covers the repository's custom orgmode-heavy configuration and the updated `orgmode` lock entry.
- The headless check is a low-noise assertion that Neovim can process insert-mode input and return to normal mode.

## Limits

- iTerm and Terminal could not be operated with Computer Use because the tool denied those bundle IDs. VS Code integrated terminal was used as the GUI terminal fallback.
- The final fix is validated against the observed macOS crash reports and smoke checks; existing live Neovim/VSCodium extension processes may need restart to pick up the new Lua config.

## Reopened Verification

```sh
nvim --headless '+lua require("lazy").load({plugins={"blink.cmp"}}); print("blink_fuzzy", require("blink.cmp.config").fuzzy.implementation)' '+qa!'
```

Result: exit 0, printed `blink_fuzzy lua`.

```sh
nvim --headless '+enew' '+set ft=markdown' '+lua local ok,err=pcall(function() vim.treesitter.start(0, "markdown") end); print("markdown_ts", ok, err or "")' '+qa!'
```

Result: exit 0, printed `markdown_ts true`.

```sh
nvim --headless '+enew' '+set ft=org' '+lua local ok,err=pcall(function() vim.treesitter.start(0, "org") end); print("org_ts", ok, err or "")' '+qa!'
```

Result: exit 0, printed `org_ts true`.

```sh
TERM=xterm-256color expect -c 'spawn nvim -n .legion/tasks/nvim-insert-mode-freeze-fix/tmp/final-insert-native-fix.txt; after 1600; send "iabc"; after 700; send "\033:qa!\r"; expect eof; set result [wait]; puts "wait_result=$result"; exit [lindex $result 3]'
```

Result: exit 0. Neovim entered insert mode, accepted text, left insert mode, and quit.

```sh
find ~/Library/Logs/DiagnosticReports -maxdepth 1 -iname 'nvim-2026-06-09*.ips' -type f -print | sort | tail -4
```

Result: latest report remained `nvim-2026-06-09-144416.ips`; no new report was produced by the final parser or insert smoke checks.

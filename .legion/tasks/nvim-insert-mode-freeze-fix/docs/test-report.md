# Test Report: nvim-insert-mode-freeze-fix

## Summary

Result: PASS for the observed post-restore insert and typing paths.

The user suspected the issue started after `lazy-lock.json` took effect. The staged lockfile had updated many plugins, including insert-path candidates such as `LazyVim`, `blink.cmp`, `mini.pairs`, `opencode.nvim`, and `orgmode`. The implementation action was to synchronize the installed plugin state to the staged lockfile and rebuild/check `blink.cmp`.

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

- The original freeze was not consistently reproducible under automation after plugin restore/build. The fix is therefore validated as a runtime-state repair rather than a Lua configuration patch.
- Manual verification in the user's terminal is still useful because terminal UI timing and restored sessions can affect symptoms that scripted checks may miss.

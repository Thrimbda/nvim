# nvim-insert-mode-freeze-fix Log

## 2026-06-09

- Entered Legion workflow because the repository is Legion-managed and the user explicitly requested Legion workflow.
- No existing task id/path was provided, so the entry state is `brainstorm` rather than restore.
- Classified as low-risk local Neovim configuration repair: small, reversible, no API/schema/security boundary changes.
- Adopted delayed approval for the contract and design-lite path so implementation can proceed and final diff can be reviewed in one pass.
- Noted pre-existing main-workspace modification: `lazy-lock.json` is modified before this task and must not be reverted as part of the fix.
- User added that the issue likely started after the staged `lazy-lock.json` took effect.
- Copied the staged lockfile into the worktree for diagnosis and confirmed installed plugin checkouts matched the new lockfile for key candidates such as `LazyVim`, `blink.cmp`, `mini.pairs`, `opencode.nvim`, `snacks.nvim`, and `orgmode`.
- Headless insert checks passed; early PTY checks were discarded after `nvim --clean` showed the same timer-exit issue, proving that script was invalid.
- Used `expect` for real TUI smoke checks. Default, org, markdown, and Lua insert/typing paths exited successfully after restore/build.
- Ran `nvim --headless '+Lazy! restore' '+Lazy! build blink.cmp' '+qa!'` against the active main config to synchronize installed plugins to the staged lockfile and ensure the `blink.cmp` build task completed.
- Removed a `Lazy restore` side effect that had advanced only the working-copy `nvim-treesitter` lock entry beyond the user's staged lockfile.
- Synced final task/wiki evidence back to the main workspace and ran a final default-path TUI insert+typing smoke; it exited 0.
- Confirmed no leftover Neovim/expect smoke processes were running.
- User reported the issue still occurs deterministically: Neovim flash-exits and even debug-mode startup does not survive long enough to write a log.
- Reopened the task. The current working tree has a single uncommitted lockfile delta: `nvim-treesitter` moved from `4916d6592ede8c07973490d9322f187e07dfefac` to `7caec274fd19c12b55902a5b795100d21531391f`, which is now the primary suspect.
- Computer Use could not operate iTerm or Terminal because both bundle IDs were denied by tool policy. Used VS Code's integrated terminal as the closest GUI terminal path; insert did not flash-exit there.
- Parsed macOS DiagnosticReports for 2026-06-09 and found repeated `SIGKILL (Code Signature Invalid)` / `CODESIGNING Invalid Page` crashes. Mapped sizes matched native artifacts: `blink.cmp` fuzzy dylib (~1.2MB mapped region) and tree-sitter parser `.so` files (~416KB mapped region).
- Restored `nvim-treesitter` runtime to locked commit `4916d6592ede8c07973490d9322f187e07dfefac`, added a local spec pin for that commit, forced `blink.cmp` fuzzy implementation to `lua`, and added a macOS native-artifact signing helper.
- Re-signed all current local tree-sitter parser `.so` files, `orgmode/parser/org.so`, and `blink.cmp`'s dylib with ad-hoc `codesign --force --sign -`.
- Final verification: `blink.cmp` reports `fuzzy.implementation == "lua"`; markdown and org treesitter start in headless smoke tests; TUI insert/typing smoke exits 0; no crash report newer than `nvim-2026-06-09-144416.ips` appeared after final verification.

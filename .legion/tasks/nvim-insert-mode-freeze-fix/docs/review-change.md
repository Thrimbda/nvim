# Review Change: nvim-insert-mode-freeze-fix

## Verdict

PASS.

## Blocking Findings

None.

## Scope Review

- In scope: investigated lockfile-related insert-mode failure, synchronized installed plugins to the staged lockfile, verified default and org insert/typing paths.
- In scope: recorded Legion evidence and preserved the user's pre-existing staged `lazy-lock.json` update.
- Out of scope avoided: no broad Lua configuration rewrite, no plugin redesign, no terminal or shell changes.

## Correctness Review

The reopened investigation found a deterministic platform-level failure mode:

- macOS DiagnosticReports repeatedly recorded `SIGKILL (Code Signature Invalid)` with `CODESIGNING Invalid Page`.
- Mapped region sizes matched native Neovim artifacts: `blink.cmp`'s fuzzy dylib and tree-sitter parser `.so` files.
- The source change removes the insert-mode dependency on the `blink.cmp` native matcher by forcing `fuzzy.implementation = "lua"`.
- The source change pins `nvim-treesitter` to the lockfile commit and adds a build-time signing hook for local parser/native artifacts on macOS.
- Runtime repair re-signed the current installed parser/native artifacts.

Final parser and insert smoke checks exited 0, and no new `nvim` DiagnosticReports were produced after the final verification.

## Maintainability Review

No maintainability blocker. The added helper is small, macOS-gated, and only invoked from plugin build hooks. The `blink.cmp` Lua fuzzy fallback trades some completion matching performance for stability, which is acceptable for an editor-crash fix.

## Security Review

Security lens was not triggered. The task does not change auth, permissions, secrets, protocol boundaries, user data handling, or privileged input paths. The local `codesign --force --sign -` action is ad-hoc signing of user-local Neovim artifacts.

## Residual Risk

Existing live embedded Neovim processes may still have the old config loaded. They should be restarted before judging the final behavior.

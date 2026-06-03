## Summary

- Disable lazy.nvim's plugin-owned `lazy.lua` package source so malformed third-party package fragments cannot enter package cache.
- Make dadbod-grip command lazy-loading fully user-owned by declaring the real `Grip*` command list explicitly.
- Remove the stale `GripToggle` trigger that the installed plugin does not create.

## Validation

- Isolated worktree Neovim startup passed
- `Lazy! reload` passed with isolated config/state/cache
- Lazy assertions confirmed `pkg.sources` excludes `lazy`, dadbod-grip command triggers are complete, and problematic plugin-owned specs are absent from package cache
- `GripHome` command lazy-load trigger passed
- `git diff --check`

## Notes

- `stylua` was unavailable in this environment.

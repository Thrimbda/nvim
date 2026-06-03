## Summary

- Explicitly lazy-load Copilot and opencode so they no longer participate in Neovim's initial startup path.
- Preserve `:Copilot` command lazy-loading while loading Copilot suggestions on `InsertEnter`.
- Keep the fix limited to plugin loading timing; no theme, dashboard, lockfile, or terminal changes.

## Verification

- PASS: isolated worktree startup printed `startup-ok`.
- PASS: lazy spec assertion printed `lazy-spec-ok` and confirmed Copilot/opencode are not loaded during startup.
- PASS: `docs/startuptime-after.log` has no `copilot` or `opencode` startup entries.
- SKIPPED: `stylua --check` because `stylua` is not installed in this environment.

## Notes

- Neovim's built-in TUI `clear screen` remains expected; this change reduces the plugin-caused blank startup interval.
- Manual terminal UX confirmation is still recommended after applying the config.

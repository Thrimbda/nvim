# nvim-dadbod-grip-invalid-lazy-spec-fix

## Metadata

- `task-id`: `nvim-dadbod-grip-invalid-lazy-spec-fix`
- `status`: `active`
- `risk`: `low`
- `schema-version`: `2026-06-03`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

- This task fixes Lazy's invalid `Grip` plugin spec error by making the nvim repository stop consuming plugin-owned `lazy.lua` package specs.
- The current effective rule is that user-owned lazy.nvim specs are the source of truth for command triggers and plugin behavior in this config.
- `dadbod-grip.nvim` now declares the full real `Grip*` command list in `lua/plugins/dadbod-grip.lua`, including `GripOpen`, `GripAttach`, `GripDetach`, and other commands added upstream.
- The stale `GripToggle` command trigger was removed because the installed plugin does not create it.
- Follow-up correction: `pkg.enabled = false` is required, because changing only `pkg.sources` does not stop lazy.nvim from loading a pre-existing `pkg-cache.lua` that already contains the malformed package spec.

## Reusable Decisions

- Do not rely on third-party plugin-owned `lazy.lua` files for behavior that matters in this nvim config; declare it in `lua/plugins/*.lua` instead.
- If a plugin-owned package spec is malformed or incomplete, disable that package-spec source rather than patching files under `~/.local/share/nvim/lazy/**` or pinning to an older commit as the primary repair.
- Disable the package spec subsystem with `pkg.enabled = false` when stale `pkg-cache.lua` entries are already present; changing only `pkg.sources` is not enough for existing cache files.
- Validate worktree nvim config through isolated `XDG_CONFIG_HOME`, `XDG_CACHE_HOME`, and `XDG_STATE_HOME`; otherwise tests can accidentally read the main `~/.config/nvim` or cached Lazy specs.

## Related Raw Sources

- `plan`: `.legion/tasks/nvim-dadbod-grip-invalid-lazy-spec-fix/plan.md`
- `log`: `.legion/tasks/nvim-dadbod-grip-invalid-lazy-spec-fix/log.md`
- `tasks`: `.legion/tasks/nvim-dadbod-grip-invalid-lazy-spec-fix/tasks.md`
- `test-report`: `.legion/tasks/nvim-dadbod-grip-invalid-lazy-spec-fix/docs/test-report.md`
- `review`: `.legion/tasks/nvim-dadbod-grip-invalid-lazy-spec-fix/docs/review-change.md`
- `report`: `.legion/tasks/nvim-dadbod-grip-invalid-lazy-spec-fix/docs/report-walkthrough.md`

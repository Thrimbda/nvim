# install-sops-nvim

## Metadata

- `task-id`: `install-sops-nvim`
- `status`: `active`
- `risk`: `medium`
- `schema-version`: `2026-06-08`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

- Installed `Thrimbda/sops.nvim` as a focused LazyVim/lazy.nvim plugin spec.
- Current decision: use eager loading with `lazy = false` because upstream needs `BufReadCmd` handlers before the first supported encrypted file is opened.
- Current decision: set `main = "nvim_sops"` and `opts = {}` to avoid lazy.nvim module inference risk and avoid hardcoded credentials.
- `lazy-lock.json` now pins `sops.nvim` to commit `1656dac4d893f2d96c7ccb6d3fa3259bde6004e5` after `update-sops-nvim`.
- `sops` CLI is not installed on the verification host and remains an external runtime dependency.

## Reusable Decisions

- For Neovim plugins that install `BufReadCmd` handlers for first-read workflows, do not lazy-load on `BufReadPre`, `BufEnter`, or similar file events unless upstream explicitly supports it.
- For SOPS or secret-editing plugins, do not commit account-specific key paths, cloud credential paths, profiles, or secret material as plugin defaults.
- Verify plugin module setup and full headless config load without opening or writing real secret files.

## Related Raw Sources

- `plan`: `.legion/tasks/install-sops-nvim/plan.md`
- `log`: `.legion/tasks/install-sops-nvim/log.md`
- `tasks`: `.legion/tasks/install-sops-nvim/tasks.md`
- `rfc`: `.legion/tasks/install-sops-nvim/docs/rfc.md`
- `rfc-review`: `.legion/tasks/install-sops-nvim/docs/review-rfc.md`
- `test-report`: `.legion/tasks/install-sops-nvim/docs/test-report.md`
- `review`: `.legion/tasks/install-sops-nvim/docs/review-change.md`
- `report`: `.legion/tasks/install-sops-nvim/docs/report-walkthrough.md`
- `follow-up-update`: `.legion/tasks/update-sops-nvim/plan.md`

## Notes

- Follow-up `update-sops-nvim` kept the plugin spec unchanged and updated only the lockfile pin.

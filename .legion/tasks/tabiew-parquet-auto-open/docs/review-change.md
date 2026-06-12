# Review Change

## Verdict

PASS.

## Blocking Findings

None.

## Scope Review

- In scope: early Neovim file handler registration, Tabiew invocation path, missing-`tw` fallback, and Legion evidence.
- Out of scope avoided: no system package installation, no data-viewer plugin addition, no lockfile modification, and no unrelated plugin/config churn.

## Correctness Review

- `init.lua` requires `config.file_handlers` before `config.lazy`, which is necessary because LazyVim loads `lua/config/autocmds.lua` on `VeryLazy` and that would be too late for `nvim data.parquet` startup reads.
- `lua/config/file_handlers.lua` registers a dedicated `BufReadCmd` group for `*.parquet`, `*.pqt`, and `*.parq`.
- The callback resolves the target path to an absolute path before invoking `tw`.
- Missing `tw` is handled with a non-modifiable `nofile` buffer containing install instructions.
- The Tabiew terminal process is tied to the opened buffer and schedules buffer deletion on exit, avoiding stale terminal buffers after quitting Tabiew.

## Verification Review

- `docs/test-report.md` records direct command evidence for module registration, fallback behavior, direct startup handling, and `git diff --check`.
- The initial failed validation correctly identified the too-late `autocmds.lua` placement and was resolved by moving the handler into an early module.
- Residual limitation is explicit: `tw` is unavailable in this environment, so real Tabiew TUI launch was not automated.

## Security Review

- Security lens: not applied beyond trigger scan.
- Reason: no auth, secrets, crypto, trust boundary, network, privilege, or user-data exposure behavior changes.

## Residual Risks

- Real Tabiew rendering and keyboard behavior need an interactive smoke check on a machine with `tw` installed.
- If `tw` changes command-line behavior in future releases, this config depends only on the stable `tw <file>` interface documented by Tabiew.

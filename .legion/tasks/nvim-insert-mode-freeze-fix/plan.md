# nvim-insert-mode-freeze-fix

## Contract

- `name`: Fix Neovim insert-mode freeze
- `taskId`: `nvim-insert-mode-freeze-fix`
- `goal`: Restore normal Neovim editing so entering insert mode does not freeze, hang, or terminate the editor.
- `problem`: The current Neovim configuration becomes unusable when insert mode is entered. Insert-mode entry is a core editing path, so the fix must identify the local configuration or plugin trigger and remove the regression without broad config churn.

## Acceptance

- Entering insert mode in this configuration no longer freezes, hangs, or exits Neovim.
- The fix is scoped to the insert-mode trigger path and preserves normal plugin behavior where possible.
- Existing LazyVim/lazy.nvim conventions remain intact.
- Verification includes an automated insert-mode smoke check plus any targeted plugin-state checks needed by the fix.
- The task records residual limits if a fully interactive terminal-only symptom cannot be proven by automation.

## Scope

- Inspect local insert-mode triggers, plugin lazy-load events, insert-related autocmds, keymaps, and recent startup-load changes.
- Apply the smallest reversible configuration change that removes the insert-mode failure.
- Update Legion task artifacts with verification and review evidence.

## Non-Goals

- Do not perform broad plugin upgrades or lockfile churn unless the root cause requires it.
- Do not redesign completion, AI assistant, colorscheme, dashboard, or editor UI behavior outside the failing trigger.
- Do not change global shell, terminal emulator, or system Neovim installation.
- Do not migrate the configuration away from LazyVim/lazy.nvim patterns.

## Assumptions

- The failing path is caused by this repository's Neovim configuration or plugin specs, not by a system-wide Neovim binary defect.
- The failure can be narrowed by running Neovim with this config and driving insert-mode entry from a smoke test.
- It is acceptable to lazy-load, disable, or retime a nonessential insert-triggered plugin if it is the root cause.
- Existing modified `lazy-lock.json` in the main workspace is treated as pre-existing user/environment state and must not be reverted unless proven directly relevant.

## Constraints

- Keep changes small and easy to revert.
- Avoid touching unrelated plugin specs or generated files.
- Use an isolated git worktree for implementation changes.
- Preserve user edits that predate this task.

## Risks

- A plugin may hang only in an interactive TUI, so headless verification may need to be paired with a timeout-driven TUI smoke test.
- Insert-mode plugin triggers can mask each other; fixing one may expose another delayed failure.
- If the root cause is in plugin code or a lockfile update, the local config fix may need to disable or retime behavior rather than patch upstream code.

## Design Summary

- Treat this as low-risk local configuration repair unless investigation shows dependency or cross-module changes are required.
- First reproduce with a timeout-bound Neovim invocation that enters insert mode.
- Compare normal startup against `--clean` or minimal config where useful to distinguish Neovim core from local config.
- Inspect `InsertEnter`, insert-mode keymaps, AI/completion plugins, and recent lazy-load changes before editing.
- Prefer removing the problematic insert-mode trigger over adding sleeps, redraw hacks, or broad plugin disabling.

## Phases

- Brainstorm: materialize this task contract and design-lite summary.
- Engineer: reproduce, isolate the root cause, and apply the minimal configuration fix in a worktree.
- Verify: run timeout-bound insert-mode smoke checks and targeted assertions.
- Review: check scope, regression risk, and verification quality.
- Report: write walkthrough and wiki notes for reusable Neovim/LazyVim learnings.

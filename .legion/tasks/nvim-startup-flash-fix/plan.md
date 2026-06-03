# nvim-startup-flash-fix

## Contract

- `name`: Fix Neovim startup flash
- `taskId`: `nvim-startup-flash-fix`
- `goal`: Remove the noticeable black-screen flash that appears when launching Neovim from the terminal.
- `problem`: Starting Neovim briefly clears or paints the terminal black before the editor UI recovers. It does not break functionality, but it makes startup feel visually jarring.

## Acceptance

- Launching `nvim` no longer produces a noticeable black flash caused by local startup configuration.
- Existing Neovim behavior and plugin loading remain intact.
- The fix is minimal and avoids broad plugin upgrades, UI rewrites, or unrelated startup optimization.
- Verification records the startup path checked and any remaining visual limitations that cannot be proven automatically.

## Scope

- Inspect local Neovim startup configuration and plugin setup for options that repaint or clear the screen during startup.
- Apply the smallest configuration change that removes the flash.
- Run a lightweight startup verification and document the result.

## Non-Goals

- Do not redesign the colorscheme, statusline, dashboard, or general UI.
- Do not perform broad plugin updates or lockfile churn unless directly required.
- Do not tune general startup performance beyond what is needed for the visual flash.
- Do not change shell, terminal emulator, or global Vim configuration outside this Neovim config.

## Assumptions

- The reported `vim` entry path resolves to this Neovim configuration, either via `nvim` or a shell alias.
- The flash is caused by startup repaint behavior in local config or plugin settings, not by the terminal emulator itself.
- Manual visual verification is acceptable for the final UX-specific acceptance criterion.

## Constraints

- Keep the change small and reversible.
- Preserve LazyVim/Lazy.nvim conventions already used by this config.
- Avoid touching unrelated files or existing user changes.

## Risks

- Startup flashes are partly terminal-dependent, so automated checks may only prove that Neovim starts successfully.
- Disabling a visual startup feature may slightly change the initial screen shown before the first buffer is ready.
- Plugin-managed startup behavior may have multiple overlapping sources, requiring care to avoid an overbroad fix.

## Design Summary

- Prefer identifying and disabling the specific startup UI repaint source over adding delays or broad redraw hacks.
- Treat this as low-risk configuration work unless investigation reveals cross-plugin coordination or terminal-specific behavior.
- Keep verification focused on `nvim` startup health plus a documented manual visual check.

## Phases

- Brainstorm: create and confirm this task contract.
- Engineer: inspect startup config, apply the smallest fix, and avoid unrelated churn.
- Verify: run startup/headless checks and record manual visual validation limits.
- Review: check for regressions, out-of-scope edits, and missing verification.
- Report: write reviewer-facing summary and update wiki knowledge if reusable.

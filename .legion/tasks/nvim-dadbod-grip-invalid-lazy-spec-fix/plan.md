# Nvim Dadbod Grip Invalid Lazy Spec Fix

## Task Identity

- Name: Nvim Dadbod Grip Invalid Lazy Spec Fix
- Task ID: `nvim-dadbod-grip-invalid-lazy-spec-fix`
- Trigger: user reported Lazy/Neovim error `Invalid plugin spec { cmd = { "Grip", ... } }`.
- Base ref: `origin/master`

## Goal

Make the Neovim configuration robust against invalid plugin-owned Lazy package specs, specifically the broken `dadbod-grip.nvim/lazy.lua` command-only fragment, so Lazy package-cache rebuilds and Neovim startup no longer surface the invalid spec error.

## Problem

The user configuration for `joryeugene/dadbod-grip.nvim` has a valid plugin source, but the installed plugin also ships a top-level `lazy.lua` file that returns only `cmd = { ... }`. lazy.nvim treats plugin-owned `lazy.lua` files as package specs and later validates them as plugin specs. A command-only fragment without a plugin source can become `Invalid plugin spec { cmd = ... }` when Lazy rebuilds or consumes the package cache.

## Acceptance Criteria

- Neovim headless startup completes without the invalid `Grip` plugin spec error.
- Lazy package-cache refresh/reload paths complete without reading `dadbod-grip.nvim/lazy.lua` as a plugin spec.
- The user-owned `dadbod-grip.nvim` plugin declaration remains explicit and complete enough to lazy-load the intended `Grip` commands.
- The fix is repository-owned in `/home/c1/.config/nvim`, not a manual edit to `~/.local/share/nvim/lazy/dadbod-grip.nvim` or a one-off cache deletion.
- Evidence records the observed root cause, implemented configuration boundary, and validation commands.

## Scope

- Inspect the Neovim Lazy configuration and the affected dadbod-grip plugin declaration.
- Change the nvim repository configuration so invalid plugin-owned `lazy.lua` package specs are not consumed.
- Keep required plugin behavior explicitly represented in user-owned specs where needed.
- Run targeted non-interactive Neovim/Lazy validation and record evidence.

## Non-Goals

- Do not patch plugin source under `~/.local/share/nvim/lazy/**` as the durable fix.
- Do not pin dadbod-grip to an older commit as the primary fix.
- Do not preserve backward compatibility with lazy.nvim's plugin-owned `lazy.lua` package source if it can reintroduce invalid third-party specs.
- Do not redesign unrelated LazyVim plugin configuration.

## Assumptions

- The pasted error is from lazy.nvim validating the plugin-owned dadbod-grip `lazy.lua` package spec.
- Disabling consumption of plugin-owned `lazy.lua` package specs is acceptable in this configuration, as user-owned specs should be the durable source of plugin behavior.
- If another plugin previously depended on a plugin-owned `lazy.lua` file, the nvim repository should declare that behavior explicitly rather than relying on automatic package-spec ingestion.

## Constraints

- Use Legion task docs and an isolated Git worktree for repository changes.
- Keep the repair in `/home/c1/.config/nvim`, not `/home/c1/dotfiles`.
- Do not modify unrelated local plugin clones or generated cache files as the final solution.

## Risks

- Disabling lazy.nvim's `lazy.lua` package source can expose implicit plugin behavior that was previously supplied by upstream package specs.
- Headless validation cannot prove every interactive UI surface, so validation should include Lazy reload/package-cache behavior plus explicit source inspection.

## Design Summary

- Treat user-owned plugin specs as the source of truth for this nvim config.
- Disable lazy.nvim's plugin-owned `lazy.lua` package-source ingestion to prevent invalid third-party package fragments from entering package cache.
- Review currently installed plugins with `lazy.lua` files and explicitly cover any behavior that matters in the user config instead of relying on upstream auto-specs.
- Validate by exercising headless startup, Lazy reload/package-cache refresh behavior, and dadbod-grip command trigger declarations.

## Phases

- Brainstorm: materialize this robust Lazy package-spec repair contract.
- Engineer: patch the nvim Lazy configuration and affected plugin declarations as needed.
- Verify: run targeted Neovim/Lazy validation and capture test evidence.
- Review/report/wiki: check readiness, produce handoff docs, and write back durable Legion knowledge.

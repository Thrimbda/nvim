# install-gitsigns-nvim

## Task Contract

- **Name**: Install gitsigns.nvim
- **Task ID**: install-gitsigns-nvim
- **Goal**: Install `lewis6991/gitsigns.nvim` in the existing lazy.nvim setup so Git status signs and hunk actions are available for supported buffers.
- **Problem**: The configuration currently lacks an explicit lazy.nvim spec for gitsigns, making the installation intent unclear despite lockfile presence.

## Acceptance

- [ ] A lazy.nvim plugin spec for `lewis6991/gitsigns.nvim` exists under `lua/plugins/` and is discoverable by `import = "plugins"`.
- [ ] The spec is minimal and non-destructive, keeping default behavior unless existing config requires customization.
- [ ] Config load remains successful in a lightweight headless startup check.
- [ ] No unrelated files or plugin behavior were changed.

## Scope

- `lua/plugins/gitsigns.lua`
- `.legion/tasks/install-gitsigns-nvim/**`

## Phases

1. Contract
2. Implementation
3. Verification
4. Closeout

---

Created: 2026-06-24

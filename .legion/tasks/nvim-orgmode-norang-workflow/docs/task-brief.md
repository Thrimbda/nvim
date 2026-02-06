# Task Brief: Norang-style orgmode workflow for Neovim

## Problem
Design and implement a Norang-inspired workflow in Neovim (nvim-orgmode) that provides:
- Custom agenda views similar to Norang block agenda
- Punch in/out continuous clocking with a default task and parent fallback
- Clear, repo-local documentation and a PR-ready summary

## Acceptance Criteria
- orgmode config defines custom agenda commands for block agenda, NEXT list, and REFILE inbox
- Punch in/out commands keep clocks running between punch in/out, with fallback to parent task or default task
- Default task is located by :ID: and configurable in Lua
- Keymaps are provided for punch actions and block agenda
- Documentation explains setup and daily usage
- PR body and walkthrough docs are generated

## Assumptions
- Neovim 0.11+ and nvim-orgmode are already installed and enabled
- Org files live under the existing `org_agenda_files` path (`~/OneDrive/cone/**/*`)
- The user will set a stable Organization task `:ID:` in an org file
- nvim-orgmode exposes clock actions via `orgmode.action` and/or default mappings
- No automated tests exist for this config repo

## Risks
Low risk. Changes are limited to Lua config and docs; rollback is removing the new module/config entries.

## Verification
- Open `:Org agenda b` and confirm the block agenda sections render
- Punch in (`F9 i`) clocks into the default Organization task
- Clock a task, then use keep-running clock out (`F9 O`) to fall back to parent/default
- Punch out (`F9 o`) stops continuous clocking
- Confirm clock logs are stored in LOGBOOK drawers

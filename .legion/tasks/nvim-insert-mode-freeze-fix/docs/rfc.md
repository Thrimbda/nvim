# Design-lite: nvim-insert-mode-freeze-fix

## Decision

Use a timeout-bound reproduction-first workflow and make the smallest local configuration change that removes the insert-mode failure.

## Rationale

Entering insert mode usually triggers a narrow set of config surfaces: `InsertEnter` autocmds, insert-mode keymaps, completion/AI plugins, and lazy.nvim plugin specs with insert events. The fastest reliable repair is to identify that trigger instead of changing unrelated startup or UI behavior.

## Verification

- Run Neovim with this config under a timeout and feed an insert-mode transition.
- Add targeted checks for the plugin spec or autocmd surface changed by the fix.
- Record any terminal-interactive limitation if a headless check cannot fully prove the original symptom.

## Rollback

Revert the small config change and associated Legion task artifacts.

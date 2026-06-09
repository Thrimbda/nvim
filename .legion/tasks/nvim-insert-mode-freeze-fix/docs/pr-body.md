# nvim-insert-mode-freeze-fix

## Summary

- Synchronized installed plugins to the staged `lazy-lock.json` with `Lazy restore`.
- Ran `Lazy build blink.cmp`.
- Verified default and org insert/typing paths with TUI `expect` smoke checks.
- Added Legion evidence for the diagnosis, verification, and review.

## Validation

- `nvim --headless '+Lazy! restore' '+Lazy! build blink.cmp' '+qa!'`
- TUI default buffer insert + typing smoke: exit 0
- TUI org buffer insert + typing smoke: exit 0
- Headless insert + typing assertion: exit 0, `mode=n line=hello world`

## Notes

No Lua config patch was needed. The evidence points to plugin runtime state after the staged lockfile update rather than a stable source-level config defect.

# Review Change

## Result

PASS.

## Blocking Findings

None.

## Scope Review

- In scope: archive candidate computation now follows Norang month-prefix semantics.
- In scope: `Tasks to Archive` matcher now uses `-REFILE/` instead of the bare implementation tag.
- In scope: virtual search adapter handles the exact archive query and adds internal candidate filtering.
- In scope: smoke coverage includes this-month, last-month, old DONE, open TODO, and REFILE DONE behavior.
- No unrelated files or user local state were changed.

## Correctness Review

- The new rule matches Norang's documented behavior: only done-state todos with no current-month or last-month timestamp in their subtree become archive candidates.
- The `-REFILE/` archive query prevents old REFILE items from appearing in the archive block while keeping internal `ARCHIVE_CANDIDATE` available for virtual classification.
- Tests verify both internal virtual tags and agenda-query behavior.

## Maintainability Review

- The change keeps the existing virtual tag adapter architecture from PR #11.
- The exact `-REFILE/` interception is intentionally narrow and documented in the task contract. A future broader tags search feature may want an explicit orgmode.nvim extension point, but that is outside this bugfix.
- Legacy `archive.stale_days` / `recent_month_window` config remains accepted for compatibility, though the Norang-compatible implementation no longer relies on day-count staleness.

## Security

No security trigger. The change does not touch auth, permissions, secrets, trust boundaries, persistence formats, or user-controlled privileged execution.

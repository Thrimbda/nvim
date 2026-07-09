# Render Handoff

## Decision

Artifact/local-only render path.

## Artifact

- HTML artifact: `.legion/tasks/org-agenda-refresh-archive-fix/docs/report-walkthrough.html`
- Entrypoint: `report-walkthrough.html`
- Fallback source: `.legion/tasks/org-agenda-refresh-archive-fix/docs/report-walkthrough.md`

## Rationale

The repository currently has no Pages or PR preview workflow. It only has `.github/workflows/org-smoke.yml`.

This task is a scoped nvim org plugin bug fix. Adding a new Pages publishing workflow would expand the delivery surface and introduce repository settings, token permissions, and public/private visibility decisions that are outside the task contract.

## Reviewer Use

Reviewers can open the checked-in HTML artifact locally or from the PR file view as an artifact/source file. No public rendered URL is promised by this PR.

## Future Option

If stable rendered PR URLs become useful, create a separate task to design a GitHub Pages or authenticated internal preview workflow with explicit visibility and fork-PR safety rules.

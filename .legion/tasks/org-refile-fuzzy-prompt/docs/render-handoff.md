# Render Handoff: org-refile-fuzzy-prompt

## Decision

Artifact-only / local render。

## Artifact

- HTML artifact: `.legion/tasks/org-refile-fuzzy-prompt/docs/report-walkthrough.html`
- Entrypoint: `report-walkthrough.html`

## Reason

当前仓库只有 `.github/workflows/org-smoke.yml`，没有现成 GitHub Pages、internal static host 或 HTML preview workflow。新增 Pages preview workflow 会扩大本次 refile input 修复 scope，并需要仓库 Pages setting、权限与 fork PR trust model 决策。

## Reviewer Path

本次 PR reviewer 可以直接打开 HTML artifact，或在 PR 中阅读 `docs/report-walkthrough.md` 与 `docs/pr-body.md`。该 artifact 不包含 secrets、private logs、tokens、account data 或 customer data。

## Resume Condition

如果 reviewer 明确需要稳定 rendered URL，应另开或扩展一个 CI/render 任务，先确认平台、可见性、Pages setting、fork PR 策略与 preview URL shape，再引入 `pr-html-render` 的 GitHub Pages template。

# GitHub — comments and requests

> Last verified: 2026-09-17

Library-owned. Read-only copy in `.cursor/library-notes/github.md`.

Use `gh`. Skill: `.cursor/skills/github-collab/SKILL.md`.

## sgs-agent-skills is Logan's

`https://github.com/logan-bishop-sgs/sgs-agent-skills` is the shared
library. **Other agents must not change it** — no commits, no pushes, no
PRs, no edits to `author-notes/`, `skills/`, or `templates/`.

If a skill or note is wrong: log it in **this repo's**
`CONTEXT/skill-issues.md` and send it with the `report-skill-issue`
skill (dashboard **Report Feedback**, related feature **Cursor skills**).
Do not open a PR against the library.

Logan may update the library when he asks an agent to.

## What you may do without extra permission

- Read issues, PRs, checks, and file contents.
- Comment on an issue or PR the user is talking about (not to sneak
  library edits through a comment).
- Open an **issue** if they asked to file a request / bug / follow-up.
- Open a PR on **their** GitHub repo (not `sgs-agent-skills`) after they
  asked.

## What you must ask first

- Anything that merges, closes, or deletes.
- Force-push, rewriting `main`/`master`.
- Changing org/repo settings, collaborators, or visibility.
- Moving an Azure DevOps app onto GitHub.

## NAM EHS split

| Host | What lives there |
|---|---|
| Azure DevOps `SGS-NAM-Dev` | `ehs_dashboard`, V3, most production apps |
| GitHub `logan-bishop-sgs/sgs-agent-skills` | Cursor skills + Logan's author-notes (hands off) |

Do not add this skills library as a second remote on an ADO repo.

## Account

`SGS_EMAIL` in `.env` is this user's SGS identity. `gh auth login` with
their own SGS-linked GitHub account. Logan's GitHub user is
`logan-bishop-sgs`.

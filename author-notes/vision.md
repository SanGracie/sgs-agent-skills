# Vision — agents for the whole team

> Last verified: 2026-09-17

Library-owned. Logan updates this in `author-notes/`.

## Where this is going

Dozens of SGS people (eventually anyone who should) talk to **their**
Cursor agent in plain language. Engineering already gave the skills
(LIMS extracts, Outlook datadrop, setup). They should not need to know
git, AniTa internals, or how to write a SKILL.md.

Setup is one sentence: **help me get set up** in the working repo.

## Two places to write

| Place | Who writes | What |
|---|---|---|
| GitHub `sgs-agent-skills` | Logan / engineering only | Skills, templates, these notes |
| Each person's repo `CONTEXT/` | Their agent + them | Project docs, `work-log.md`, **`skill-issues.md`** |

Agents never "improve" the GitHub library from a tech laptop.

## Skill is wrong → engineering

1. Agent logs the lesson in **that repo's** `CONTEXT/skill-issues.md`.
2. User says send it to engineering (or the agent offers).
3. Dashboard **Report Feedback** (sidebar), related feature
   **Cursor skills**. Same queue as a broken report:
   `/admin/report-feedback`.
4. Engineering fixes the library, techs **refresh skills**.

Do not use GitHub PRs for that loop. Feedback is the inbox.

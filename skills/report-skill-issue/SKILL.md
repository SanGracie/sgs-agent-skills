---
name: report-skill-issue
description: >-
  Logs a Cursor skill problem in this repo's CONTEXT/skill-issues.md and
  sends it to engineering via the EHS Dashboard Report Feedback queue
  (related feature Cursor skills). Use when a skill failed, the user
  says send this to engineering, file feedback, report a skill bug, or
  the agent learned the library instructions were wrong.
---

# Report a skill issue to engineering

Do **not** edit GitHub `sgs-agent-skills`. This person's notes stay in
**this repo**. Engineering's inbox is the dashboard **Report Feedback**
queue, not a GitHub PR.

## Always write locally first

Append to `<context-dir>/skill-issues.md` (create from the setup
template if missing). Newest at the top. Timezone on the date.

```markdown
## YYYY-MM-DD TZ — <skill-name> — open

- **Who:** name + SGS_EMAIL from `.env` if present
- **Skill:** extract-seesales / setup-agent / …
- **What we tried:**
- **What happened:**
- **What the skill said to do:**
- **What would help:**
- **Sent to Feedback:** no
```

`<context-dir>` is the same CONTEXT folder setup-agent created
(app `CONTEXT/` or repo `CONTEXT/`). Also append a one-liner to
`work-log.md`.

## Then send to engineering (Feedback)

Ask once: "Send this to engineering on the dashboard Feedback page?"

If yes:

1. Build `issue_text` from the block above (plain text, no secrets,
   no `ANITA_PASSWORD`). Cap 8000 characters.
2. Related feature is exactly `Cursor skills`.
3. Dashboard base URL: `.env` `EHS_DASHBOARD_BASE_URL`, else
   `https://us-ehs-tv-reports-hrc7gxa6dtesdfca.centralus-01.azurewebsites.net`.
4. Copy `issue_text` to the clipboard if you can (`Set-Clipboard` on
   Windows).
5. Open:

```
<BASE>/?feedback=1&feature=Cursor%20skills
```

If `issue_text` is under 1500 characters, also add `&issue=` with
URL-encoding. Longer drafts stay on the clipboard / in
`skill-issues.md` — the user pastes into the box.

6. They must be signed into the dashboard. They click **Submit
   Feedback**. You cannot submit for them (session cookie).
7. When they confirm it submitted, change **Sent to Feedback:** to
   `yes` in `skill-issues.md`.

If they say no, leave **Sent to Feedback:** `no`. The local log is
enough until they are ready.

## Do not

- Push or PR `logan-bishop-sgs/sgs-agent-skills`
- "Fix" the shared skill in GitHub from a tech laptop
- Put passwords in the ticket
- Email a screenshot as the only record

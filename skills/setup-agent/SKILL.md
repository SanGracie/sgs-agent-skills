---
name: setup-agent
description: >-
  Sets up a Cursor agent workspace from the SGS cursor-skills library:
  copies LIMS skills, writes a personalized .cursor/rules/workspace.mdc,
  and creates CONTEXT/ docs plus admin/plans. Use when the user says
  help me get set up, set up cursor, set up the agent, create cursor
  rules, CONTEXT folder, onboard this repo, or personalize my rules.
---

# Setup a Cursor agent workspace

Turn the user's **working repo** into a Logan-style Cursor workspace,
filled in with **their** name, role, and repo — not a copy of
`ehscloudreporting`.

This library's templates live in `templates/` next to `skills/`.

## Do not

- Copy `ehs_dashboard/CONTEXT/` or any other app's architecture docs
  into a different repo.
- Create more than **one** `.mdc` file in the target. The only rule
  file is `.cursor/rules/workspace.mdc`.
- Put `.cursor/rules/` inside an app package.
- Commit `.env`, passwords, tokens, `.trc`, or `anita.wcf`.
- Run this against the `cursor-skills` library itself unless the user
  explicitly wants docs in this repo.

## Resolve paths

1. **Library root** — folder that contains `skills/` and `templates/`.
   Walk up from this `SKILL.md` (`skills/setup-agent/`). If this skill
   was copied into a project as `.cursor/skills/setup-agent/` and
   `templates/` is missing, clone
   `https://github.com/logan-bishop-sgs/cursor-skills` to a temp dir
   and use that as the library root.
2. **Target root** — the git repo the user wants set up.
   - If the current workspace **is** `cursor-skills`, ask for the
     working-repo path (their dashboard, V3 clone, etc.).
   - Otherwise the current workspace is the target.
   - Never guess a OneDrive sibling. Confirm the path exists
     (`Test-Path`) before writing.

## Interview (do this first)

Ask, or infer from git/user config and the repo, then confirm:

| Field | Example |
|---|---|
| Name | Carl Santos |
| Role | Data technician, NAM EHS |
| Team | Manila / reports to Logan Bishop |
| Expertise | one line |
| What this repo is | one line a new tech would need |
| Primary app folder | `ehs_dashboard`, repo root, etc. |
| Install LIMS skills? | default **yes** for NAM EHS |

Use `AskQuestion` when you need a choice (target path, overwrite
existing rules, include LIMS). Do not block on polish — a short
role line is enough.

## Explore the target before writing layout

Read the target. Do not invent folders.

- `git rev-parse --show-toplevel`, `git remote -v`, top-level listing
- README, `app/`, `src/`, deploy scripts
- Existing `.cursor/`, `CONTEXT/`, `admin/`
- Gitignored sibling repos (name them in layout; do not add them)

If `workspace.mdc` or `CONTEXT/INDEX.md` already exists, show a
diff of what you would change and **ask before overwrite**. Merge
Developer Context; do not wipe a layout section you did not verify.

## Install skills

Copy these folders from `<library>/skills/` into
`<target>/.cursor/skills/<name>/`:

- `setup-agent` (this skill)
- `extract-seesales`
- `extract-tat-by-group`
- `outlook-datadrop-rule`

Skip LIMS folders only if the user said no. Overwrite skill copies
from this library (they are the source). Keep any extra skills
already in the target.

LIMS skills currently assume a Windows PC with AniTa + VPN and
`ANITA_PASSWORD` in the process env / repo `.env` (not git). Paths
inside those skills are `.cursor/skills/...` — correct after copy.

## Write files from templates

Read each file in `<library>/templates/` and substitute placeholders.
Today's date is the user_info date (`YYYY-MM-DD`).

| Template | Write to |
|---|---|
| `workspace.mdc` | `<target>/.cursor/rules/workspace.mdc` |
| `CONTEXT-INDEX.md` | `<context-dir>/INDEX.md` |
| `CONTEXT-project-overview.md` | `<context-dir>/project-overview.md` |
| `CONTEXT-conventions.md` | `<context-dir>/conventions.md` |
| `admin-plans-README.md` | `<target>/admin/plans/README.md` |
| `admin-CONTEXT-subagents.md` | `<target>/admin/CONTEXT/subagents.md` |

**Context dir:** if there is a clear primary app folder, use
`<target>/<app>/CONTEXT/`. Otherwise `<target>/CONTEXT/`.

**Placeholders**

- `{{TODAY}}` `{{NAME}}` `{{ROLE}}` `{{TEAM}}` `{{EXPERTISE}}` `{{BUSINESS}}`
- `{{WORKSPACE_TITLE}}` — short title for the repo
- `{{REPO_ONE_LINER}}` — what it is
- `{{PRIMARY_APP}}` — folder or repo name INDEX talks about
- `{{CONTEXT_DIR}}` — e.g. `ehs_dashboard/CONTEXT`
- `{{CONTEXT_INDEX_PATH}}` — e.g. `ehs_dashboard/CONTEXT/INDEX.md`
- `{{REPO_LAYOUT}}` — markdown from **your explore**, not from
  `ehscloudreporting`'s layout. Name each top-level area, what must
  not be deployed, and which folders are other git repos.
- `{{DIAGNOSIS_LINE}}` — if a `diagnosis.md` exists, link it; else
  one sentence pointing at logs + health.
- `{{TASK_ROWS}}` — extra INDEX rows for real features you found
  (`| Accutest SEE SALES extract | \`.cursor/skills/extract-seesales/SKILL.md\``)
- `{{WHERE_NEW_WORK_GOES}}` — where new routes/scripts/docs go in
  **this** repo. If you cannot tell, write "ask before inventing a
  package" rather than copying another app's table.

Replace every `{{...}}`. Do not leave placeholders.

Create empty `admin/plans/active/` and `admin/plans/completed/`
(add a `.gitkeep` if the target tracks them in git).

If `admin/` is gitignored in the target, still write the files on
disk and tell the user they are local-only.

## INDEX rows for LIMS (when those skills are installed)

Add to the task table:

| Accutest SEE SALES AniTa extract | `.cursor/skills/extract-seesales/SKILL.md` |
| Accutest TAT by service group | `.cursor/skills/extract-tat-by-group/SKILL.md` |
| Outlook datadrop forward rule | `.cursor/skills/outlook-datadrop-rule/SKILL.md` |

## Finish

1. Confirm the one rule file: `Get-ChildItem -Recurse .cursor/rules`
   must be a single `workspace.mdc`.
2. Confirm no leftover `{{PLACEHOLDER}}` in written files.
3. Tell the user, in plain language:
   - which folder is now the agent workspace
   - that they should start a **new** Cursor chat in that repo so
     skills and rules load
   - LIMS extracts still need AniTa + VPN + `ANITA_PASSWORD`
   - what you created, and that `CONTEXT/` is theirs to grow

Do not commit unless they ask. If they want this library updated,
commit in `cursor-skills`, not in their app repo, unless they asked
to save the new rules there.

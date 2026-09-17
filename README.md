# SGS Agent Skills

Shared [Cursor](https://cursor.com) Agent skills and workspace setup for SGS NAM EHS.

Repo: https://github.com/logan-bishop-sgs/sgs-agent-skills

This repository is **public** so any SGS colleague with the link can open it. Do not commit secrets, passwords, tokens, `.trc`, or `anita.wcf`.

## Help me get set up

In Cursor, clone this repo (or open it if you already have it), then say:

> help me get set up

and give the path to **your working repo** (dashboard, V3, a new project — not this library).

The `setup-agent` skill will:

1. Copy LIMS skills into that repo's `.cursor/skills/`
2. Write **one** Cursor rule (`.cursor/rules/workspace.mdc`) personalized to you
3. Create `CONTEXT/INDEX.md`, `project-overview.md`, and `conventions.md`
4. Create `admin/plans/` (task tracker) and `admin/CONTEXT/subagents.md`

Start a **new chat** in the working repo after it finishes so Cursor loads the rules and skills.

You can also copy `skills/setup-agent` into an existing project's `.cursor/skills/` and say the same thing there.

## Skills in this repo

| Skill | When to use it |
|---|---|
| `setup-agent` | "help me get set up", create Cursor rules / CONTEXT |
| `extract-seesales` | Accutest SEE SALES from AniTa → email → SharePoint |
| `extract-tat-by-group` | Accutest Invoice Disk TAT by service group |
| `outlook-datadrop-rule` | Outlook forward to `us.ehs.datadrop@sgs.com` |

LIMS skills run on a Windows PC with AniTa, VPN, and `ANITA_PASSWORD` in the environment (never in git). They currently assume Logan's AniTa hosts; the scripts live under `.cursor/skills/` after setup copies them.

## Layout

```
skills/
  setup-agent/
  extract-seesales/
  extract-tat-by-group/
  outlook-datadrop-rule/
templates/          # filled in by setup-agent; do not copy by hand
```

## Add a skill

Open a pull request that adds `skills/<skill-name>/SKILL.md` (plus any scripts). Do not put secrets in `SKILL.md`.

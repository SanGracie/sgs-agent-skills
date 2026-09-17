# Conventions & gotchas agents keep re-learning

> Last verified: {{TODAY}}

Hard-won rules for `{{PRIMARY_APP}}`. Each section should be verified against code on the date
above. See [`INDEX.md`](INDEX.md) for which doc to read per task.

## Diagnosing a reported problem

Do not infer the cause from reading the handler. Confirm the symptom from
logs, health checks, and a recreate (or reconstruct it from the log at the
reported time) **before** opening feature code. Show the smoking gun, then
explain it.

## Where new work goes

{{WHERE_NEW_WORK_GOES}}

## Docs

- Point at code rather than copying lists that will drift.
- Update **this repo's** `CONTEXT/` in the same change that alters behavior.
- Append [`work-log.md`](work-log.md) every session.
- Do not edit GitHub `sgs-agent-skills` or `.cursor/library-notes/` to record work.

## Secrets and local env

Never commit `.env`, passwords, tokens, or credential files. Production secrets
live in the platform secret store, not in git. `.gitignore` must include `.env`,
`.env.*` (with `!.env.example`), `venv/`, `__pycache__/`, `*.trc`, `anita.wcf`.

Start from `.env.example`. Create `.env` on the machine.

| Key | What |
|---|---|
| `SGS_EMAIL` / `SGS_NAME` | This user's SGS identity. Microsoft password is SSO — not `.env`. |
| `ANITA_USER` / `ANITA_PASSWORD` / `ANITA_HOST` | Accutest LIMS. Password belongs in `.env`. |
| Commented keys | Future skills. Uncomment when needed; add the same name to `.env.example`. |

Leave password values blank in chat.

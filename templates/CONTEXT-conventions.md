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
- Update `CONTEXT/` in the same change that alters behavior. The task is not
  done until the matching doc exists or you explicitly say why none is needed.

## Secrets

Never commit `.env`, passwords, tokens, or credential files. Production secrets
live in the platform secret store, not in git.

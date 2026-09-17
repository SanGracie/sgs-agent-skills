# SGS NAM — who we are

> Last verified: 2026-09-17

Library-owned. Logan updates this in `sgs-agent-skills/author-notes/`.
Do not invent org chart, lab ownership, or reporting lines.

## Company

**SGS** is a global testing, inspection, and certification company.
This team's work is **NAM EHS** (North America Environmental, Health
and Safety laboratory network) — operations reporting, client service,
sales, GBS (global business services), and LIMS extracts from Accutest
AniTa into SharePoint / the EHS dashboard.

Internal email is `@sgs.com`. SharePoint is `sgs.sharepoint.com`.
Most app git remotes are **Azure DevOps** (`SGS-NAM-Dev`), not GitHub.
This skills library is the exception: it lives on GitHub so techs can
clone it without an ADO invite.

## Logan Bishop

- Data and Automation Engineer (promotion in progress), NAM EHS Management.
- Reports to the VP of Technical Services NAM.
- Designs and builds end-to-end (Python, FastAPI, Azure, Cursor agents).
- Owns ~30 automated reporting systems; partners with Operations, Sales,
  Client Service, and GBS.
- Values pragmatism over formality. Does not need architecture hand-holding.
- **Write docs for the techs, not just for agents.** They did not live
  through the refactors. A stale path costs a person a morning.

When an agent is on **Logan's** machine, treat him as the owner: commits,
deploys, secrets, and AniTa extracts that assume his Windows PC / VPN.

## The data technicians

All are titled "data technician"; the job is helping build `ehs_dashboard`
and the reporting systems around it.

| Person | Where | Focus |
|---|---|---|
| Carl | Manila | `Cloud-Late-Report-Automation-V3` (own git repo). Moving into front-end. |
| Karl | Manila | Same V3 ownership with Carl. Moving into front-end. |
| David | Bogota | GBS reports. Newer on the team. |
| Fourth tech | starting soon | TBD |

V3 produces daily late-report workbooks and Postgres ETL that the
dashboard reads **read-only**. A V3 outage looks like a dashboard bug;
the fix is in Carl/Karl's repo.

## How agents should treat people

- **Personalize** Developer Context in `.cursor/rules/workspace.mdc` to
  the person at the keyboard (name, role, team). That is not a replacement
  for this file.
- Do not talk down. Techs are builders, not ticket-clickers.
- Prefer solutions a small team can run. Easy to justify operationally.
- Timezones: Manila (GMT+8), Bogota (GMT-5), Logan often GMT+8 on this
  laptop, labs are US. Label timestamps.

## Labs (Accutest / NAM EHS, common names)

Wheat Ridge, Dayton, Orlando, Scott, Houston, Livonia, Scarborough, and
others as the dashboard registry grows. Labs in late/KPI reports are
**registry rows**, not per-lab code packages — that fact belongs in
`ehs_dashboard` CONTEXT, not here.

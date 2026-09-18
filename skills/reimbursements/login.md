# Workday sign-in (SGS)

## Address

- Tenant: `wd3.myworkday.com/sgs`
- Create expense report: `https://wd3.myworkday.com/sgs/d/task/2997$728.htmld`

Override the start page with `EXPENSE_URL` in `.env` if needed.

## Use Edge, not Cursor’s window

Cursor’s helper window **cannot** finish SGS sign-in. After the username it goes to `sso.sgs.net/adfs/ls/wia` and stays **blank/black**. Cookie copy into that window is blocked.

Always open Workday in real Edge:

```powershell
powershell -File .cursor/skills/reimbursements/scripts/Open-Workday-Edge.ps1
```

That script starts Edge with a debug port (`9222`) so the agent can keep using the same window.

Username is `EXPENSE_USERNAME` or `SGS_EMAIL` in `.env`. Do not store the Microsoft password. One-time codes: use once, do not store.

## Agent steps

1. Run the Edge helper. Attach to `http://127.0.0.1:9222` if you need to drive the page.
2. If already in Workday, continue the report.
3. If SGS Microsoft sign-in appears, fill the work email and continue. In Edge this should not go black.
4. If Workday asks **Should we remember this device?** tick **Remember this device** and **Submit**.
5. If a phone / extra check appears, stop and ask them to finish it.
6. If Workday dumped you on the home page, go to Create Expense Report again.

## Old pattern (do not use)

<details>
<summary>Cursor helper window</summary>
Blank/black after username. Do not retry that window for expenses.
</details>

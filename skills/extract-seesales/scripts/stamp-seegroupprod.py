"""Stamp location + group onto unstamped AniTa seegroupprod files.

AniTa emails and the .xls do not carry location or group. The extract walk
order is the source of truth. This script matches unstamped
``seesales-seegroupprod-loganb_*`` files in a Power Automate Updates folder
(oldest first) to ``-Groups`` / a ledger and renames them to:

  seesales-seegroupprod-{location}-{group}-{yyyy-MM}_{origstamp}.xls
  e.g. seesales-seegroupprod-wheatridge-MET-2026-09_20260914085444.xls

Dry-run by default. Pass --apply to rename. Confirm on SharePoint, not Inbox.

  python stamp-seegroupprod.py --location wheatridge --month 2026-09 --after 2026-09-14T08:53:00Z
  python stamp-seegroupprod.py --location wheatridge --month 2026-09 --after 2026-09-14T08:53:00Z --apply
  python stamp-seegroupprod.py --location wheatridge --relabel --apply
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

SCRIPT = Path(__file__).resolve()
REPO = SCRIPT.parents[4]
DASH = REPO / "ehs_dashboard"
sys.path.insert(0, str(DASH))

from dotenv import load_dotenv  # noqa: E402

load_dotenv(REPO / ".env")
load_dotenv(DASH / ".env")

from office365.sharepoint.files.file import File  # noqa: E402

from app.services.sharepoint import UPDATE_PATH, get_ctx  # noqa: E402

DEFAULT_GROUPS = "MET,GEN,MSS,MSU,GCS,SUB,MISC,GCU,FLD"
# Filename uses the lab name, not the short LIMS code (co is Wheat Ridge).
LOCATION_SLUG = {
    "wheatridge": "wheatridge",
    "wheat": "wheatridge",
    "wr": "wheatridge",
    "ridge": "wheatridge",
    "co": "wheatridge",
    "dayton": "dayton",
    "nj": "dayton",
    "orlando": "orlando",
    "fla": "orlando",
    "fl": "orlando",
    "scott": "scott",
    "la": "scott",
    "scott62": "scott",
    "houston": "houston",
    "tx": "houston",
    "scott64": "houston",
    "nam": "nam",
}
UNSTAMPED = re.compile(r"^seesales-seegroupprod-loganb_(\d{14})_[0-9a-f]+\.xls$", re.I)
STAMPED = re.compile(r"^seesales-seegroupprod-[a-z0-9]+-[a-z0-9]+-\d{4}-\d{2}_", re.I)
STAMPED_PARTS = re.compile(
    r"^seesales-seegroupprod-([a-z0-9]+)-([a-z0-9]+)-(\d{4}-\d{2})_(.+)$",
    re.I,
)


def _parse_after(raw: str | None) -> datetime | None:
    if not raw:
        return None
    text = raw.strip()
    if text.endswith("Z"):
        text = text[:-1] + "+00:00"
    dt = datetime.fromisoformat(text)
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt


def _mod_aware(mod: datetime | None) -> datetime:
    if mod is None:
        return datetime.min.replace(tzinfo=timezone.utc)
    if getattr(mod, "tzinfo", None) is None:
        return mod.replace(tzinfo=timezone.utc)
    return mod


def _groups(raw: str) -> list[str]:
    return [p.strip().upper() for p in raw.split(",") if p.strip()]


def _ledger_rows(path: Path) -> list[dict]:
    rows = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line:
            rows.append(json.loads(line))
    return rows


def main() -> int:
    parser = argparse.ArgumentParser(description="Rename unstamped seegroupprod files using walk order.")
    parser.add_argument("--location", required=True, help="Lab name stamped into the filename (wheatridge/dayton/...)")
    parser.add_argument("--month", help="YYYY-MM stamped into the filename (or use --ledger)")
    parser.add_argument("--groups", default=DEFAULT_GROUPS, help="Comma group codes in walk order")
    parser.add_argument("--ledger", help="JSONL from export-seesales-groups.ps1")
    parser.add_argument("--date", help="PA folder YYYY-MM-DD (default: today UTC)")
    parser.add_argument("--after", help="Only unstamped files modified at/after this UTC time")
    parser.add_argument("--before", help="Only unstamped files modified before this UTC time")
    parser.add_argument("--apply", action="store_true", help="Rename on SharePoint (default is dry-run)")
    parser.add_argument("--inspect", action="store_true", help="Print columns of the first unstamped file")
    parser.add_argument("--relabel", action="store_true", help="Rewrite LIMS-code location tokens (co) to the lab name")
    args = parser.parse_args()

    loc = LOCATION_SLUG.get(args.location.strip().lower(), args.location.strip().lower())
    if not re.fullmatch(r"[a-z0-9]{2,16}", loc):
        print("location must be a lab name/code (wheatridge, dayton, orlando, scott, houston)")
        return 2

    folder_date = args.date or datetime.now(timezone.utc).strftime("%Y-%m-%d")
    folder = f"{UPDATE_PATH}/{folder_date}"
    ctx = get_ctx()
    files = list(ctx.web.get_folder_by_server_relative_url(folder).files.get_all().execute_query())

    if args.relabel:
        ok = 0
        print(f"folder {folder}")
        print(f"relabel location token -> {loc}")
        for f in files:
            name = str(f.properties.get("Name") or "")
            m = STAMPED_PARTS.match(name)
            if not m:
                continue
            old_loc, group, month, rest = m.group(1).lower(), m.group(2), m.group(3), m.group(4)
            mapped = LOCATION_SLUG.get(old_loc, old_loc)
            if mapped != loc or old_loc == loc:
                continue
            new_name = f"seesales-seegroupprod-{loc}-{group}-{month}_{rest}"
            url = str(f.properties.get("ServerRelativeUrl") or f"{folder}/{name}")
            print(f"{name}  ->  {new_name}")
            if not args.apply:
                continue
            content = File.open_binary(ctx, url).content
            if not content:
                print("FAIL empty download", name)
                return 2
            dest = ctx.web.get_folder_by_server_relative_url(folder)
            dest.upload_file(new_name, content).execute_query()
            ctx.web.get_file_by_server_relative_url(url).delete_object().execute_query()
            ok += 1
            print(f"RENAMED {new_name}")
        if args.apply:
            print(f"OK relabeled {ok}")
        else:
            print("DRY_RUN pass --apply to rename")
        return 0

    if args.ledger:
        planned = [
            {
                "location": LOCATION_SLUG.get(str(r.get("location") or loc).lower(), str(r.get("location") or loc).lower()),
                "group": str(r["group"]).upper(),
                "month": str(r["month"]),
            }
            for r in _ledger_rows(Path(args.ledger))
        ]
    else:
        if not args.month or not re.fullmatch(r"20\d{2}-(0[1-9]|1[0-2])", args.month):
            print("month YYYY-MM is required unless --ledger is passed")
            return 2
        planned = [{"location": loc, "group": g, "month": args.month} for g in _groups(args.groups)]

    after = _parse_after(args.after)
    before = _parse_after(args.before)

    unstamped: list[tuple[datetime, str, str]] = []
    for f in files:
        name = str(f.properties.get("Name") or "")
        if not UNSTAMPED.match(name):
            continue
        mod = _mod_aware(f.properties.get("TimeLastModified"))
        if after is not None and mod < after:
            continue
        if before is not None and mod >= before:
            continue
        url = str(f.properties.get("ServerRelativeUrl") or f"{folder}/{name}")
        unstamped.append((mod, name, url))
    unstamped.sort(key=lambda row: (row[0], row[1]))

    print(f"folder {folder}")
    print(f"unstamped {len(unstamped)} planned {len(planned)}")
    if args.inspect and unstamped:
        content = File.open_binary(ctx, unstamped[0][2]).content
        print(f"inspect {unstamped[0][1]} bytes={len(content)}")
        try:
            import pandas as pd

            df = pd.read_excel(content, header=None)
            print("xls_shape", df.shape)
            print(df.head(8).to_string())
        except Exception as exc:
            print("inspect_read_failed", type(exc).__name__, exc)

    if len(unstamped) != len(planned):
        print(f"SHORT/EXTRA unstamped={len(unstamped)} planned={len(planned)} - will not apply")
        for i, (mod, name, _) in enumerate(unstamped):
            plan = planned[i] if i < len(planned) else None
            print(f"  {mod}  {name}  -> {plan}")
        return 2 if args.apply else 0

    ok = 0
    for (mod, name, url), plan in zip(unstamped, planned):
        stamp = UNSTAMPED.match(name).group(1)
        new_name = (
            f"seesales-seegroupprod-{plan['location']}-{plan['group']}-{plan['month']}_{stamp}.xls"
        )
        print(f"{mod}  {name}  ->  {new_name}")
        if not args.apply:
            continue
        if STAMPED.match(new_name) is None:
            print("REFUSE bad new name", new_name)
            return 2
        content = File.open_binary(ctx, url).content
        if not content:
            print("FAIL empty download", name)
            return 2
        dest = ctx.web.get_folder_by_server_relative_url(folder)
        dest.upload_file(new_name, content).execute_query()
        ctx.web.get_file_by_server_relative_url(url).delete_object().execute_query()
        ok += 1
        print(f"RENAMED {new_name}")

    if args.apply:
        print(f"OK renamed {ok}")
    else:
        print("DRY_RUN pass --apply to rename")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

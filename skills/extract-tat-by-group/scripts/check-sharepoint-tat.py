"""List AniTa TAT-by-group drops in a Power Automate Updates folder.

Run from anywhere. Loads repo-root .env plus ehs_dashboard/.env.
Confirm here, not Outlook Inbox.

  python check-sharepoint-tat.py
  python check-sharepoint-tat.py --date 2026-09-16 --range 01-sep-26_15-sep-26 --expect 60
"""
from __future__ import annotations

import argparse
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

from app.services.sharepoint import UPDATE_PATH, get_ctx  # noqa: E402

LOCS = ("co", "nj", "fla", "la", "tx")
GROUPS = ("fld", "gca", "gcs", "gcv", "gen", "lcms", "met", "misc", "msa", "mss", "msv", "sub")


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


def _group_slug(name: str) -> tuple[str, str] | None:
    low = name.lower()
    for loc in LOCS:
        prefix = f"{loc}-tat-"
        if low.startswith(prefix):
            rest = low[len(prefix) :]
            grp = rest.split("-", 1)[0]
            return loc, grp
    return None


def main() -> int:
    parser = argparse.ArgumentParser(description="List TAT-by-group files in a PA Updates folder.")
    parser.add_argument("--date", help="Folder date YYYY-MM-DD (default: today UTC)")
    parser.add_argument("--expect", type=int, default=0, help="Required matching file count")
    parser.add_argument("--after", help="Only count files modified at/after this UTC time")
    parser.add_argument(
        "--range",
        default="",
        help="Require this date-range token in the name (e.g. 01-sep-26_15-sep-26)",
    )
    args = parser.parse_args()

    folder_date = args.date or datetime.now(timezone.utc).strftime("%Y-%m-%d")
    after = _parse_after(args.after)
    token = (args.range or "").strip().lower()
    folder = f"{UPDATE_PATH}/{folder_date}"
    ctx = get_ctx()
    files = list(ctx.web.get_folder_by_server_relative_url(folder).files.get_all().execute_query())

    hits: list[tuple[datetime | None, str, object, str]] = []
    found: dict[str, set[str]] = {loc: set() for loc in LOCS}
    for f in files:
        name = str(f.properties.get("Name") or "")
        low = name.lower()
        if "-tat-" not in low:
            continue
        parsed = _group_slug(name)
        if parsed is None:
            continue
        loc, grp = parsed
        mark = "KEEP"
        if token and token not in low:
            mark = "other-range"
        elif "15-sep-26_15-sep-26" in low:
            mark = "oneday"
        mod = f.properties.get("TimeLastModified")
        hits.append((mod, name, f.properties.get("Length"), mark))
        if mark == "KEEP":
            found[loc].add(grp)

    hits.sort(key=lambda row: (row[0] or datetime.min.replace(tzinfo=timezone.utc), row[1]))

    counted: list[str] = []
    for mod, name, length, mark in hits:
        keep = mark == "KEEP"
        if after is not None and mod is not None:
            mod_aware = mod if getattr(mod, "tzinfo", None) else mod.replace(tzinfo=timezone.utc)
            keep = keep and mod_aware >= after
        print(f"{mod}  {name}  {length}  {mark if keep or mark != 'KEEP' else 'old'}")
        if keep:
            counted.append(name)

    print(f"folder {folder}")
    print(f"tat_total {len(hits)}")
    print(f"tat_counted {len(counted)}")
    for loc in LOCS:
        miss = [g for g in GROUPS if g not in found[loc]]
        print(f"{loc} {len(found[loc])}/12 missing={miss}")
    if args.expect:
        if len(counted) >= args.expect:
            print(f"OK expect>={args.expect}")
            return 0
        print(f"SHORT counted={len(counted)} expect={args.expect} (Power Automate can lag a few minutes)")
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

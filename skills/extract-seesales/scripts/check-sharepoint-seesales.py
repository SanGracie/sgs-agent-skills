"""List AniTa loganb SEE SALES drops in today's Power Automate folder.

Run from anywhere. Loads repo-root .env plus ehs_dashboard/.env.
Confirm here, not Outlook Inbox.

  python check-sharepoint-seesales.py
  python check-sharepoint-seesales.py --date 2026-09-14 --expect 9
  python check-sharepoint-seesales.py --after 2026-09-14T07:00:00Z
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


def main() -> int:
    parser = argparse.ArgumentParser(description="List loganb SEE SALES files in a PA Updates folder.")
    parser.add_argument("--date", help="Folder date YYYY-MM-DD (default: today UTC)")
    parser.add_argument("--expect", type=int, default=0, help="Required new loganb file count")
    parser.add_argument("--after", help="Only count files modified at/after this UTC time")
    parser.add_argument(
        "--kind",
        choices=("all", "account", "group"),
        default="all",
        help="all loganb seesales* / account seesales-seesales- / group seesales-seegroupprod-",
    )
    args = parser.parse_args()

    folder_date = args.date or datetime.now(timezone.utc).strftime("%Y-%m-%d")
    after = _parse_after(args.after)
    folder = f"{UPDATE_PATH}/{folder_date}"
    ctx = get_ctx()
    files = list(ctx.web.get_folder_by_server_relative_url(folder).files.get_all().execute_query())

    hits: list[tuple[datetime | None, str, object]] = []
    for f in files:
        name = str(f.properties.get("Name") or "")
        low = name.lower()
        if args.kind == "account":
            if "loganb" not in low or "seesales-seesales-" not in low:
                continue
        elif args.kind == "group":
            if "seesales-seegroupprod-" not in low:
                continue
        elif "loganb" not in low or "seesale" not in low:
            continue
        mod = f.properties.get("TimeLastModified")
        hits.append((mod, name, f.properties.get("Length")))
    hits.sort(key=lambda row: (row[0] or datetime.min.replace(tzinfo=timezone.utc), row[1]))

    counted = []
    for mod, name, length in hits:
        keep = True
        if after is not None and mod is not None:
            mod_aware = mod if getattr(mod, "tzinfo", None) else mod.replace(tzinfo=timezone.utc)
            keep = mod_aware >= after
        mark = "KEEP" if keep else "old"
        print(f"{mod}  {name}  {length}  {mark}")
        if keep:
            counted.append(name)

    print(f"folder {folder}")
    print(f"loganb_total {len(hits)}")
    print(f"loganb_counted {len(counted)}")
    if args.expect:
        if len(counted) >= args.expect:
            print(f"OK expect>={args.expect}")
            return 0
        print(f"SHORT counted={len(counted)} expect={args.expect} (Power Automate can lag a few minutes)")
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

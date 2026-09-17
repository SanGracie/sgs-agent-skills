"""Classify an AniTa canvas snap without an agent watching.

Prints one line: CLASS=text|form|empty KEYS=password,remove,iforms,menu,seesales,oneofone
Used by login-seesales.ps1. Invert is written next to the source png.
"""
from __future__ import annotations

import os
import sys

from PIL import Image, ImageOps

KEYS = (
    ("password", ("password", "enter password")),
    ("remove", ("remove?", "if remove", "currently exist")),
    ("iforms", ("iforms", "please log", "enter user", "log on")),
    ("menu", ("main menu", "hotkey", "hot key")),
    ("seesales", ("see sales", "seesales", "september", "month of")),
    ("invoicedisk", ("invoice disc", "invoice disk", "disc generation", "billing date", "disc format")),
    ("future", ("in the future", "invoice date is in the future")),
    ("committed", ("transaction complete", "posted and committed")),
    ("needaccount", ("must select an account", "select an account")),
    ("invaliduser", ("invalid username", "missing or invalid")),
    ("oneofone", ("1 of 1", "1of1")),
)


def _load_rgb(path: str) -> Image.Image:
    im = Image.open(path)
    if im.mode == "RGBA":
        rgb = Image.new("RGB", im.size, (0, 0, 0))
        rgb.paste(im, mask=im.split()[-1])
        return rgb
    return im.convert("RGB")


def classify(rgb: Image.Image) -> str:
    px = list(rgb.getdata())
    n = len(px)
    if n < 100:
        return "empty"
    mid = sum(1 for r, g, b in px if 70 <= max(r, g, b) <= 190)
    bright = sum(1 for r, g, b in px if max(r, g, b) > 200)
    white = sum(1 for r, g, b in px if min(r, g, b) > 230)
    olive = sum(1 for r, g, b in px if 140 < r < 230 and 140 < g < 210 and b < 130)
    # IFORMS Log On is a dark-blue field screen (little white, no splash).
    # Main menu has the olive ACCULIMS box. Invoice Disk has a white dialog.
    if olive / n > 0.02:
        return "form"
    if white / n < 0.03 and mid / n > 0.02:
        return "logon"
    if mid / n > 0.08:
        return "form"
    if bright < 80:
        return "empty"
    return "text"


def keywords(rgb: Image.Image) -> list[str]:
    inv = ImageOps.invert(ImageOps.autocontrast(rgb.convert("L")))
    # Cheap: sample a downscaled string of ink vs paper is not OCR.
    # Optional tesseract if the operator installed it later.
    text = ""
    try:
        import pytesseract  # type: ignore

        text = pytesseract.image_to_string(inv) or ""
    except Exception:
        text = ""
    blob = " ".join(text.lower().split())
    found = []
    for name, needles in KEYS:
        if any(n in blob for n in needles):
            found.append(name)
    return found


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: read-anita-screen.py <snap.png>", file=sys.stderr)
        return 2
    cap = os.path.join(os.environ["LOCALAPPDATA"], "Temp", "anita-capture")
    name = sys.argv[1]
    path = name if os.path.isabs(name) else os.path.join(cap, name)
    canvas = os.path.join(cap, os.path.splitext(os.path.basename(path))[0] + "-canvas.png")
    src = canvas if os.path.isfile(canvas) else path
    rgb = _load_rgb(src)
    kind = classify(rgb)
    keys = keywords(rgb)
    inv_path = os.path.join(cap, os.path.splitext(os.path.basename(src))[0] + "-inv.png")
    ImageOps.invert(rgb.convert("L")).save(inv_path)
    print(f"CLASS={kind} KEYS={','.join(keys) if keys else '-'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

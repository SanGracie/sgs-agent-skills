"""Invert an anita-capture snap so dark-blue canvas text is readable."""
import os
import sys
from PIL import Image, ImageOps

name = sys.argv[1]
cap = os.path.join(os.environ["LOCALAPPDATA"], "Temp", "anita-capture")
stem = os.path.splitext(name)[0]
for candidate in (name, stem + "-canvas.png"):
    path = os.path.join(cap, candidate)
    if not os.path.isfile(path):
        continue
    im = Image.open(path)
    if im.mode == "RGBA":
        rgb = Image.new("RGB", im.size, (0, 0, 0))
        rgb.paste(im, mask=im.split()[-1])
    else:
        rgb = im.convert("RGB")
    out = os.path.join(cap, stem + "-inv.png") if candidate == name else os.path.join(cap, stem + "-canvas-inv.png")
    ImageOps.invert(rgb.convert("L")).save(out)
    print("invert", os.path.basename(out), rgb.size)

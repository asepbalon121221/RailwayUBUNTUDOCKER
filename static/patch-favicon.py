#!/usr/bin/env python3
from pathlib import Path
import shutil
import subprocess

root = Path(subprocess.check_output(["npm", "root", "-g"], text=True).strip()) / "9router"
svg = Path("/usr/local/share/xd/favicon.svg")
ico = Path("/usr/local/share/xd/favicon.ico")
n = 0
for p in root.rglob("*"):
    if "node_modules" in p.parts:
        continue
    if p.is_dir() and p.name == "public":
        shutil.copyfile(svg, p / "favicon.svg")
        shutil.copyfile(ico, p / "favicon.ico")
        n += 1
        icons = p / "icons"
        if icons.is_dir():
            shutil.copyfile(svg, icons / "icon-192.svg")
            shutil.copyfile(svg, icons / "icon-512.svg")
    elif p.is_file() and p.name == "favicon.ico":
        shutil.copyfile(ico, p)
        n += 1
    elif p.is_file() and p.name in ("favicon.svg", "icon-192.svg", "icon-512.svg"):
        shutil.copyfile(svg, p)
        n += 1
print("xd favicon patched", n)

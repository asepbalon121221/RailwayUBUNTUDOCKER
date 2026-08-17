#!/usr/bin/env python3
from pathlib import Path
import shutil
import subprocess
import sys

svg = Path("/usr/local/share/xd/favicon.svg")
ico = Path("/usr/local/share/xd/favicon.ico")


def npm_cmd(*args):
    return subprocess.check_output(["npm", *args], text=True).strip()


def package_dirs():
    found = []
    try:
        for line in npm_cmd("list", "-g", "9router", "--parseable").splitlines():
            p = Path(line.strip())
            if p.is_dir():
                found.append(p)
    except subprocess.CalledProcessError:
        pass
    try:
        p = Path(npm_cmd("root", "-g")) / "9router"
        if p.is_dir():
            found.append(p)
    except subprocess.CalledProcessError:
        pass
    which = shutil.which("9router")
    if which:
        bin_dir = Path(which).resolve().parent
        for rel in ("../lib/node_modules/9router", "node_modules/9router"):
            p = (bin_dir / rel).resolve()
            if p.is_dir():
                found.append(p)
    for p in (
        Path("/usr/lib/node_modules/9router"),
        Path("/usr/local/lib/node_modules/9router"),
    ):
        if p.is_dir():
            found.append(p)
    uniq = []
    seen = set()
    for p in found:
        if p not in seen:
            uniq.append(p)
            seen.add(p)
    return uniq


n = 0
pkgs = package_dirs()
print("9router pkgs:", *[str(p) for p in pkgs] or ["NONE"])
for pkg in pkgs:
    for p in pkg.rglob("*"):
        if "node_modules" in p.parts[len(pkg.parts) :]:
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
    for rel in ("app/public", "public", "app/.next/standalone/public"):
        dest = pkg / rel
        dest.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(svg, dest / "favicon.svg")
        shutil.copyfile(ico, dest / "favicon.ico")
        n += 1

print("xd favicon patched", n)
if n == 0:
    sys.exit("9router public files not found")

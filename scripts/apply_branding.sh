#!/usr/bin/env bash
# Creates browser/branding/firedoge inside src/ (only for the firedoge branding).
# Copies the CURRENT nightly branding, then swaps in the old FireDoge image files
# wherever a file with the same relative path exists (so tree changes can't break it).
set -euo pipefail
[ "${1:-}" = "firedoge" ] || exit 0
python3 - <<'PY'
import os, shutil, sys
OLD, SRC = "branding/firedoge", "src/browser/branding"
NEW = os.path.join(SRC, "firedoge")
shutil.copytree(os.path.join(SRC, "nightly"), NEW)
EXT = {".png", ".ico", ".svg", ".icns", ".bmp", ".gif", ".jpg"}
n = 0
for root, _, files in os.walk(OLD):
    for f in files:
        if os.path.splitext(f)[1].lower() not in EXT:
            continue
        dst = os.path.join(NEW, os.path.relpath(os.path.join(root, f), OLD))
        if os.path.exists(dst):
            shutil.copyfile(os.path.join(root, f), dst)
            n += 1
print(f"firedoge: replaced {n} image file(s)")
sys.exit(0 if n else 1)
PY

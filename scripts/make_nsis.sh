#!/usr/bin/env bash
# usage: make_nsis.sh <package.zip> <flavor> <platform> <version> <short> <outdir>
set -euo pipefail
zip="$1"; flavor="$2"; platform="$3"; version="$4"; short="$5"; out="$6"
here="$(cd "$(dirname "$0")" && pwd)"
work="$(mktemp -d)"
unzip -q "$zip" -d "$work"
src="$work/firefox"; [ -d "$src" ] || src="$work"
[ -f "$src/firefox.exe" ] || { echo "firefox.exe not found in $zip"; exit 1; }
mkdir -p "$out"; out="$(cd "$out" && pwd)"
name="NightlyFox-${flavor}-${platform}-${short}-setup.exe"
makensis -V2 -DFLAVOR="$flavor" -DVERSION="$version" -DSRCDIR="$src" -DOUTFILE="$out/$name" "$here/installer.nsi"
(cd "$out" && sha256sum "$name" > "$name.sha256")
ls -lh "$out/$name"

#!/usr/bin/env bash
# Renders a terminal-style status image and force-pushes it to branch status-<VARIANT>.
# Never fails the build.
here="$(cd "$(dirname "$0")" && pwd)"
state="${1:-compiling}"
tmp="$(mktemp -d)"
python3 "$here/console.py" --state "$state" --variant "${VARIANT:-?}" --commit "${SHORT:-}" \
  --log "${LOG:-/dev/null}" --start "${START_EPOCH:-0}" --out "$tmp/console.svg" || exit 0
cd "$tmp" || exit 0
git init -q -b "status-${VARIANT}" \
  && git add console.svg \
  && git -c user.name=nightlyfox-bot -c user.email=nightlyfox-bot@users.noreply.github.com commit -q -m "status: $state" \
  && git push -q -f "https://x-access-token:${GH_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" "status-${VARIANT}" \
  || true
exit 0

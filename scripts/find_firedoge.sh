#!/usr/bin/env bash
# Finds the LAST upstream commit that still had the FireDoge Nightly branding and copies
# browser/branding/nightly from it into ./branding/firedoge .
#  1. find the commit that added it (message mentions doge) or use $ADD_COMMIT
#  2. note one image that commit changed, then walk forward until that image changes again
#  3. the parent of that change is the last commit with the doge branding
set -euo pipefail
ROOT="$(pwd)"; WORK="$(mktemp -d)"; P=browser/branding/nightly
git clone -q --filter=blob:none --no-checkout https://github.com/mozilla/gecko-dev.git "$WORK/gd"
cd "$WORK/gd"
add="${ADD_COMMIT:-}"
if [ -z "$add" ]; then
  echo "== commits mentioning doge that touch $P"
  git log --format='%h %ad %s' --date=short -i -E --grep='doge|firedoge' -- "$P" | head -20 || true
  add=$(git log --format=%H -i -E --grep='doge|firedoge' -- "$P" | tail -1 || true)
fi
[ -n "$add" ] || { echo "Could not auto-detect the commit. Re-run with the add_commit input."; exit 1; }
echo "== add commit: $(git log -1 --format='%h %ad %s' --date=short "$add")"
probe=$(git diff-tree --no-commit-id --name-only -r "$add" -- "$P" | grep -E '\.(png|svg|ico)$' | head -1 || true)
[ -n "$probe" ] || { echo "That commit changed no image under $P."; exit 1; }
want=$(git rev-parse "$add:$probe")
latest=""
for c in $(git log --reverse --format=%H "$add..HEAD" -- "$probe"); do
  if [ "$(git rev-parse "$c:$probe" 2>/dev/null || echo gone)" != "$want" ]; then
    latest=$(git rev-parse "$c^"); break
  fi
done
[ -n "$latest" ] || latest=$(git rev-parse HEAD)
echo "== last commit with the doge images: $(git log -1 --format='%h %ad %s' --date=short "$latest")"
git archive "$latest" "$P" | tar -x -C "$WORK"
rm -rf "$ROOT/branding/firedoge"; mkdir -p "$ROOT/branding/firedoge"
cp -r "$WORK/$P/." "$ROOT/branding/firedoge/"
printf 'source: https://github.com/mozilla/gecko-dev/tree/%s/%s\nadded-by: %s\nprobe-file: %s\n' "$latest" "$P" "$add" "$probe" > "$ROOT/branding/firedoge/SOURCE.txt"
echo "== copied $(find "$ROOT/branding/firedoge" -type f | wc -l) files"

#!/usr/bin/env bash
# Finds the LAST upstream commit that still had the FireDoge Nightly branding and copies
# browser/branding/nightly from it into ./branding/firedoge .
# Upstream removed it in "Bug 1695087: Revert to regular nightly branding. So long firedoge...",
# so the last commit WITH the doge images is the PARENT of that revert.
# Inputs (all optional): REMOVAL_COMMIT = the revert commit, ADD_COMMIT = the commit that added it.
set -euo pipefail
ROOT="$(pwd)"; WORK="$(mktemp -d)"; P=browser/branding/nightly
git clone -q --filter=blob:none --no-checkout https://github.com/mozilla/gecko-dev.git "$WORK/gd"
cd "$WORK/gd"
rm_c="${REMOVAL_COMMIT:-}"; add="${ADD_COMMIT:-}"; latest=""

if [ -z "$rm_c" ] && [ -z "$add" ]; then
  echo "== commits mentioning doge that touch $P"
  git log --format='%h %ad %s' --date=short -i -E --grep='doge|firedoge' -- "$P" | head -20 || true
  c=$(git log --format=%H -i -E --grep='doge|firedoge' -- "$P" | tail -1 || true)
  [ -n "$c" ] || { echo "Nothing found. Re-run with removal_commit or add_commit."; exit 1; }
  if git log -1 --format=%s "$c" | grep -qiE 'revert|back(ed)? ?out|so long|remove|restore'; then rm_c="$c"; else add="$c"; fi
fi

if [ -n "$rm_c" ]; then
  echo "== removal commit: $(git log -1 --format='%h %ad %s' --date=short "$rm_c")"
  echo "== images it changed (these were doge before it):"
  git diff-tree --no-commit-id --name-status -r "$rm_c" -- "$P" | head -30
  latest=$(git rev-parse "$rm_c^")
else
  echo "== add commit: $(git log -1 --format='%h %ad %s' --date=short "$add")"
  probe=$(git diff-tree --no-commit-id --name-only -r "$add" -- "$P" | grep -E '\.(png|svg|ico)$' | head -1 || true)
  [ -n "$probe" ] || { echo "That commit changed no image under $P."; exit 1; }
  want=$(git rev-parse "$add:$probe")
  for c in $(git log --reverse --format=%H "$add..HEAD" -- "$probe"); do
    if [ "$(git rev-parse "$c:$probe" 2>/dev/null || echo gone)" != "$want" ]; then
      latest=$(git rev-parse "$c^"); break
    fi
  done
  [ -n "$latest" ] || { echo "Doge images never changed again; unexpected."; exit 1; }
fi

echo "== last commit with the doge images: $(git log -1 --format='%h %ad %s' --date=short "$latest")"
git archive "$latest" "$P" | tar -x -C "$WORK"
rm -rf "$ROOT/branding/firedoge"; mkdir -p "$ROOT/branding/firedoge"
cp -r "$WORK/$P/." "$ROOT/branding/firedoge/"
printf 'source: https://github.com/mozilla/gecko-dev/tree/%s/%s\nremoval-commit: %s\nadd-commit: %s\n' "$latest" "$P" "$rm_c" "$add" > "$ROOT/branding/firedoge/SOURCE.txt"
echo "== copied $(find "$ROOT/branding/firedoge" -type f | wc -l) files"

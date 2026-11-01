#!/usr/bin/env bash
# usage: apply_onboarding.sh <on|off> <branding>
# Turns on Firefox's real first-run onboarding (about:welcome) by setting the branding pref
# startup.homepage_welcome_url. Default per branding: unofficial = none, nightly/aurora = a
# mozilla.org web page, official = about:welcome.
set -euo pipefail
[ "${1:-off}" = "on" ] || exit 0
f="src/browser/branding/$2/pref/firefox-branding.js"
[ -f "$f" ] || { echo "missing $f"; exit 1; }
sed -i 's|^pref("startup.homepage_welcome_url",.*);|pref("startup.homepage_welcome_url", "about:welcome");|' "$f"
grep -n 'homepage_welcome_url"' "$f"
grep -q 'homepage_welcome_url", "about:welcome"' "$f" || { echo "onboarding patch did not apply"; exit 1; }

#!/usr/bin/env bash
# usage: make_deb.sh <tarball> <flavor> <platform> <debarch amd64|arm64> <version> <short> <outdir>
set -euo pipefail
tarball="$1"; flavor="$2"; platform="$3"; debarch="$4"; version="$5"; short="$6"; out="$7"
pkg="nightlyfox-$flavor"
work="$(mktemp -d)"; root="$work/root"
mkdir -p "$root/opt" "$root/usr/bin" "$root/usr/share/applications" "$root/DEBIAN" "$out"
out="$(cd "$out" && pwd)"
tar -xf "$tarball" -C "$work"
mv "$work/firefox" "$root/opt/$pkg"
ln -s "/opt/$pkg/firefox" "$root/usr/bin/$pkg"
# updates come from new .deb files, not from the in-app updater (/opt isn't writable anyway)
mkdir -p "$root/opt/$pkg/distribution"
printf '{"policies":{"DisableAppUpdate":true}}\n' > "$root/opt/$pkg/distribution/policies.json"
for n in 16 32 48 64 128; do
  i="$root/opt/$pkg/browser/chrome/icons/default/default$n.png"
  if [ -f "$i" ]; then
    mkdir -p "$root/usr/share/icons/hicolor/${n}x${n}/apps"
    cp "$i" "$root/usr/share/icons/hicolor/${n}x${n}/apps/$pkg.png"
  fi
done
cat > "$root/usr/share/applications/$pkg.desktop" <<DESK
[Desktop Entry]
Version=1.0
Type=Application
Name=NightlyFox ($flavor)
GenericName=Web Browser
Comment=Unofficial Firefox Nightly build
Exec=/opt/$pkg/firefox %u
Icon=$pkg
Terminal=false
StartupNotify=true
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;
DESK
size=$(du -sk "$root" | cut -f1)
cat > "$root/DEBIAN/control" <<CTRL
Package: $pkg
Version: ${version}.$(date -u +%Y%m%d%H%M)
Architecture: $debarch
Maintainer: NightlyFox <noreply@users.noreply.github.com>
Installed-Size: $size
Section: web
Priority: optional
Homepage: https://github.com/${GITHUB_REPOSITORY:-foobtech/NightlyFox}
Depends: libasound2t64 | libasound2, libatk1.0-0t64 | libatk1.0-0, libc6, libcairo-gobject2, libcairo2, libdbus-1-3, libfontconfig1, libfreetype6, libgcc-s1, libgdk-pixbuf-2.0-0, libglib2.0-0t64 | libglib2.0-0, libgtk-3-0t64 | libgtk-3-0, libharfbuzz0b, libpango-1.0-0, libpangocairo-1.0-0, libpangoft2-1.0-0, libstdc++6, libx11-6, libx11-xcb1, libxcb-shm0, libxcb1, libxcomposite1, libxcursor1, libxdamage1, libxext6, libxfixes3, libxi6, libxrandr2, libxrender1, libxtst6
Description: NightlyFox ($flavor), an unofficial Firefox Nightly build
 Compiled from Mozilla's Nightly source in GitHub Actions. Not made or endorsed by Mozilla.
CTRL
find "$root" -type d -exec chmod 755 {} +
name="NightlyFox-${flavor}-${platform}-${short}.deb"
dpkg-deb --root-owner-group -Zxz --build "$root" "$out/$name"
(cd "$out" && sha256sum "$name" > "$name.sha256")
ls -lh "$out/$name"

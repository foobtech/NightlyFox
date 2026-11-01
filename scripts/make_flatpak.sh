#!/usr/bin/env bash
# usage: make_flatpak.sh <tarball> <flavor> <platform> <flatpak-arch x86_64|aarch64> <short> <outdir>
# Same recipe Mozilla uses: copy the Firefox base app, add the Firefox tree, build-finish, build-export, bundle.
set -euo pipefail
tarball="$(realpath "$1")"; flavor="$2"; platform="$3"; farch="$4"; short="$5"; out="$6"
mkdir -p "$out"; out="$(cd "$out" && pwd)"
FD=25.08; BASE=org.mozilla.firefox.BaseApp; BRANCH=nightly
camel=$(python3 -c "import sys,re;print(''.join(p.capitalize() for p in re.split(r'[^A-Za-z0-9]+',sys.argv[1]) if p))" "$flavor")
owner="$(echo "${GITHUB_REPOSITORY_OWNER:-foobtech}" | tr 'A-Z' 'a-z' | tr -c 'a-z0-9\n' '_')"
app="io.github.${owner}.NightlyFox.${camel}"
echo "app id: $app"

flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install --user -y flathub "$BASE/$farch/$FD" --no-deps

work="$(mktemp -d)"; cd "$work"
mkdir -p build/files
cp -a "$HOME/.local/share/flatpak/app/$BASE/$farch/$FD/active/files/." build/files/
mkdir -p build/files/lib build/files/bin
tar -xf "$tarball" -C build/files/lib
mkdir -p build/files/lib/firefox/distribution
printf '{"policies":{"DisableAppUpdate":true}}\n' > build/files/lib/firefox/distribution/policies.json
printf '#!/bin/sh\nexec /app/lib/firefox/firefox "$@"\n' > build/files/bin/firefox; chmod +x build/files/bin/firefox

cat > build/metadata <<META
[Application]
name=$app
runtime=org.freedesktop.Platform/$farch/$FD
sdk=org.freedesktop.Sdk/$farch/$FD
base=app/$BASE/$farch/$FD
command=firefox
META

for n in 16 32 48 64 128; do
  i="build/files/lib/firefox/browser/chrome/icons/default/default$n.png"
  if [ -f "$i" ]; then
    mkdir -p "build/files/share/icons/hicolor/${n}x${n}/apps"
    cp "$i" "build/files/share/icons/hicolor/${n}x${n}/apps/$app.png"
  fi
done
mkdir -p build/files/share/applications
cat > "build/files/share/applications/$app.desktop" <<DESK
[Desktop Entry]
Version=1.0
Type=Application
Name=NightlyFox ($flavor)
GenericName=Web Browser
Comment=Unofficial Firefox Nightly build
Exec=firefox %u
Icon=$app
Terminal=false
StartupNotify=true
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;
DESK

flatpak build-finish build --allow=devel --share=ipc --share=network --socket=pulseaudio --socket=wayland \
  --socket=fallback-x11 --socket=pcsc --socket=cups --persist=.mozilla --env=DICPATH=/usr/share/hunspell \
  --filesystem=xdg-config/gtk-3.0:ro --filesystem=xdg-download:rw --device=all \
  --talk-name=org.freedesktop.FileManager1 --system-talk-name=org.freedesktop.NetworkManager \
  --talk-name=org.a11y.Bus --talk-name=org.gtk.vfs.* "--own-name=$app.*" --command=firefox
flatpak build-export --arch="$farch" --disable-sandbox repo build "$BRANCH"
name="NightlyFox-${flavor}-${platform}-${short}.flatpak"
flatpak build-bundle --arch="$farch" --runtime-repo=https://dl.flathub.org/repo/flathub.flatpakrepo repo "$out/$name" "$app" "$BRANCH"
(cd "$out" && sha256sum "$name" > "$name.sha256")
ls -lh "$out/$name"

# NightlyFox

Unofficial builds of Firefox Nightly, compiled in GitHub Actions straight from
upstream's `main` branch (formerly mozilla-central), for people who'd rather not
download from Mozilla.

[![Build Nightly](https://github.com/foobtech/NightlyFox/actions/workflows/nightly.yml/badge.svg)](https://github.com/foobtech/NightlyFox/actions/workflows/nightly.yml)

## Brandings
| Name | What it is |
|---|---|
| `unofficial` | Generic "unofficial" branding (the safe one to redistribute) |
| `nightly` | Firefox Nightly name + logo |
| `aurora` | Firefox Developer Edition name + logo |
| `official` | Release Firefox name + logo |
| `firedoge` | Joke: Nightly branding with the 2021 FireDoge images |

## Onboarding builds
Builds can also include Firefox's first-run onboarding (`about:welcome`). Those
files end in `-onboarding`, e.g. `NightlyFox-unofficial-onboarding-linux-x86_64-...`.
Without it, `unofficial` shows no welcome page, and `nightly`/`aurora` open a
mozilla.org page. Onboarding contacts Mozilla's servers.

## Platforms
Linux x86_64 and Linux aarch64. Windows x64 works but is off by default (no auto-update).
macOS and Android are planned.

A build runs once a day at 23:30 UTC and compiles the newest upstream commit at
that moment, for every enabled platform and branding. Each release lists the
upstream commits since the previous build and when compiling started, finished
and how long it took.

## Live build consoles
Updated every minute while a build is running. GitHub caches README images for
about 5 minutes, so what you see can lag by that much.

<details><summary><b>linux-x86_64</b></summary>

**unofficial**  
![unofficial linux-x86_64](https://raw.githubusercontent.com/foobtech/NightlyFox/status-unofficial-linux-x86_64/console.svg)

**nightly**  
![nightly linux-x86_64](https://raw.githubusercontent.com/foobtech/NightlyFox/status-nightly-linux-x86_64/console.svg)

**aurora**  
![aurora linux-x86_64](https://raw.githubusercontent.com/foobtech/NightlyFox/status-aurora-linux-x86_64/console.svg)

**official**  
![official linux-x86_64](https://raw.githubusercontent.com/foobtech/NightlyFox/status-official-linux-x86_64/console.svg)

**firedoge**  
![firedoge linux-x86_64](https://raw.githubusercontent.com/foobtech/NightlyFox/status-firedoge-linux-x86_64/console.svg)

</details>

<details><summary><b>linux-aarch64</b></summary>

**unofficial**  
![unofficial linux-aarch64](https://raw.githubusercontent.com/foobtech/NightlyFox/status-unofficial-linux-aarch64/console.svg)

**nightly**  
![nightly linux-aarch64](https://raw.githubusercontent.com/foobtech/NightlyFox/status-nightly-linux-aarch64/console.svg)

**aurora**  
![aurora linux-aarch64](https://raw.githubusercontent.com/foobtech/NightlyFox/status-aurora-linux-aarch64/console.svg)

**official**  
![official linux-aarch64](https://raw.githubusercontent.com/foobtech/NightlyFox/status-official-linux-aarch64/console.svg)

**firedoge**  
![firedoge linux-aarch64](https://raw.githubusercontent.com/foobtech/NightlyFox/status-firedoge-linux-aarch64/console.svg)

</details>

<details><summary><b>windows-x86_64</b> (experimental)</summary>

**unofficial**  
![unofficial windows-x86_64](https://raw.githubusercontent.com/foobtech/NightlyFox/status-unofficial-windows-x86_64/console.svg)

**nightly**  
![nightly windows-x86_64](https://raw.githubusercontent.com/foobtech/NightlyFox/status-nightly-windows-x86_64/console.svg)

**aurora**  
![aurora windows-x86_64](https://raw.githubusercontent.com/foobtech/NightlyFox/status-aurora-windows-x86_64/console.svg)

**official**  
![official windows-x86_64](https://raw.githubusercontent.com/foobtech/NightlyFox/status-official-windows-x86_64/console.svg)

**firedoge**  
![firedoge windows-x86_64](https://raw.githubusercontent.com/foobtech/NightlyFox/status-firedoge-windows-x86_64/console.svg)

</details>

## Downloading
Releases tab -> newest `nightly-...` release -> pick the file for your platform
and branding. Every file has a `.sha256` next to it.

**Linux**
- `.deb` (Debian, Ubuntu, Mint...): `sudo apt install ./NightlyFox-unofficial-linux-x86_64-<hash>.deb`
  then start it from your app menu or with `nightlyfox-unofficial`. New builds
  are new `.deb` files; install the newer one over the old.
- `.flatpak` (only when built with `packages=flatpak` or `all`):
  `flatpak install --user ./NightlyFox-unofficial-linux-x86_64-<hash>.flatpak`
- `.tar.xz` (any distro): `tar xf <file>` then `./firefox/firefox`

**Windows**
- `-setup.exe`: double-click. It installs just for you (no admin) and adds a
  Start menu entry and an uninstaller. Windows may show a SmartScreen warning
  because the file isn't signed: click "More info", then "Run anyway".
- `.zip`: extract and run `firefox.exe` (portable).

## Updating
The builds check this repo's releases for updates (Settings -> General ->
Firefox Updates). Update packages are unsigned for now.

## Trademark note
"Firefox", the Nightly logo, the Developer Edition logo and the release logo
belong to Mozilla. The `nightly`, `aurora` and `official` brandings use them.
Check Mozilla's trademark / distribution policy before publishing those. If in
doubt, set the repo variable `BRANDINGS` to `unofficial,firedoge` and rename
the project NightlyBuilder.

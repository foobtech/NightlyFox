# NightlyFox

Unofficial builds of Firefox Nightly, compiled in GitHub Actions straight from
upstream's `main` branch (formerly mozilla-central), for people who'd rather not
download from Mozilla.

[![Build Nightly](https://github.com/foobtech/NightlyFox/actions/workflows/nightly.yml/badge.svg)](https://github.com/foobtech/NightlyFox/actions/workflows/nightly.yml)

- **unbranded**: generic "unofficial" branding (safe to redistribute)
- **branded**: Firefox Nightly name/logo (see trademark note)

A build runs once a day at 23:30 UTC and compiles the newest upstream commit at
that moment, for both variants. Each release lists the upstream commits since
the previous build and when compiling started, finished and how long it took.

## Live build console
Refreshed every ~5 minutes while a build is running (GitHub caches images, so it
can lag a little). When idle it shows the result of the last build.

**unbranded**
![unbranded console](https://raw.githubusercontent.com/foobtech/NightlyFox/status-unbranded/console.svg)

**branded**
![branded console](https://raw.githubusercontent.com/foobtech/NightlyFox/status-branded/console.svg)

## Downloading
Releases tab -> newest `nightly-...` release -> grab the `.tar.xz`, then:

    tar xf NightlyFox-unbranded-linux-x86_64-<hash>.tar.xz
    ./firefox/firefox

## Updating
The builds check this repo's releases for updates (Settings -> General ->
Firefox Updates). Update packages are unsigned for now.

## Trademark note
"Firefox" and the Nightly logo belong to Mozilla. Check Mozilla's trademark /
distribution policy before shipping the branded variant. If in doubt, delete
`branded` from the matrix in `.github/workflows/nightly.yml` and rename the
project NightlyBuilder.

# CLAUDE.md

## What this repo is

A Doki Doki Literature Club login screen for SDDM: plain QML against the Theme API 2.0, Qt 6, no C++. Every wrong password runs a glitch and leaves a mark that accumulates. It ships prebuilt — the theme directory copies anywhere, and `install.sh` is for systems without Nix

`theme/theme.conf` is **generated** from `ddlc-palette` by `nix/theme-conf.nix` and committed with literal hex, so the theme installs without Nix. Regenerate with `nix run .#write-theme-conf`, never by hand

The seam in `rokokol/huix` is `nixos/services/desktop/sddm.nix`: it enables `ddlc.sddm` and nothing else

## Build / check

```sh
nix build .#sddm-ddlc-theme .#sayori-cursors
nix flake check          # theme.conf current, theme self-contained, cursors intact, module wiring, real-nixpkgs eval
nix run .#preview        # the greeter in a window; F8 fakes a wrong password
nix run .#write-theme-conf
./install.sh --prefix "$PWD/out" --no-configure
nix fmt -- --ci
```

There is no behaviour suite: the theme is QML the greeter runs, and nothing short of a greeter runs it. `nix run .#preview` is how it gets looked at

## Layout

```
theme/          Main.qml, theme.conf, metadata.desktop, components/, assets/ — copy it anywhere
cursors/        the prebuilt XCursor theme, its frames and the script that rebuilds one from the other
nix/            theme.nix, cursors.nix, module.nix, module-test.nix, nixos-eval.nix
```

QML file names are CamelCase because in QML the file name *is* the type name — the kebab-case rule stops at that door

## Changing a colour

It comes from `ddlc-palette`, never a literal here. Edit the mapping in `nix/theme-conf.nix`, run `nix run .#write-theme-conf`, commit both

## The module is checked twice

`nix/module-test.nix` evaluates it against option stubs; `nix/nixos-eval.nix` evaluates it inside a real `nixpkgs.lib.nixosSystem` and reads the generated `sddm.conf`. The second exists because a stubbed option accepts any value while the real one renders an INI and refuses what it cannot write. Keep both, and keep `want 'keys == [ … ]'` as the first assertion in each set — the field names are written twice, in Nix and in jq, with nothing tying them together

## CHANGELOG

Every user-visible change adds a bullet under `## [Unreleased]` in `CHANGELOG.md`. A release moves those bullets under a new version heading with the date, tags `v<x.y.z>` and cuts a `gh release` whose notes are that section. Dates belong in this file and nowhere else — the no-dates rule holds everywhere but here, because Keep a Changelog asks for them

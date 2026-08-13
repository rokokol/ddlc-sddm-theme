# Changelog

Kept in the shape of [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versioned by [semver](https://semver.org/spec/v2.0.0.html)

## [Unreleased]

## [1.0.0] - 2026-08-13

Split out of [rokokol/huix](https://github.com/rokokol/huix), where it was a theme directory next to the configuration that selected it

### Added

- the theme: plain QML against the SDDM Theme API 2.0, Qt 6, with the glitch that accumulates on every wrong password
- `theme.conf` generated from `ddlc-palette` and committed with literal hex, so the theme installs without Nix — `nix run .#write-theme-conf` rewrites it
- the Sayori cursor theme, prebuilt, with the script that rebuilds it from its frames
- `nixosModules.default` (`ddlc.sddm`), `overlays.default`, and `nix run .#preview` for the greeter in a window
- checks: `theme.conf` is current, the theme carries every file its QML names, the cursors are whole, and the module is evaluated both against option stubs and inside a real nixpkgs module set

# Changelog

Kept in the shape of [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versioned by [semver](https://semver.org/spec/v2.0.0.html)

## [Unreleased]

### Changed

- `install.sh` now exits 2, not 1, on a usage error — an unknown flag, a relative `--prefix`, an invalid `--component` value, or `--uninstall` combined with a configuration flag — and `--help` ends with the `Exit` sentence naming every code it can produce; a missing dependency in the preflight still exits 1

## [1.1.0] - 2026-09-01

### Changed

- `install.sh` stages both the prefix and `/etc` under `DESTDIR` and can install only the `theme` or `cursors` component for split packages
- `install.sh` reworked onto the [huix-standard](https://github.com/rokokol/huix-standard) grammar: `-h`/`-v` short flags, canonical `PREFIX` (absolute always), a preflight that installs nothing and prints exact per-distro guidance (SDDM is a session dependency — a warning, not a refusal), and the checkout-completeness and writability checks kept. Components stay additive, each converging its own files on a re-run — dropping `--no-configure` restores the SDDM config, adding it removes one, declaratively

### Added

- `VERSION` at the repo root as the one source of version: both packages read it (they used to say `1.0` while the tag said `v1.0.0` — exactly the drift this ends), `install.sh -v|--version` prints it, CI asserts the changelog heading matches
- `./install.sh --uninstall` removes an install by its manifest at `share/ddlc-sddm-theme/install-manifest` — `--uninstall --component cursors` takes one component out and keeps the rest, `/etc/sddm.conf.d/10-ddlc.conf` is owned by the theme component and leaves with it; installs made before the manifest existed fall back to the known layout for this one release
- tab completion for the installer, `source completions/install.sh.{bash,zsh}`, drift-checked against `install.sh` by `tests/check-completions.sh`
- `tests/installer.sh` — the installer's contract as a fast suite, also run by `nix flake check`; the theme itself keeps having no behaviour suite, `nix run .#preview` is how it gets looked at
- `tests/distro.sh` — the full preflight→guidance→install→uninstall cycle inside real `debian`, `ubuntu`, `arch` and `fedora` containers with a deliberately Qt-less smoke (files plus the INI shape SDDM parses), and four per-distro CI badges (push, weekly cron, never pull requests)

### Documentation

- link the shared `ddlc-palette` from the README badges

## [1.0.0] - 2026-08-13

Split out of [rokokol/huix](https://github.com/rokokol/huix), where it was a theme directory next to the configuration that selected it

### Added

- the theme: plain QML against the SDDM Theme API 2.0, Qt 6, with the glitch that accumulates on every wrong password
- `theme.conf` generated from `ddlc-palette` and committed with literal hex, so the theme installs without Nix — `nix run .#write-theme-conf` rewrites it
- the Sayori cursor theme, prebuilt, with the script that rebuilds it from its frames
- `nixosModules.default` (`ddlc.sddm`), `overlays.default`, and `nix run .#preview` for the greeter in a window
- checks: `theme.conf` is current, the theme carries every file its QML names, the cursors are whole, and the module is evaluated both against option stubs and inside a real nixpkgs module set

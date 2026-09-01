#!/usr/bin/env bash
# Distro tests for ddlc-sddm-theme: run install.sh for real, as root, inside a container
# of an actual distribution — the one thing the sandboxed suite cannot do. Asserts the
# whole contract: the preflight refuses and its printed guidance actually works, the
# install lands both components and the SDDM config, selective uninstall keeps the rest,
# --uninstall takes everything back out.
#
# The smoke is deliberately Qt-less: no container runs a greeter. The theme is files —
# present per the manifest, with metadata.desktop and theme.conf shaped like the INI
# SDDM reads. SDDM itself is a session dependency: a warning, never a refusal.
#
#   tests/distro.sh              every distribution below
#   tests/distro.sh debian       just one
#
# Needs docker or podman. In CI this runs on push to master, weekly, and by hand — never
# on pull requests: a flaky mirror must not redden someone's change. Images are :latest
# on purpose — the weekly run is the upstream-drift detector.
#
# From the huix-standard template
set -euo pipefail

HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO=$(dirname "$HERE")

declare -A IMAGE=(
  [debian]=docker.io/library/debian:latest
  [ubuntu]=docker.io/library/ubuntu:latest
  [arch]=docker.io/library/archlinux:latest
  [fedora]=docker.io/library/fedora:latest
)

# Bootstrap: only what the harness itself needs to run in a minimal image — never a
# dependency the preflight's guidance is supposed to provide, or the guidance test would
# pass because the answer was planted
declare -A BOOTSTRAP=(
  [debian]='apt-get update -qq && apt-get install -y -qq bash'
  [ubuntu]='apt-get update -qq && apt-get install -y -qq bash'
  [arch]='pacman -Sy --noconfirm --needed bash'
  [fedora]='dnf install -y -q bash'
)

# ======================================================================================
# host half: find an engine, pull fresh, re-execute this script inside the container
# ======================================================================================

if [[ "${1:-}" != "--inside" ]]; then
  engine=""
  for candidate in "${CONTAINER_ENGINE:-}" docker podman; do
    [[ -n "$candidate" ]] || continue
    if command -v "$candidate" >/dev/null && "$candidate" info >/dev/null 2>&1; then
      engine="$candidate"
      break
    fi
  done
  if [[ -z "$engine" ]]; then
    echo "tests/distro.sh: needs a working docker or podman" >&2
    exit 1
  fi

  wanted=("$@")
  ((${#wanted[@]})) || wanted=(debian ubuntu arch fedora)

  fails=0
  for distro in "${wanted[@]}"; do
    image="${IMAGE[$distro]:-}"
    if [[ -z "$image" ]]; then
      echo "tests/distro.sh: no such distribution: $distro" >&2
      exit 1
    fi
    printf '\n== %s (%s)\n' "$distro" "$image"
    # One retry on the pull: a mirror hiccup is not a verdict on anything
    "$engine" pull -q "$image" >/dev/null || "$engine" pull -q "$image" >/dev/null
    # The checkout goes in read-only — the run must not be able to edit it
    if ! "$engine" run --rm -v "$REPO:/src:ro" "$image" \
      bash /src/tests/distro.sh --inside "$distro"; then
      printf '  %s: FAILED\n' "$distro"
      fails=$((fails + 1))
    else
      printf '  %s: passed\n' "$distro"
    fi
  done
  ((fails)) && exit 1
  echo
  echo "all distributions passed"
  exit 0
fi

# ======================================================================================
# container half
# ======================================================================================

distro="$2"

say() { printf '\n  -- %s\n' "$1"; }
die() {
  printf '  !! %s\n' "$1" >&2
  exit 1
}

say "bootstrap ($distro)"
bash -c "${BOOTSTRAP[$distro]}" >/dev/null

# The checkout is mounted read-only; work on a copy a package manager cannot be blamed for
cp -r /src /work
cd /work

prefix=/usr
theme_dir="$prefix/share/sddm/themes/ddlc"
icons_dir="$prefix/share/icons/sayori-cursors"
share_dir="$prefix/share/ddlc-sddm-theme"
manifest="$share_dir/install-manifest"
conf=/etc/sddm.conf.d/10-ddlc.conf

say "a relative PREFIX is rejected"
if PREFIX=usr ./install.sh >/dev/null 2>&1; then
  die "install.sh accepted a relative PREFIX"
fi

say "install, running the printed guidance when the preflight refuses"
rc=0
out=$(./install.sh 2>&1) || rc=$?
if ((rc != 0)); then
  # The refusal must be complete and clean: name what is missing, write nothing
  printf '%s\n' "$out" | grep -q 'missing dependencies' ||
    die "the refusal did not say what is missing: $out"
  [[ ! -e "$share_dir" && ! -e "$theme_dir" ]] ||
    die "a refused install left files behind"
  printf '%s\n' "$out" | grep -qE 'command not found|: line [0-9]' &&
    die "the preflight listed what is missing and then carried on: $out"

  commands=$(printf '%s\n' "$out" | sed -n 's/^  \$ //p')
  if [[ -z "$commands" ]]; then
    echo "::notice title=ddlc-sddm-theme distro test::SKIP on $distro — guidance is manual-only"
    printf '  SKIP: no runnable guidance on %s\n' "$distro"
    exit 0
  fi
  # The container is root and none of these images ships sudo — answered with a shim
  if ! command -v sudo >/dev/null; then
    printf '#!/bin/sh\nexec env "$@"\n' >/usr/local/bin/sudo
    chmod +x /usr/local/bin/sudo
  fi
  export DEBIAN_FRONTEND=noninteractive
  while IFS= read -r cmd; do
    printf '  running printed guidance: %s\n' "$cmd"
    # Process substitution, not a pipe: pipefail would read yes's SIGPIPE death as failure
    bash -c "$cmd" < <(yes 2>/dev/null) || die "printed guidance failed: $cmd"
  done <<<"$commands"

  say "install succeeds once the guidance has been followed"
  ./install.sh || die "install failed after following the guidance"
else
  echo "  (every install dependency was already present — the refusal path ran in tests/installer.sh)"
fi

say "the installed theme answers (Qt-less smoke: files and their INI shape)"
[[ -f "$manifest" ]] || die "no install-manifest after install"
[[ -f "$theme_dir/Main.qml" ]] || die "Main.qml missing"
[[ -e "$icons_dir/index.theme" ]] || die "cursors missing"
[[ -f "$conf" ]] || die "SDDM config missing"
grep -qx 'Current=ddlc' "$conf" || die "the config does not select the theme"
# metadata.desktop and theme.conf are the two files SDDM parses before any QML runs
grep -qx '\[SddmGreeterTheme\]' "$theme_dir/metadata.desktop" ||
  die "metadata.desktop lost its section header"
grep -q '^MainScript=Main.qml$' "$theme_dir/metadata.desktop" ||
  die "metadata.desktop does not name Main.qml"
grep -qx '\[General\]' "$theme_dir/theme.conf" || die "theme.conf lost its section header"
# Every line is a section, a key=value, a ;comment or blank — no empty alternation in
# the pattern: some grep implementations reject `|)` outright
bad=$(grep -vE '^(\[[A-Za-z]+\]|[A-Za-z][A-Za-z0-9]*=.*|;.*|[[:space:]]*)$' \
  "$theme_dir/theme.conf" || true)
[[ -z "$bad" ]] || die "theme.conf has a non-INI line: $bad"
version_out=$(./install.sh --version)
[[ "$version_out" == *"$(cat VERSION)"* ]] ||
  die "--version does not match VERSION: $version_out"
./install.sh --help >/dev/null || die "--help failed"

say "selective uninstall removes one component and keeps the rest"
./install.sh --uninstall --component cursors || die "--uninstall --component failed"
[[ ! -e "$icons_dir" ]] || die "selective uninstall left the cursors"
[[ -f "$theme_dir/Main.qml" ]] || die "selective uninstall took the theme"
./install.sh --component cursors || die "reinstalling one component failed"
[[ -e "$icons_dir/index.theme" ]] || die "the cursors did not come back"

say "uninstall removes exactly what the manifest names"
mapfile -t manifest_paths < <(grep -v '^#' "$manifest" | sed 's/^[a-z-]* //')
./install.sh --uninstall || die "--uninstall failed"
for path in "${manifest_paths[@]}"; do
  [[ ! -e "$path" && ! -L "$path" ]] || die "uninstall left $path behind"
done
[[ ! -e "$share_dir" ]] || die "uninstall left $share_dir behind"
[[ ! -e "$conf" ]] || die "uninstall left the SDDM config"

say "a second uninstall is quiet and succeeds"
./install.sh --uninstall >/dev/null || die "uninstall is not idempotent"

echo
echo "  $distro: full cycle passed"

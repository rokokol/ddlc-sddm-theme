#!/usr/bin/env bash
# The fast suite for install.sh: flag surface, the manifest contract, the per-component
# sweep, selective uninstall, the declarative --no-configure, staging, and the refusal
# path — everything that needs no container. This is the installer's contract only: the
# theme itself is QML the greeter runs, and `nix run .#preview` is how that gets looked
# at (see CLAUDE.md)
set -euo pipefail

HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO="${1:-$(dirname "$HERE")}"

fails=0
say() { printf -- '-- %s\n' "$1"; }
die() {
  printf '!! %s\n' "$1" >&2
  fails=$((fails + 1))
}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

prefix="$tmp/prefix"
stage="$tmp/stage"
manifest="$stage$prefix/share/ddlc-sddm-theme/install-manifest"
# Everything goes through DESTDIR staging: the real /etc must never be touched by a test
run() { "$REPO/install.sh" --prefix "$prefix" --destdir "$stage" "$@"; }

say "--help names every flag the case parses, and -v matches VERSION"
mapfile -t flags < <(
  sed -n 's/^ *\(-[-a-zA-Z0-9 |]*\))$/\1/p' "$REPO/install.sh" |
    tr '|' '\n' | tr -d ' ' | sort -u
)
((${#flags[@]})) || die "found no flags in install.sh — the extractor is broken"
help_out=$("$REPO/install.sh" --help)
for flag in "${flags[@]}"; do
  grep -qF -- "$flag" <<<"$help_out" || die "--help does not mention $flag"
done
[[ "$("$REPO/install.sh" -v)" == "ddlc-sddm-theme $(cat "$REPO/VERSION")" ]] ||
  die "-v does not print 'ddlc-sddm-theme \$(cat VERSION)'"

say "bad arguments are refused with exit 2, the usage-error code"
rc=0
run --prefix relative/path >/dev/null 2>&1 || rc=$?
((rc == 2)) || die "a relative PREFIX exited $rc, not the usage-error code 2"
rc=0
run --component greeter >/dev/null 2>&1 || rc=$?
((rc == 2)) || die "an unknown component exited $rc, not the usage-error code 2"
rc=0
run --no-such-flag >/dev/null 2>&1 || rc=$?
((rc == 2)) || die "an unknown flag exited $rc, not the usage-error code 2"
rc=0
run --uninstall --no-configure >/dev/null 2>&1 || rc=$?
((rc == 2)) || die "--uninstall combined with --no-configure exited $rc, not the usage-error code 2"

say "a full install lands both components, the config and the manifest"
run >/dev/null
[[ -f "$stage$prefix/share/sddm/themes/ddlc/Main.qml" ]] || die "theme missing"
[[ -f "$stage$prefix/share/sddm/themes/ddlc/theme.conf" ]] || die "theme.conf missing"
[[ -e "$stage$prefix/share/icons/sayori-cursors/index.theme" ]] || die "cursors missing"
[[ -f "$stage/etc/sddm.conf.d/10-ddlc.conf" ]] || die "SDDM config missing"
grep -q 'CursorTheme=sayori-cursors' "$stage/etc/sddm.conf.d/10-ddlc.conf" ||
  die "the config does not name the cursors"
[[ -f "$manifest" ]] || die "no manifest after install"
for comp in theme cursors meta; do
  grep -q "^$comp " "$manifest" || die "manifest has no $comp entries"
done
if grep -v '^#' "$manifest" | grep -qF "$stage"; then
  die "the staged manifest leaks DESTDIR into a recorded path"
fi
# The cursor theme's symlinks must be recorded, not just its files
grep -q "sayori-cursors/cursors/arrow" "$manifest" || die "cursor symlinks not recorded"

say "re-running with --no-configure sweeps the config away (declarative boolean)"
run --no-configure >/dev/null
[[ ! -e "$stage/etc/sddm.conf.d/10-ddlc.conf" ]] || die "--no-configure left the config"
[[ ! -e "$stage/etc/sddm.conf.d" ]] || die "the empty conf.d was not pruned"
run >/dev/null
[[ -f "$stage/etc/sddm.conf.d/10-ddlc.conf" ]] || die "re-running did not restore the config"

say "--uninstall --component cursors keeps the theme and the config"
run --uninstall --component cursors >/dev/null
[[ ! -e "$stage$prefix/share/icons/sayori-cursors" ]] || die "cursors left behind"
[[ -f "$stage$prefix/share/sddm/themes/ddlc/Main.qml" ]] || die "theme taken with cursors"
[[ -f "$stage/etc/sddm.conf.d/10-ddlc.conf" ]] || die "config taken with cursors"
if grep -q '^cursors ' "$manifest"; then die "manifest still claims cursors"; fi
grep -q '^meta ' "$manifest" || die "meta entries lost on selective uninstall"

say "removing the last real component takes the bookkeeping with it"
run --uninstall --component theme >/dev/null
[[ ! -e "$stage$prefix/share/sddm" ]] || die "theme left behind"
[[ ! -e "$stage/etc/sddm.conf.d" ]] || die "config left behind"
[[ ! -e "$stage$prefix/share/ddlc-sddm-theme" ]] ||
  die "the manifest dir outlived the last component"

say "--uninstall takes a full install out and is idempotent"
run >/dev/null
run --uninstall >/dev/null
[[ ! -e "$stage$prefix/share/sddm" && ! -e "$stage$prefix/share/icons" ]] ||
  die "uninstall left component trees"
[[ ! -e "$stage$prefix/share/ddlc-sddm-theme" ]] || die "uninstall left the share dir"
out=$(run --uninstall)
[[ "$out" == *"nothing to uninstall"* ]] || die "a second uninstall was not quiet: $out"

say "a pre-manifest install is still uninstallable (fallback layout)"
mkdir -p "$stage$prefix/share/sddm/themes"
cp -r "$REPO/theme" "$stage$prefix/share/sddm/themes/ddlc"
install -D -m644 /dev/null "$stage/etc/sddm.conf.d/10-ddlc.conf"
run --uninstall >/dev/null
[[ ! -e "$stage$prefix/share/sddm/themes/ddlc" ]] || die "legacy uninstall missed the theme tree"
[[ ! -e "$stage/etc/sddm.conf.d/10-ddlc.conf" ]] || die "legacy uninstall missed the config"

say "the preflight refuses completely when an install dep is missing"
stub="$tmp/bin"
mkdir -p "$stub"
for tool in bash cat dirname readlink sed tr grep rm rmdir find sort cp mkdir; do
  ln -s "$(command -v "$tool")" "$stub/$tool"
done
echo "ID=debian" >"$tmp/os-release" # the flake-check sandbox has no /etc/os-release
rc=0
out=$(OS_RELEASE="$tmp/os-release" PATH="$stub" bash "$REPO/install.sh" \
  --prefix "$prefix" --destdir "$tmp/refused" 2>&1) || rc=$?
((rc == 1)) || die "the preflight exited $rc, not the missing-dependency code 1"
grep -q 'missing dependencies' <<<"$out" || die "the refusal did not say what is missing"
grep -q ' - install$' <<<"$out" || die "the refusal did not name install(1)"
grep -qE '^  \$ ' <<<"$out" || die "the refusal printed no runnable guidance"
[[ ! -e "$tmp/refused" ]] || die "a refused install wrote files"

say "the guidance is per-distro and printed as runnable lines"
for pair in "debian:  \$ sudo apt install coreutils" \
  "ubuntu:  \$ sudo apt install coreutils" \
  "arch:  \$ sudo pacman -S --needed coreutils" \
  "fedora:  \$ sudo dnf install coreutils"; do
  id="${pair%%:*}"
  line="${pair#*:}"
  echo "ID=$id" >"$tmp/os-release"
  out=$(OS_RELEASE="$tmp/os-release" PATH="$stub" bash "$REPO/install.sh" \
    --prefix "$prefix" --destdir "$tmp/refused" 2>&1) || true
  grep -qxF "$line" <<<"$out" || die "no '$line' in the $id refusal"
done

say "install.sh and its completions agree"
bash "$REPO/check-sh.sh" -c "$REPO/completions/install.sh.bash" "$REPO/completions/install.sh.zsh" \
  "$REPO/install.sh" >/dev/null || die "completions drift"

echo
if ((fails)); then
  echo "$fails failure(s)"
  exit 1
fi
echo "all install.sh checks passed"

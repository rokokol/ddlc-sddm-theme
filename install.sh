#!/usr/bin/env bash
# Install the DDLC theme on a non-NixOS system. NixOS users take the flake instead — see README
set -euo pipefail

prefix="/usr"
with_cursors=1
configure=1

usage() {
  cat <<EOF
Usage: sudo ./install.sh [options]

Installs the theme, builds the cursors and selects both in SDDM. No flags needed

Options:
  --prefix DIR      install prefix (default: $prefix)
  --no-cursors      skip the Sayori cursor theme
  --no-configure    do not touch /etc/sddm.conf.d, just install the files
  -h, --help        this text

Writes:
  \$prefix/share/sddm/themes/ddlc
  \$prefix/share/icons/sayori-cursors   (unless --no-cursors)
  /etc/sddm.conf.d/10-ddlc.conf         (unless --no-configure)

Everything ships prebuilt — this only copies files, no build tools needed
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prefix)
      prefix="${2:?--prefix needs a directory}"
      shift 2
      ;;
    --no-cursors)
      with_cursors=0
      shift
      ;;
    --no-configure)
      configure=0
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "install.sh: unknown option $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Check before writing anything, so a broken checkout cannot leave a half-install
for need in "$here/theme/Main.qml" "$here/theme/theme.conf"; do
  [[ -e $need ]] || {
    echo "install.sh: $need is missing — run this from a full checkout" >&2
    exit 1
  }
done
if ((with_cursors)) && [[ ! -e $here/cursors/theme/index.theme ]]; then
  echo "install.sh: cursors/theme is missing — rebuild it with cursors/build-cursors.sh," >&2
  echo "or rerun with --no-cursors to install the theme alone" >&2
  exit 1
fi

command -v sddm >/dev/null || command -v sddm-greeter-qt6 >/dev/null ||
  echo "install.sh: warning — SDDM not found on PATH, installing anyway" >&2

themes="$prefix/share/sddm/themes"

# Writability is decided by the closest ancestor that exists — the rest gets created
ancestor="$themes"
while [[ ! -e $ancestor ]]; do ancestor="$(dirname "$ancestor")"; done
[[ -w $ancestor ]] || {
  echo "install.sh: $ancestor is not writable — rerun with sudo, or pass --prefix ~/.local" >&2
  exit 1
}

install -d "$themes"
rm -rf "${themes:?}/ddlc"
cp -r "$here/theme" "$themes/ddlc"
echo "installed $themes/ddlc"

if ((with_cursors)); then
  icons="$prefix/share/icons"
  install -d "$icons"
  rm -rf "${icons:?}/sayori-cursors"
  cp -a "$here/cursors/theme" "$icons/sayori-cursors"
  echo "installed $icons/sayori-cursors"
fi

if ((configure)); then
  # /usr keeps the theme, /etc keeps the configuration — even under a non-default prefix
  confd="/etc/sddm.conf.d"
  install -d "$confd"
  {
    echo "[Theme]"
    echo "Current=ddlc"
    if ((with_cursors)); then printf 'CursorTheme=sayori-cursors\nCursorSize=32\n'; fi
    echo
    echo "[General]"
    # /nix/store mtime=1970 is a NixOS problem, but a stale QML cache after an update is not
    echo "GreeterEnvironment=QML_DISABLE_DISK_CACHE=1"
  } >"$confd/10-ddlc.conf"
  echo "wrote $confd/10-ddlc.conf — the theme is live on the next greeter start"
else
  echo "set Current=ddlc under [Theme] in /etc/sddm.conf.d/ to activate it"
fi

echo "the theme asks for the 'Doki' font family and falls back to the Qt default without it"

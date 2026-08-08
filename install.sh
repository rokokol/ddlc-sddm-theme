#!/usr/bin/env bash
# Install the DDLC theme on a non-NixOS system. NixOS users take the flake instead — see README
set -euo pipefail

prefix="/usr"
with_cursors=1
configure=0

usage() {
  cat <<EOF
Usage: sudo ./install.sh [options]

Options:
  --prefix DIR    install prefix (default: $prefix)
  --no-cursors    skip the Sayori cursor theme
  --configure     also write \$sysconfdir/sddm.conf.d/10-ddlc.conf selecting the theme
  -h, --help      this text

Installs:
  \$prefix/share/sddm/themes/ddlc
  \$prefix/share/icons/sayori-cursors   (unless --no-cursors)

Needs ImageMagick and xcursorgen for the cursors; the theme itself is a plain copy
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
    --configure)
      configure=1
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
done

here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

themes="$prefix/share/sddm/themes"
install -d "$themes"
rm -rf "${themes:?}/ddlc"
cp -r "$here/theme" "$themes/ddlc"
echo "installed $themes/ddlc"

if ((with_cursors)); then
  "$here/cursors/build-cursors.sh" "$prefix/share/icons/sayori-cursors"
  echo "installed $prefix/share/icons/sayori-cursors"
fi

if ((configure)); then
  # /usr keeps the theme, /etc keeps the configuration — even under a non-default prefix
  confd="/etc/sddm.conf.d"
  install -d "$confd"
  {
    echo "[Theme]"
    echo "Current=ddlc"
    ((with_cursors)) && printf 'CursorTheme=sayori-cursors\nCursorSize=32\n'
    echo
    echo "[General]"
    # /nix/store mtime=1970 is a NixOS problem, but a stale QML cache after an update is not
    echo "GreeterEnvironment=QML_DISABLE_DISK_CACHE=1"
  } >"$confd/10-ddlc.conf"
  echo "wrote $confd/10-ddlc.conf"
else
  echo "now set Current=ddlc under [Theme] in /etc/sddm.conf.d/ (or rerun with --configure)"
fi

echo "the theme asks for the 'Doki' font family and falls back to the Qt default without it"

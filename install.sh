#!/usr/bin/env bash
# Install the DDLC theme on a non-NixOS system. NixOS users take the flake instead — see
# README. Everything ships prebuilt: this copies the theme and cursor trees under a
# prefix, selects them in SDDM, and records every path it wrote in an install-manifest
# that --uninstall consumes. Components are additive: installing one never touches the
# other, and --uninstall --component takes one back out on its own
set -euo pipefail

here="$(cd -- "$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
VERSION=$(cat "$here/VERSION")

PREFIX="${PREFIX:-/usr}"
DESTDIR="${DESTDIR:-}"
COMPONENT="${COMPONENT:-all}"
OS_RELEASE="${OS_RELEASE:-/etc/os-release}"
configure=1

usage() {
  cat <<EOF
install the ddlc-sddm-theme $VERSION login screen and cursors

Installs the theme, the prebuilt cursors and selects both in SDDM. No flags needed.
Re-running a component converges it: a file a previous install of that component wrote
and this run does not is removed — running with --no-configure removes a previously
written SDDM config the same way. The other component is never touched.

usage: sudo ./install.sh [options]
  -h, --help         show this help and exit
  -v, --version      print the version and exit
      --prefix DIR   install prefix (default: $PREFIX; env PREFIX)
      --destdir DIR  staging root: the prefix and /etc both land under it (env DESTDIR)
      --component C  install theme, cursors, or all (default: $COMPONENT)
      --no-cursors   compatibility shorthand for --component theme
      --no-configure do not touch /etc/sddm.conf.d, just install the files
      --uninstall    remove what a previous install wrote, by its manifest;
                     with --component C, only that component

Writes:
  \$PREFIX/share/sddm/themes/ddlc
  \$PREFIX/share/icons/sayori-cursors    (component cursors)
  /etc/sddm.conf.d/10-ddlc.conf          (unless --no-configure; component theme)

Everything ships prebuilt — this only copies files, no build tools needed

Exit 0 done, 1 when the install could not be made — a dependency missing, a manifest
that cannot be written — and 2 on a usage error.
EOF
}

die() { # the request itself is wrong
  printf 'install.sh: %s\n' "$1" >&2
  exit 2
}

UNINSTALL=0
config_given=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h | --help)
      usage
      exit 0
      ;;
    -v | --version)
      echo "ddlc-sddm-theme $VERSION"
      exit 0
      ;;
    --prefix)
      # Not ${2:?}: that exits 1 with bash's own message, and a usage error is 2
      (($# >= 2)) || die "$1 needs a directory"
      PREFIX="$2"
      shift 2
      ;;
    --destdir)
      (($# >= 2)) || die "$1 needs a directory"
      DESTDIR="$2"
      shift 2
      ;;
    --component)
      (($# >= 2)) || die "$1 needs a component"
      COMPONENT="$2"
      shift 2
      ;;
    --no-cursors)
      COMPONENT=theme
      shift
      ;;
    --no-configure)
      configure=0
      config_given="$1"
      shift
      ;;
    --uninstall)
      UNINSTALL=1
      shift
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
done

[[ "$PREFIX" == /* ]] || die "PREFIX must be absolute: $PREFIX"
if ((UNINSTALL)) && [[ -n "$config_given" ]]; then
  die "--uninstall does not combine with $config_given"
fi

case "$COMPONENT" in
  all)
    with_theme=1
    with_cursors=1
    ;;
  theme)
    with_theme=1
    with_cursors=0
    ;;
  cursors)
    with_theme=0
    with_cursors=1
    configure=0
    ;;
  *)
    die "component must be theme, cursors, or all: $COMPONENT"
    ;;
esac

root="${DESTDIR%/}$PREFIX"
share_runtime="$PREFIX/share/ddlc-sddm-theme"
share="${DESTDIR%/}$share_runtime"
manifest="$share/install-manifest"

in_scope() { # is component $1 covered by this run's selection?
  # `meta` owns the shared bookkeeping (the installed VERSION copy): every install
  # rewrites it, and only a full uninstall — or removing the last real component —
  # takes it out
  if ((UNINSTALL == 0)) && [[ "$1" == meta ]]; then return 0; fi
  [[ "$COMPONENT" == all || "$COMPONENT" == "$1" ]]
}

# --- manifest helpers ------------------------------------------------------------------
# Each line is `component path`: the component name first (it cannot contain a space),
# then the path it owns as its final runtime path (no DESTDIR) — the manifest ships
# inside a staged tree and stays correct wherever the tree ends up. The component field
# is what makes both the per-component sweep and --uninstall --component possible

old_entries=()
if [[ -f "$manifest" ]]; then
  mapfile -t old_entries < <(grep -v '^#' "$manifest")
fi

installed=()

record_tree() { # record_tree COMPONENT RUNTIME_DIR — record every file in a copied tree
  local f
  while IFS= read -r f; do
    installed+=("$1 ${f#"${DESTDIR%/}"}")
  done < <(find "${DESTDIR%/}$2" \( -type f -o -type l \) | sort)
}

prune() { # remove now-empty parents of RUNTIME_PATH, stopping at its root
  local dir stop
  dir="$(dirname "${DESTDIR%/}$1")"
  stop="$root"
  [[ "$1" == /etc/* ]] && stop="${DESTDIR%/}/etc"
  while [[ "$dir" == "$stop"/* ]]; do
    rmdir "$dir" 2>/dev/null || break
    dir="$(dirname "$dir")"
  done
}

legacy_entries() {
  # Installs made before the manifest existed (<= 1.0.0) left no record; this is their
  # layout — whole trees, removed recursively below. Kept for exactly one release after
  # the manifest arrived; delete this function in the release after that
  echo "theme $PREFIX/share/sddm/themes/ddlc"
  echo "theme /etc/sddm.conf.d/10-ddlc.conf"
  echo "cursors $PREFIX/share/icons/sayori-cursors"
}

# --- uninstall -------------------------------------------------------------------------

if ((UNINSTALL)); then
  entries=("${old_entries[@]}")
  had_manifest=1
  if [[ ! -f "$manifest" ]]; then
    had_manifest=0
    mapfile -t entries < <(legacy_entries)
  fi
  kept=()
  removed=0
  for entry in "${entries[@]}"; do
    [[ -z "$entry" ]] && continue
    comp="${entry%% *}"
    path="${entry#* }"
    if in_scope "$comp"; then
      if [[ -e "${DESTDIR%/}$path" || -L "${DESTDIR%/}$path" ]]; then
        # The legacy entries are whole owned trees; manifest entries are single files
        rm -rf "${DESTDIR%/}$path"
        removed=$((removed + 1))
      fi
      prune "$path"
    else
      kept+=("$entry")
    fi
  done
  # bookkeeping alone is not an install: when no real component remains, take the
  # meta entries (the VERSION copy) out with the last one
  real_left=0
  for entry in "${kept[@]}"; do
    [[ "${entry%% *}" == meta ]] || real_left=1
  done
  if ((real_left == 0)) && ((${#kept[@]})); then
    for entry in "${kept[@]}"; do
      rm -f "${DESTDIR%/}${entry#* }"
    done
    kept=()
  fi
  if ((had_manifest)) && ((${#kept[@]})); then
    {
      echo "# ddlc-sddm-theme $VERSION install manifest"
      printf '%s\n' "${kept[@]}"
    } >"$manifest"
    echo "uninstalled the $COMPONENT component ($removed files); the rest stays"
  elif ((had_manifest)); then
    rm -f "$manifest"
    rmdir "$share" 2>/dev/null || true
    echo "uninstalled ddlc-sddm-theme from $root"
  elif ((removed)); then
    echo "uninstalled the $COMPONENT component ($removed trees, pre-manifest install)"
  else
    echo "ddlc-sddm-theme: nothing to uninstall under $root"
  fi
  exit 0
fi

# --- preflight: refuse loudly, install nothing ----------------------------------------
# install deps: the copy itself cannot happen without them — any missing means collect
# them all, print the report, exit 1 having written nothing.
# session deps: SDDM is the user's own display manager — a theme for a greeter you have
# not installed yet is still a valid install, so a warning and the install proceeds

missing=()
absent=()

need() { command -v "$1" >/dev/null 2>&1 || missing+=("$1"); }

need install
if in_scope theme; then
  command -v sddm >/dev/null 2>&1 || command -v sddm-greeter-qt6 >/dev/null 2>&1 ||
    absent+=("sddm")
fi

distro_id() {
  sed -n 's/^ID\(_LIKE\)\?=//p' "$OS_RELEASE" 2>/dev/null | tr -d '"' | tr '\n' ' '
}

guidance() {
  # One recommended method per distro. Runnable lines are printed as `  $ command` —
  # two spaces, dollar, space — and the distro tests run exactly those lines, so this
  # text cannot rot silently. No -y/--noconfirm: a human is reading; the tests arrange
  # non-interactivity around the command, never inside it
  case " $(distro_id) " in
    *" arch "*)
      echo "Install them on Arch:"
      echo '  $ sudo pacman -S --needed coreutils'
      ;;
    *" debian "* | *" ubuntu "*)
      echo "Install them on Debian/Ubuntu:"
      echo '  $ sudo apt install coreutils'
      ;;
    *" fedora "*)
      echo "Install them on Fedora:"
      echo '  $ sudo dnf install coreutils'
      ;;
    *)
      echo "Install coreutils with your package manager"
      ;;
  esac
}

if ((${#missing[@]})); then
  {
    echo "install.sh: missing dependencies:"
    printf '  - %s\n' "${missing[@]}"
    echo
    guidance
  } >&2
  exit 1
fi
if ((${#absent[@]})); then
  printf 'install.sh: not found (comes from your session, install proceeds): %s\n' \
    "${absent[@]}" >&2
fi

# Check before writing anything, so a broken checkout cannot leave a half-install
if ((with_theme)); then
  for need_file in "$here/theme/Main.qml" "$here/theme/theme.conf"; do
    [[ -e $need_file ]] || {
      echo "install.sh: $need_file is missing — run this from a full checkout" >&2
      exit 1
    }
  done
fi
if ((with_cursors)) && [[ ! -e $here/cursors/theme/index.theme ]]; then
  echo "install.sh: cursors/theme is missing — rebuild it with cursors/build-cursors.sh," >&2
  echo "or rerun with --component theme to install the theme alone" >&2
  exit 1
fi

# Writability is decided by the closest ancestor that exists — the rest gets created
ancestor="$root/share"
while [[ ! -e $ancestor ]]; do ancestor="$(dirname "$ancestor")"; done
[[ -w $ancestor ]] || {
  echo "install.sh: $ancestor is not writable — rerun with sudo, or pass --prefix ~/.local" >&2
  exit 1
}

# --- install ---------------------------------------------------------------------------

if ((with_theme)); then
  themes="$root/share/sddm/themes"
  install -d "$themes"
  rm -rf "${themes:?}/ddlc"
  cp -r "$here/theme" "$themes/ddlc"
  record_tree theme "$PREFIX/share/sddm/themes/ddlc"
  echo "installed $themes/ddlc"
fi

if ((with_cursors)); then
  icons="$root/share/icons"
  install -d "$icons"
  rm -rf "${icons:?}/sayori-cursors"
  cp -a "$here/cursors/theme" "$icons/sayori-cursors"
  record_tree cursors "$PREFIX/share/icons/sayori-cursors"
  echo "installed $icons/sayori-cursors"
fi

if ((configure)) && ((with_theme)); then
  # /usr keeps the theme, /etc keeps the configuration — even under a non-default prefix
  confd="${DESTDIR%/}/etc/sddm.conf.d"
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
  installed+=("theme /etc/sddm.conf.d/10-ddlc.conf")
  echo "wrote $confd/10-ddlc.conf — the theme is live on the next greeter start"
elif ((with_theme)); then
  echo "set Current=ddlc under [Theme] in /etc/sddm.conf.d/ to activate it"
fi

# The per-component sweep: whatever a previous install of these components wrote and
# this run did not — a dropped --no-configure removes the config the same way. Entries
# of the component outside this run's scope carry over untouched
kept=()
for entry in "${old_entries[@]}"; do
  [[ -z "$entry" ]] && continue
  comp="${entry%% *}"
  path="${entry#* }"
  if in_scope "$comp"; then
    fresh=0
    for now in "${installed[@]}"; do
      [[ "$entry" == "$now" ]] && fresh=1
    done
    if ((fresh == 0)); then
      rm -f "${DESTDIR%/}$path"
      prune "$path"
    fi
  else
    kept+=("$entry")
  fi
done

install -d "$share"
install -m644 "$here/VERSION" "$share/VERSION"
installed+=("meta $share_runtime/VERSION")
{
  echo "# ddlc-sddm-theme $VERSION install manifest"
  printf '%s\n' "${kept[@]}" "${installed[@]}"
} >"$manifest"

if ((with_theme)); then
  echo "the theme asks for the 'Doki' font family and falls back to the Qt default without it"
fi
echo "installed ddlc-sddm-theme $VERSION ($COMPONENT) — manifest: $manifest"

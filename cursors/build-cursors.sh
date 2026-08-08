#!/usr/bin/env bash
# Build the Sayori X cursor theme. The plain head is the default cursor, the glitched one
# is shown over clickable elements — the way the icon changed in the game during glitches.
# Single implementation for both paths: nix/cursors.nix and install.sh call this script
set -euo pipefail

usage() {
  cat <<EOF
Usage: build-cursors.sh <icon-theme-dir>

Writes an XCursor theme into <icon-theme-dir> (cursors/ plus index.theme), for example
  build-cursors.sh ~/.local/share/icons/sayori-cursors

Needs: ImageMagick (magick or convert) and xcursorgen
EOF
}

[[ $# -eq 1 ]] || {
  usage >&2
  exit 2
}
[[ $1 == -h || $1 == --help ]] && {
  usage
  exit 0
}

src="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/assets"
out="$1"

# ImageMagick 7 renamed convert to magick; accept either
if command -v magick >/dev/null; then
  im=(magick)
elif command -v convert >/dev/null; then
  im=(convert)
else
  echo "build-cursors.sh: need ImageMagick (magick or convert)" >&2
  exit 1
fi
command -v xcursorgen >/dev/null || {
  echo "build-cursors.sh: need xcursorgen (x11-apps / xorg-xcursorgen)" >&2
  exit 1
}

cursors="$out/cursors"
mkdir -p "$cursors"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# Scale the source into several sizes and assemble one X cursor;
# the hotspot is the top-left edge of the head (~10% of the size)
build_cursor() {
  local png="$1" name="$2" size
  local cfg="$work/$name.cfg"
  : >"$cfg"
  for size in 24 32 48 64; do
    "${im[@]}" "$png" -resize "$size"x"$size" "$work/$name-$size.png"
    echo "$size $((size / 10)) $((size / 10)) $work/$name-$size.png" >>"$cfg"
  done
  xcursorgen "$cfg" "$cursors/$name"
}

build_cursor "$src/sayori-head.png" left_ptr
build_cursor "$src/sayori-head-glitch.png" pointing_hand

# Standard cursor names — symlinks to the two built ones
for alias in default arrow top_left_arrow text xterm ibeam watch wait \
  progress half-busy crosshair cross left_side right_side \
  top_side bottom_side size_ver size_hor size_fdiag size_bdiag \
  fleur move all-scroll not-allowed no-drop question_arrow \
  whats_this up_arrow; do
  ln -sf left_ptr "$cursors/$alias"
done
for alias in hand1 hand2 hand pointer openhand grab grabbing closedhand \
  dnd-none dnd-move dnd-copy dnd-link; do
  ln -sf pointing_hand "$cursors/$alias"
done

cat >"$out/index.theme" <<EOF
[Icon Theme]
Name=sayori-cursors
Comment=Sayori's head (DDLC) as a cursor for SDDM
EOF

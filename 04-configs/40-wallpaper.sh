#!/usr/bin/env bash
# 04-configs/40-wallpaper.sh
# Set the Tahoe-Beach wallpaper. MacTahoe-kde ships a day/dark-aware wallpaper
# package "MacTahoe" (contents/images + contents/images_dark, 3840x2160) plus
# static "MacTahoe-Light" / "MacTahoe-Dark". We prefer the dynamic package so
# the wallpaper tracks the light/dark switch automatically.
set -euo pipefail

WPBASE="${XDG_DATA_HOME:-$HOME/.local/share}/wallpapers"
DYNAMIC="$WPBASE/MacTahoe"                    # day+dark aware package
LIGHT_IMG="$WPBASE/MacTahoe-Light/contents/images/3840x2160.jpeg"
DARK_IMG="$WPBASE/MacTahoe-Dark/contents/images/3840x2160.jpeg"

if command -v plasma-apply-wallpaperimage >/dev/null 2>&1; then
  if [[ -d "$DYNAMIC" ]]; then
    # Point at the dynamic package dir; Plasma's image wallpaper plugin reads
    # images/ vs images_dark/ per the active color scheme.
    plasma-apply-wallpaperimage "$DYNAMIC"
    echo "==> Applied dynamic Tahoe-Beach wallpaper (day/dark aware): $DYNAMIC"
  elif [[ -f "$DARK_IMG" ]]; then
    plasma-apply-wallpaperimage "$DARK_IMG"
    echo "==> Applied static dark Tahoe-Beach wallpaper: $DARK_IMG"
  else
    echo "!! No MacTahoe wallpaper found under $WPBASE — run 03-theme/install-base.sh first."
    exit 1
  fi
else
  echo "!! plasma-apply-wallpaperimage not found."; exit 1
fi

# The auto light/dark switcher (50-*) does NOT need to touch the wallpaper when
# the dynamic package is used — it flips itself. If you applied a STATIC image,
# the switcher will swap MacTahoe-Light <-> MacTahoe-Dark images too.
echo "    Static variants available for the switcher:"
echo "      light: $LIGHT_IMG"
echo "      dark:  $DARK_IMG"

#!/usr/bin/env bash
# 04-configs/60-a11y.sh
# Accessibility hooks for the Tahoe theme. Each dimension is independent.
#
#   transparency on|off     Liquid-glass blur/translucency. OFF => opaque Kvantum
#                           surfaces + Plasma Blur effect disabled (reduce transparency).
#   contrast on|off         Swap the color scheme to the increased-contrast variant
#                           and raise Plasma contrast. Persists a flag the auto
#                           switcher reads so light mode stays high-contrast.
#   motion on|off           reduce-motion: OFF => KWin animations off (AnimationSpeed
#                           to instant) + Kvantum state-fade off.
#   status                  print current state of all three.
#
# Examples:
#   ./60-a11y.sh transparency off      # reduce transparency
#   ./60-a11y.sh contrast on           # increase contrast
#   ./60-a11y.sh motion off            # reduce motion
set -euo pipefail

KVDIR="${XDG_CONFIG_HOME:-$HOME/.config}/Kvantum/MacTahoe"
FLAGDIR="${XDG_CONFIG_HOME:-$HOME/.config}/tahoe-liquid-glass"
mkdir -p "$FLAGDIR"

reconfigure() {
  for t in ${QDBUS:-qdbus} qdbus; do
    command -v "$t" >/dev/null 2>&1 && { "$t" org.kde.KWin /KWin reconfigure 2>/dev/null || true; break; }
  done
}

# --- reduce transparency ----------------------------------------------------
set_transparency() {   # $1 = on|off
  local on="$1" val
  for kv in "$KVDIR/MacTahoe.kvconfig" "$KVDIR/MacTahoeDark.kvconfig"; do
    [[ -f "$kv" ]] || continue
    if [[ "$on" == "off" ]]; then
      ${KWRITECONFIG:-kwriteconfig5} --file "$kv" --group "%General" --key translucent_windows false
      ${KWRITECONFIG:-kwriteconfig5} --file "$kv" --group "%General" --key blurring            false
      ${KWRITECONFIG:-kwriteconfig5} --file "$kv" --group "%General" --key popup_blurring      false
      ${KWRITECONFIG:-kwriteconfig5} --file "$kv" --group "%General" --key reduce_menu_opacity 0
      ${KWRITECONFIG:-kwriteconfig5} --file "$kv" --group "Hacks"    --key blur_translucent    false
    else
      ${KWRITECONFIG:-kwriteconfig5} --file "$kv" --group "%General" --key translucent_windows true
      ${KWRITECONFIG:-kwriteconfig5} --file "$kv" --group "%General" --key blurring            true
      ${KWRITECONFIG:-kwriteconfig5} --file "$kv" --group "%General" --key popup_blurring      true
      ${KWRITECONFIG:-kwriteconfig5} --file "$kv" --group "Hacks"    --key blur_translucent    true
    fi
  done
  # Plasma desktop Blur effect (the 02-glass-effect substrate).
  [[ "$on" == "off" ]] && val=false || val=true
  ${KWRITECONFIG:-kwriteconfig5} --file kwinrc --group Plugins --key blurEnabled "$val"
  # Plasma panel/widget opacity: opaque panels when reducing transparency.
  [[ "$on" == "off" ]] && val="3" || val="2"   # 3=Opaque, 2=Translucent (Adaptive)
  echo "$1" > "$FLAGDIR/transparency"
  reconfigure
  echo "==> transparency: $on"
}

# --- increase contrast ------------------------------------------------------
set_contrast() {   # $1 = on|off
  local on="$1"
  if [[ "$on" == "on" ]]; then
    echo 1 > "$FLAGDIR/contrast"
    # Apply the high-contrast LIGHT scheme now (the switcher will keep it for
    # daytime; dark stays TahoeDark which is already AA).
    command -v plasma-apply-colorscheme >/dev/null 2>&1 && \
      plasma-apply-colorscheme TahoeLight-Contrast || true
    ${KWRITECONFIG:-kwriteconfig5} --file kdeglobals --group KDE --key contrast 7
  else
    echo 0 > "$FLAGDIR/contrast"
    command -v plasma-apply-colorscheme >/dev/null 2>&1 && \
      plasma-apply-colorscheme TahoeLight || true
    ${KWRITECONFIG:-kwriteconfig5} --file kdeglobals --group KDE --key contrast 4
  fi
  reconfigure
  echo "==> contrast: $on"
}

# --- reduce motion ----------------------------------------------------------
set_motion() {   # $1 = on|off  (on = animations enabled; off = reduced)
  local on="$1"
  if [[ "$on" == "off" ]]; then
    # KWin global animation speed: 0 = instant (Plasma maps this to "very fast/off").
    ${KWRITECONFIG:-kwriteconfig5} --file kwinrc --group KDE --key AnimationDurationFactor 0
    # Kvantum: disable the 200ms state fade.
    for kv in "$KVDIR/MacTahoe.kvconfig" "$KVDIR/MacTahoeDark.kvconfig"; do
      [[ -f "$kv" ]] && ${KWRITECONFIG:-kwriteconfig5} --file "$kv" --group "%General" --key animate_states false
    done
  else
    ${KWRITECONFIG:-kwriteconfig5} --file kwinrc --group KDE --key AnimationDurationFactor 1
    for kv in "$KVDIR/MacTahoe.kvconfig" "$KVDIR/MacTahoeDark.kvconfig"; do
      [[ -f "$kv" ]] && ${KWRITECONFIG:-kwriteconfig5} --file "$kv" --group "%General" --key animate_states true
    done
  fi
  echo "$1" > "$FLAGDIR/motion"
  reconfigure
  echo "==> motion: $on"
}

status() {
  echo "Tahoe a11y state:"
  for f in transparency contrast motion; do
    if [[ -f "$FLAGDIR/$f" ]]; then printf "  %-13s %s\n" "$f" "$(cat "$FLAGDIR/$f")"
    else printf "  %-13s (default)\n" "$f"; fi
  done
}

case "${1:-status}" in
  transparency) set_transparency "${2:?on|off}" ;;
  contrast)     set_contrast     "${2:?on|off}" ;;
  motion)       set_motion       "${2:?on|off}" ;;
  status)       status ;;
  *) echo "usage: $0 {transparency|contrast|motion on|off | status}"; exit 1 ;;
esac

#!/usr/bin/env bash
# 04-configs/45-dynamic-wallpaper.sh
# Install / remove the sun-driven 4-phase DYNAMIC wallpaper for Plasma 6 (Wayland).
#
# This is a finer-grained WALLPAPER engine that supersedes the 2-state wallpaper
# swap in tahoe-theme-switch (50-auto-light-dark). It maps the time of day onto
# four macOS-Tahoe "Beach" frames, timed to the sun in Phoenix, AZ:
#
#     NIGHT (post-dusk .. pre-dawn) ......... 26-Tahoe-Beach-Night.png
#     MORNING golden/twilight (~1h @ sunrise) 26-Tahoe-Beach-Dawn.png
#     DAY (mid-morning .. mid-afternoon) .... 26-Tahoe-Beach-Day.png
#     EVENING golden (~1h @ sunset) ......... 26-Tahoe-Beach-Dawn.png  (reused)
#     EVENING civil twilight (deeper blue) .. 26-Tahoe-Beach-Dusk.png
#
# Twilight-extension rule: Phoenix civil twilight is only ~25-30 min, so each
# transition band is anchored on golden hour and widened to ~1h rather than shown
# for its literal window. See tahoe-wallpaper-phase for the exact math.
#
#   install   -> place tahoe-wallpaper-phase + tahoe-wallpaper-rearm in
#                ~/.local/bin, install the systemd --user service+timer, enable
#                them, and apply the current phase now.
#   uninstall -> disable + remove everything (leaves images + theme switcher).
#   status    -> show timer state + today's resolved schedule.
#
# Requires: python3 + astral, plasma-apply-wallpaperimage, systemd (user).
#
# IMAGES ARE NOT SHIPPED IN THIS (PUBLIC) REPO — they are large Apple wallpapers.
# Place the four frames yourself at:
#     ~/.local/share/wallpapers/Tahoe-Beach-Dynamic/images/
#         26-Tahoe-Beach-Dawn.png   26-Tahoe-Beach-Day.png
#         26-Tahoe-Beach-Dusk.png   26-Tahoe-Beach-Night.png
# (Source: extract the macOS 26 "Tahoe" Beach dynamic wallpaper frames from a Mac,
#  or from a community mirror, at 6016x3384.) If a 5th "blue hour" frame appears as
#  26-Tahoe-Beach-Blue.png in that dir, the engine uses it for the evening
#  deeper-blue slot automatically. If the frames are missing, install still wires
#  up the units and the engine degrades gracefully (day/night fallback).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACTION="${1:-install}"

BIN="$HOME/.local/bin"
UNITS="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
IMAGES="${XDG_DATA_HOME:-$HOME/.local/share}/wallpapers/Tahoe-Beach-Dynamic/images"

# Back up a file we are about to overwrite (only if it differs), timestamped.
_backup() {
  local f="$1"
  [[ -e "$f" ]] || return 0
  cmp -s "$f" "$2" 2>/dev/null && return 0   # identical -> nothing to back up
  local b="$f.bak.$(date +%Y%m%d-%H%M%S)"
  cp -a "$f" "$b"
  echo "    backed up $f -> $b"
}

install_engine() {
  mkdir -p "$BIN" "$UNITS"

  if ! python3 -c "import astral" 2>/dev/null; then
    echo "!! python 'astral' not found. Install it, e.g.:"
    echo "     pip install --user astral"
    echo "     # or:  sudo apt install python3-astral / sudo pacman -S python-astral"
    echo "   Continuing to install units; the engine will error until astral is present."
  fi

  # Idempotent install with backup of any pre-existing (differing) copies.
  _backup "$BIN/tahoe-wallpaper-phase"          "$HERE/files/tahoe-wallpaper-phase"
  _backup "$BIN/tahoe-wallpaper-rearm"          "$HERE/files/tahoe-wallpaper-rearm"
  _backup "$UNITS/tahoe-wallpaper-phase.service" "$HERE/files/tahoe-wallpaper-phase.service"
  _backup "$UNITS/tahoe-wallpaper-phase.timer"   "$HERE/files/tahoe-wallpaper-phase.timer"

  install -m 0755 "$HERE/files/tahoe-wallpaper-phase" "$BIN/tahoe-wallpaper-phase"
  install -m 0755 "$HERE/files/tahoe-wallpaper-rearm" "$BIN/tahoe-wallpaper-rearm"
  install -m 0644 "$HERE/files/tahoe-wallpaper-phase.service" "$UNITS/tahoe-wallpaper-phase.service"
  install -m 0644 "$HERE/files/tahoe-wallpaper-phase.timer"   "$UNITS/tahoe-wallpaper-phase.timer"

  if [[ ! -f "$IMAGES/26-Tahoe-Beach-Day.png" ]]; then
    echo "!! Tahoe-Beach frames not found under:"
    echo "     $IMAGES"
    echo "   Units are installed but the engine will fall back to day/night until"
    echo "   you place: 26-Tahoe-Beach-{Dawn,Day,Dusk,Night}.png there."
  fi

  systemctl --user daemon-reload
  systemctl --user enable --now tahoe-wallpaper-phase.timer
  # Run once now so the desktop matches the sun immediately (also arms the precise
  # transient re-arm timer via ExecStartPost).
  systemctl --user start tahoe-wallpaper-phase.service || true

  echo "==> Dynamic 4-phase wallpaper installed and enabled."
  echo "    Phoenix coords by default; override with TAHOE_LAT/TAHOE_LON/TAHOE_TZ."
  "$BIN/tahoe-wallpaper-phase" schedule 2>/dev/null | sed 's/^/    /' || true
}

uninstall_engine() {
  systemctl --user disable --now tahoe-wallpaper-phase.timer 2>/dev/null || true
  systemctl --user stop tahoe-wallpaper-rearm-oneshot.timer 2>/dev/null || true
  rm -f "$UNITS/tahoe-wallpaper-phase.service" "$UNITS/tahoe-wallpaper-phase.timer"
  rm -f "$BIN/tahoe-wallpaper-phase" "$BIN/tahoe-wallpaper-rearm"
  systemctl --user daemon-reload
  echo "==> Dynamic wallpaper engine removed (images + theme switcher untouched)."
}

case "$ACTION" in
  install)   install_engine ;;
  uninstall) uninstall_engine ;;
  status)
    systemctl --user list-timers 'tahoe-wallpaper*' --all --no-pager 2>/dev/null || true
    [[ -x "$BIN/tahoe-wallpaper-phase" ]] && "$BIN/tahoe-wallpaper-phase" schedule
    ;;
  *) echo "usage: $0 {install|uninstall|status}"; exit 1 ;;
esac

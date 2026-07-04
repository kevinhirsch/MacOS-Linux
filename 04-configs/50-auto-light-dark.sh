#!/usr/bin/env bash
# 04-configs/50-auto-light-dark.sh
# Install / remove the sun-based light<->dark auto switcher.
#
#   install   -> place tahoe-theme-switch + rearm in ~/.local/bin, install the
#                systemd --user service+timer, enable them, and apply now.
#   uninstall -> disable + remove everything.
#   status    -> show timer state and next transition.
#
# Requires: python3 + astral (pip install --user astral, or python3-astral),
#           plasma-apply-colorscheme, plasma-apply-lookandfeel, ${KWRITECONFIG:-kwriteconfig5},
#           systemd (user instance).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACTION="${1:-install}"

BIN="$HOME/.local/bin"
UNITS="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"

install_switcher() {
  mkdir -p "$BIN" "$UNITS"

  # Check astral early with a clear message.
  if ! python3 -c "import astral" 2>/dev/null; then
    echo "!! python 'astral' not found. Install it, e.g.:"
    echo "     pip install --user astral"
    echo "     # or:  sudo apt install python3-astral / sudo pacman -S python-astral"
    echo "   Continuing to install units; the switcher will error until astral is present."
  fi

  install -m 0755 "$HERE/files/tahoe-theme-switch" "$BIN/tahoe-theme-switch"
  install -m 0755 "$HERE/files/tahoe-theme-rearm"  "$BIN/tahoe-theme-rearm"
  install -m 0644 "$HERE/files/tahoe-theme-switch.service" "$UNITS/tahoe-theme-switch.service"
  install -m 0644 "$HERE/files/tahoe-theme-switch.timer"   "$UNITS/tahoe-theme-switch.timer"

  systemctl --user daemon-reload
  systemctl --user enable --now tahoe-theme-switch.timer
  # Run once immediately so the desktop matches the sun right now (also arms the
  # precise transient re-arm timer via ExecStartPost).
  systemctl --user start tahoe-theme-switch.service || true

  echo "==> Auto light/dark installed and enabled."
  echo "    Phoenix coords by default; override with TAHOE_LAT/TAHOE_LON/TAHOE_TZ"
  echo "    in ~/.config/environment.d/ or the service's Environment=."
  "$BIN/tahoe-theme-switch" next-time | sed 's/^/    next transition: /'
}

uninstall_switcher() {
  systemctl --user disable --now tahoe-theme-switch.timer 2>/dev/null || true
  systemctl --user stop tahoe-theme-rearm-oneshot.timer 2>/dev/null || true
  rm -f "$UNITS/tahoe-theme-switch.service" "$UNITS/tahoe-theme-switch.timer"
  rm -f "$BIN/tahoe-theme-switch" "$BIN/tahoe-theme-rearm"
  systemctl --user daemon-reload
  echo "==> Auto light/dark removed."
}

case "$ACTION" in
  install)   install_switcher ;;
  uninstall) uninstall_switcher ;;
  status)
    systemctl --user status tahoe-theme-switch.timer --no-pager 2>/dev/null || true
    systemctl --user list-timers 'tahoe-*' --no-pager 2>/dev/null || true
    [[ -x "$BIN/tahoe-theme-switch" ]] && "$BIN/tahoe-theme-switch" next-time | sed 's/^/next transition: /'
    ;;
  *) echo "usage: $0 {install|uninstall|status}"; exit 1 ;;
esac

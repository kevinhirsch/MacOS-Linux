#!/usr/bin/env bash
# 04-configs/30-fonts.sh
# Wire SF Pro Text as the Plasma 6 UI font at the macOS type ramp, plus a
# fontconfig alias so "SF Pro Text" resolves (with Inter/Noto fallback).
#
# kdeglobals font value is a QFont string:
#   family,pointSize,pixelSize(-1),styleHint,weight,italic,underline,strikeout,fixedPitch,rawMode[,styleName]
# QFont weights:  Regular/Normal=50  Medium=57  DemiBold=63  Bold=75
# styleHint 5 = "AnyStyle" (safe default).
#
# Type ramp comes from ../tokens/tahoe.json:
#   body/UI 13 · title3 15 · title2 17 · title1 22 · subheadline 11 · caption 10
# Plasma exposes: general (UI), fixed (mono), toolbar (small), menu, window
# title, and the small font. We map the ramp onto those slots.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

UI="SF Pro Text"
MONO="SF Mono"          # falls back via fontconfig if absent
DISPLAY="SF Pro Display"

# --- Make sure the fonts actually EXIST -------------------------------------
# Without this, the QFont strings below silently fall back to Noto Sans (very
# un-macOS). Inter is the free SF-Pro-like fallback; real SF Pro is not
# redistributable, so we only install it if you dropped Apple's pack on the Desktop.
if ! fc-list 2>/dev/null | grep -qi 'Inter'; then
  sudo apt-get install -y fonts-inter >/dev/null 2>&1 \
    && echo "==> installed Inter (SF-Pro-like fallback)" \
    || echo "!! could not apt-install fonts-inter (UI will fall back to Noto)"
fi
if ! fc-list 2>/dev/null | grep -qi 'SF Pro'; then
  SFZIP="$(ls "$HOME"/Desktop/San-Francisco-Pro-Fonts*.zip 2>/dev/null | head -1 || true)"
  if [[ -n "$SFZIP" ]] && command -v unzip >/dev/null 2>&1; then
    _t="$(mktemp -d)"; unzip -oq "$SFZIP" -d "$_t"
    mkdir -p "$HOME/.local/share/fonts/SF-Pro"
    find "$_t" \( -iname '*.otf' -o -iname '*.ttf' \) -exec cp {} "$HOME/.local/share/fonts/SF-Pro/" \;
    rm -rf "$_t"
    echo "==> installed real SF Pro from $SFZIP"
  else
    echo "   (no SF Pro pack on Desktop — drop San-Francisco-Pro-Fonts*.zip there for exact type parity)"
  fi
fi
command -v fc-cache >/dev/null 2>&1 && fc-cache -f >/dev/null 2>&1 || true

# QFont builder: $1 family, $2 size, $3 weight(default 50), $4 italic(default 0)
qfont() { printf '%s,%s,-1,5,%s,%s,0,0,0,0' "$1" "$2" "${3:-50}" "${4:-0}"; }

# General / UI font — body 13pt Regular.
${KWRITECONFIG:-kwriteconfig5} --file kdeglobals --group General --key font        "$(qfont "$UI" 13 50)"
# Fixed / monospace — 13pt.
${KWRITECONFIG:-kwriteconfig5} --file kdeglobals --group General --key fixed        "$(qfont "$MONO" 13 50)"
# Small font (used by clocks/labels) — footnote 10pt.
${KWRITECONFIG:-kwriteconfig5} --file kdeglobals --group General --key smallestReadableFont "$(qfont "$UI" 10 50)"
# Toolbar font — subheadline 11pt.
${KWRITECONFIG:-kwriteconfig5} --file kdeglobals --group General --key toolBarFont  "$(qfont "$UI" 11 50)"
# Menu font — body 13pt (menu item token is 24pt tall; text is 13pt).
${KWRITECONFIG:-kwriteconfig5} --file kdeglobals --group General --key menuFont     "$(qfont "$UI" 13 50)"
# Window title font — headline 13pt Bold-ish; Aurorae centers it.
${KWRITECONFIG:-kwriteconfig5} --file kdeglobals --group WM      --key activeFont   "$(qfont "$UI" 13 63)"

# Desktop/plasma font (some KCMs read this group too).
${KWRITECONFIG:-kwriteconfig5} --file kdeglobals --group General --key desktopFont  "$(qfont "$UI" 13 50)"

# --- fontconfig alias so SF Pro resolves (with fallback) --------------------
FCDIR="${XDG_CONFIG_HOME:-$HOME/.config}/fontconfig/conf.d"
mkdir -p "$FCDIR"
install -m 0644 "$HERE/files/fontconfig-sf-pro.conf" "$FCDIR/50-sf-pro.conf"
if command -v fc-cache >/dev/null 2>&1; then
  fc-cache -f >/dev/null 2>&1 || true
fi

echo "==> Fonts set to $UI at the macOS type ramp (body 13pt)."
echo "    fontconfig alias installed ($FCDIR/50-sf-pro.conf); SF Pro -> Inter -> Noto fallback."
echo "    Display face ($DISPLAY) is used by apps that request >=20pt optically."
echo "    Note: SF Pro is not redistributable — install Apple's SF fonts, or the"
echo "          fallback (Inter) will be used automatically."

# Nudge running apps to re-read fonts.
if command -v ${QDBUS:-qdbus} >/dev/null 2>&1; then
  ${QDBUS:-qdbus} org.kde.KWin /KWin reconfigure 2>/dev/null || true
fi

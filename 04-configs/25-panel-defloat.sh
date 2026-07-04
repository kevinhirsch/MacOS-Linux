#!/usr/bin/env bash
# 04-configs/25-panel-defloat.sh
# Make the floating dock behave like the macOS Dock: it must ALWAYS float and stay
# glassy — even when a window touches it — AND still reserve a strut so a maximized
# window stops ABOVE it (leaving the wallpaper strip at the bottom).
#
# The tension: only a NormalPanel reserves a strut (→ the wallpaper gap), but stock
# Plasma de-floats a NormalPanel when a window touches it (Panel.qml sets
# floatingnessTarget = 0 in the touchingWindow branch). The built-in "never de-float"
# exception only covers NON-NormalPanel modes:
#     if (panel.visibilityMode != Panel.Global.NormalPanel && floating) { floatingnessTarget = 1 }
# We broaden it to ANY floating panel:
#     if (floating) { floatingnessTarget = 1 }
# so the strut-reserving NormalPanel dock never de-floats. The top bar is non-floating,
# so it is unaffected. Pair this with the dock at panelVisibility=0 (set in
# 00-apply-lookandfeel.sh) + panelOpacity=2 (Translucent) to get gap + float + glassy.
#
# ⚠ This edits a Plasma SYSTEM file; a plasma-workspace package update reverts it.
# The patch is idempotent and self-healing — re-run this script (or ./install.sh) after
# a Plasma update to re-apply. Original is backed up to <file>.tahoe-orig.
set -euo pipefail

PQ_CANDIDATES=(
  "/usr/share/plasma/shells/org.kde.plasma.desktop/contents/views/Panel.qml"
  "/usr/share/plasma/shells/org.kde.plasma.desktop/contents/ui/Panel.qml"
)
PQ=""
for c in "${PQ_CANDIDATES[@]}"; do [ -f "$c" ] && PQ="$c" && break; done
if [ -z "$PQ" ]; then
  echo "!! Panel.qml not found (Plasma layout changed?) — skipping de-float patch"; exit 0
fi

OLD='if (panel.visibilityMode != Panel.Global.NormalPanel && floating) {'
NEW='if (floating) { // TAHOE: any floating panel never de-floats (was: non-NormalPanel only)'

if grep -q 'TAHOE: any floating panel never de-floats' "$PQ"; then
  echo "==> Panel.qml de-float patch already applied: $PQ"
  exit 0
fi
if ! grep -qF "$OLD" "$PQ"; then
  echo "!! expected line not found in $PQ (Plasma changed the source?) — skipping to avoid corrupting it"
  echo "   look for the 'never de-float' exception and set the guard to 'if (floating)'."
  exit 0
fi

sudo cp --update=none "$PQ" "${PQ}.tahoe-orig" 2>/dev/null || true
# fixed-string replace via a temp file (portable, no regex escaping surprises)
tmp="$(mktemp)"
sudo sed "s|$(printf '%s' "$OLD" | sed 's/[&/\]/\\&/g')|$(printf '%s' "$NEW" | sed 's/[&/\]/\\&/g')|" "$PQ" > "$tmp"
sudo cp "$tmp" "$PQ"; rm -f "$tmp"

if grep -q 'TAHOE: any floating panel never de-floats' "$PQ"; then
  echo "==> Patched Panel.qml so the floating dock never de-floats: $PQ"
  echo "    (takes effect on next plasmashell start / login)"
else
  echo "!! patch did not apply cleanly — check $PQ (original at ${PQ}.tahoe-orig)"; exit 1
fi

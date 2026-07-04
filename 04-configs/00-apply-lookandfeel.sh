#!/usr/bin/env bash
# 04-configs/00-apply-lookandfeel.sh
# Apply the MacTahoe global theme (look-and-feel) and pin the Kvantum widget
# style. Dark by default; the auto switcher flips light/dark later.
set -euo pipefail

LNF_DARK="com.github.vinceliuice.MacTahoe-Dark"
LNF_LIGHT="com.github.vinceliuice.MacTahoe-Light"

if command -v plasma-apply-lookandfeel >/dev/null 2>&1; then
  # --resetLayout would also stamp the theme's panel layout; we DON'T pass it
  # because 04-configs/20-dock-panel.sh owns our panel layout.
  plasma-apply-lookandfeel --apply "$LNF_DARK"
  echo "==> Applied look-and-feel: $LNF_DARK"
else
  echo "!! plasma-apply-lookandfeel missing"; exit 1
fi

# Ensure Qt apps use Kvantum (look-and-feel may reset widgetStyle to Breeze).
${KWRITECONFIG:-kwriteconfig5} --file kdeglobals --group KDE --key widgetStyle "kvantum"

# Icon theme + cursor from the MacTahoe pack if installed (best-effort).
${KWRITECONFIG:-kwriteconfig5} --file kdeglobals --group Icons --key Theme "MacTahoe" 2>/dev/null || true

echo "    (light variant available: $LNF_LIGHT)"

#!/usr/bin/env bash
# 04-configs/00-apply-lookandfeel.sh
# Apply the MacTahoe global theme (look-and-feel) and pin the Kvantum widget
# style. Dark by default; the auto switcher flips light/dark later.
set -euo pipefail

LNF_DARK="com.github.vinceliuice.MacTahoe-Dark"
LNF_LIGHT="com.github.vinceliuice.MacTahoe-Light"

if command -v plasma-apply-lookandfeel >/dev/null 2>&1; then
  # Apply appearance AND stamp the theme's macOS panel layout (--resetLayout):
  # a top menu bar (Apple menu + global menu left; system tray + clock right) and a
  # floating icons-only dock. The custom JS in 10/20 previously reinvented this and
  # produced a broken, inverted bar; the theme's own layout is the correct macOS one.
  plasma-apply-lookandfeel --apply "$LNF_DARK" --resetLayout
  echo "==> Applied look-and-feel + macOS panel layout: $LNF_DARK"

  # Panel metrics -> macOS: thin flush menu bar (token menuBar.height 31px) and a
  # floating, always-visible dock. NOTE: Plasma flattens the dock's float gap only
  # under a *maximized* window (KWin engine limit — no always-float toggle exists).
  if command -v "${QDBUS:-qdbus6}" >/dev/null 2>&1; then
    sleep 2   # let plasmashell finish rebuilding panels from the reset layout
    "${QDBUS:-qdbus6}" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
      var ps = panels();
      for (var i = 0; i < ps.length; i++) { var p = ps[i];
        if (p.location == "top")    { p.floating = false; p.height = 30; }
        if (p.location == "bottom") { p.floating = true;  p.hiding = "none"; }
      }' >/dev/null 2>&1 || true
    # Panels default to Adaptive opacity -> they go solid/opaque (dark, on a dark
    # scheme) whenever ANY window is maximized. Force Translucent (2) so the menu bar
    # and dock stay frosted. Keyed by panel containment id; applies on next reload.
    for _pid in $("${QDBUS:-qdbus6}" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript \
        'var s="";var ps=panels();for(var i=0;i<ps.length;i++){s+=ps[i].id+" ";}print(s);' 2>/dev/null | grep -v qt.svg); do
      "${KWRITECONFIG:-kwriteconfig6}" --file plasma-org.kde.plasma.desktop-appletsrc \
        --group Containments --group "$_pid" --group General --key panelOpacity 2
    done
  fi
else
  echo "!! plasma-apply-lookandfeel missing"; exit 1
fi

# Ensure Qt apps use Kvantum (look-and-feel may reset widgetStyle to Breeze).
${KWRITECONFIG:-kwriteconfig5} --file kdeglobals --group KDE --key widgetStyle "kvantum"

# Icon theme (dark) + macOS cursor from the MacTahoe icon-theme pack (installed by
# 03-theme/install-icons.sh). Cursor theme is set in kcminputrc [Mouse]; note the
# cursor dirs must also be reachable via ~/.icons (see install-icons.sh).
${KWRITECONFIG:-kwriteconfig5} --file kdeglobals --group Icons --key Theme "MacTahoe-dark" 2>/dev/null || true
${KWRITECONFIG:-kwriteconfig5} --file kcminputrc --group Mouse --key cursorTheme "MacTahoe-cursors" 2>/dev/null || true

echo "    (light variant available: $LNF_LIGHT)"

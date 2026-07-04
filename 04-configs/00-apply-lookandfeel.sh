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

  # Panel behavior -> macOS (verified against plasma-workspace panelview.cpp / Panel.qml):
  #   * menu bar: flush (floating=false), thin (~31px token).
  #   * dock: floating, macOS-style. Visibility "none"/NormalPanel(0) => reserves a strut
  #     (setExclusiveZone(thickness) in panelview.cpp) so a MAXIMIZED window stops ABOVE the
  #     dock, leaving a wallpaper gap at the bottom (the real macOS look). It stays floating
  #     + translucent because the window never touches the panel rect, so Panel.qml's
  #     `touchingWindow` de-float/opaque trigger never fires. (WindowsGoBelow(3) reserved no
  #     strut → window slid UNDER the dock → no wallpaper gap; that was the earlier compromise.)
  #   * opacityMode Translucent(2): both panels stay CLEAR even when a window touches them
  #     (Adaptive default turns them opaque on touch). The real key is `panelOpacity` in
  #     ~/.config/plasmashellrc [PlasmaViews][Panel <id>] — NOT `opacityMode`, NOT appletsrc.
  if command -v "${QDBUS:-qdbus6}" >/dev/null 2>&1; then
    sleep 2   # let plasmashell finish rebuilding panels from the reset layout
    "${QDBUS:-qdbus6}" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
      var ps = panels();
      for (var i = 0; i < ps.length; i++) { var p = ps[i];
        if (p.location == "top")    { p.floating = false; p.height = 30; }
        if (p.location == "bottom") { p.floating = true;  p.hiding = "none"; }
      }' >/dev/null 2>&1 || true
    # Persist opacity (both) + visibility (dock=NormalPanel/0 → reserves strut → wallpaper
    # gap under maximized windows) to plasmashellrc, the file PanelView actually reads.
    _pairs=$("${QDBUS:-qdbus6}" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript \
      'var o="";panels().forEach(function(p){o+=p.location+" "+p.id+"\n";});print(o);' 2>/dev/null | grep -vE 'qt.svg|^$' || true)
    while read -r _loc _id; do
      [ -n "${_id:-}" ] || continue
      "${KWRITECONFIG:-kwriteconfig6}" --file plasmashellrc --group PlasmaViews --group "Panel $_id" --key panelOpacity 2 || true
      [ "$_loc" = "bottom" ] && "${KWRITECONFIG:-kwriteconfig6}" --file plasmashellrc --group PlasmaViews --group "Panel $_id" --key panelVisibility 0 || true
    done <<< "$_pairs"
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

#!/usr/bin/env bash
# 04-configs/10-global-menu.sh
# macOS-style top menu bar:
#   1) Tell KWin to route window menus to a Widget (not the titlebar button).
#   2) Ensure the appmenu DBus service is active for Qt/KDE apps.
#   3) Install the GTK env snippet so GTK apps export their menu too.
#   4) Add the org.kde.plasma.appmenu applet to a TOP panel (creates one if the
#      user has none), left-aligned so App/File/Edit read left-to-right.
#
# Qt/KDE apps talk DBus menu natively once menuBar=Widget. GTK apps need
# appmenu-gtk-module + UBUNTU_MENUPROXY (step 3) and a relogin.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1) KWin: export the menu to a widget/applet instead of showing a titlebar
#    "Application Menu" button. This is the switch that makes the global menu
#    receive Qt/KDE app menus.
${KWRITECONFIG:-kwriteconfig5} --file kdeglobals   --group Appmenu --key EnableAppMenu true
${KWRITECONFIG:-kwriteconfig5} --file kwinrc       --group Windows --key menuBar "Widget"

# 2) Make sure the appmenu DBus registrar is running now (it autostarts, but we
#    kick it so the current session picks up menus without a relogin).
if command -v /usr/lib/plasma-appmenu-registrar >/dev/null 2>&1; then
  /usr/lib/plasma-appmenu-registrar >/dev/null 2>&1 &
fi

# 3) GTK apps: install the environment.d snippet.
ENVDIR="${XDG_CONFIG_HOME:-$HOME/.config}/environment.d"
mkdir -p "$ENVDIR"
install -m 0644 "$HERE/files/50-appmenu-gtk.conf" "$ENVDIR/50-appmenu-gtk.conf"
echo "==> Installed $ENVDIR/50-appmenu-gtk.conf (GTK menu export; needs relogin)."

# 4) Add the Global Menu applet to a top panel via a KWin/Plasma script.
#    We drive plasmashell over DBus with a JS snippet: reuse a top panel if one
#    exists, else create a slim top panel and drop the appmenu widget at the
#    left. This is the supported programmatic way to edit panels in Plasma 6.
read -r -d '' PLASMA_JS <<'JS' || true
var found = null;
for (var i = 0; i < panels().length; i++) {
    if (panels()[i].location === "top") { found = panels()[i]; break; }
}
if (found === null) {
    found = new Panel;
    found.location = "top";
    found.height = Math.round(gridUnit * 1.6);   // slim menu bar
    found.hiding = "none";
}
// Avoid duplicate appmenu widgets.
var hasAppmenu = false;
var w = found.widgets();
for (var j = 0; j < w.length; j++) {
    if (w[j].type === "org.kde.plasma.appmenu") { hasAppmenu = true; break; }
}
if (!hasAppmenu) {
    // Add at the far left so App/File/Edit read left-to-right.
    var menu = found.addWidget("org.kde.plasma.appmenu");
    // Push it to the start of the applet order.
    found.addWidget("org.kde.plasma.panelspacer"); // spacer AFTER menu -> menu stays left
}
JS

if command -v ${QDBUS:-qdbus} >/dev/null 2>&1; then
  ${QDBUS:-qdbus} org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$PLASMA_JS" \
    && echo "==> Global Menu applet added to top panel." \
    || echo "!! Could not script plasmashell; add 'Global Menu' widget manually."
else
  echo "!! ${QDBUS:-qdbus} not found; add the 'Global Menu' widget to a top panel manually."
fi

echo "==> Log out/in once for GTK apps to start exporting their menus."

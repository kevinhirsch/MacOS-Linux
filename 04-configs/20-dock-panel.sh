#!/usr/bin/env bash
# 04-configs/20-dock-panel.sh
# Build a macOS-style DOCK as a Plasma panel:
#   - floating (detached from the screen edge, rounded)
#   - horizontal, centered, length hugs its contents (not full width)
#   - icons-only task manager, 48px icons, launchers pinned
#   - bottom of screen, dodge-windows auto-hide (optional flag)
#
# We use the plasmashell scripting API (evaluateScript) — the supported way to
# create/configure panels in Plasma 6 without corrupting appletsrc by hand.
#
# Flags:  ./20-dock-panel.sh            # always-visible floating dock
#         AUTOHIDE=1 ./20-dock-panel.sh # auto-hide (dodge windows)
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Ship the macOS-style Trash launcher (Plasma 6 here has no standalone trash applet)
# so it can be pinned at the far right of the dock.
if [[ -f "$HERE/files/tahoe-trash.desktop" ]]; then
  mkdir -p "$HOME/.local/share/applications"
  cp -f "$HERE/files/tahoe-trash.desktop" "$HOME/.local/share/applications/tahoe-trash.desktop"
  update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
fi

ICON_PX=48
# Panel thickness ~ icon + padding. 48px icon in a ~64px thick floating dock.
THICK=64
HIDING="none"
[[ "${AUTOHIDE:-0}" == "1" ]] && HIDING="dodgewindows"

read -r -d '' DOCK_JS <<JS || true
// Remove any prior Tahoe dock we made (tagged via a launcher marker is fragile,
// so instead we just avoid duplicating: skip if a bottom icons-only TM exists).
var dock = null;
for (var i = 0; i < panels().length; i++) {
    var p = panels()[i];
    if (p.location !== "bottom") continue;
    var ws = p.widgets();
    for (var k = 0; k < ws.length; k++) {
        if (ws[k].type === "org.kde.plasma.icontasks") { dock = p; break; }
    }
    if (dock) break;
}
if (dock === null) {
    dock = new Panel;
    dock.location = "bottom";
}

// --- Dock geometry: floating, centered, hug-contents ----------------------
dock.height = ${THICK};                 // panel thickness (px)
dock.hiding = "${HIDING}";
// Plasma 6 panel settings that live on the containment config:
var dc = dock.readConfig ? dock : dock;
// Floating + centered + fit-content are stored in the panel's [General]:
dock.floating = 1;                      // detached, rounded floating panel
// alignment: 132 = center (Plasma enum); lengthMode "fit" hugs contents.
try { dock.alignment = "center"; } catch(e) {}
try { dock.lengthMode = "fit"; } catch(e) {}

// --- Widgets: only an icons-only Task Manager ------------------------------
var hasTasks = false;
var w = dock.widgets();
for (var j = 0; j < w.length; j++) {
    if (w[j].type === "org.kde.plasma.icontasks") { hasTasks = true; }
}
var tasks;
if (!hasTasks) {
    tasks = dock.addWidget("org.kde.plasma.icontasks");
} else {
    for (var j2 = 0; j2 < w.length; j2++) {
        if (w[j2].type === "org.kde.plasma.icontasks") { tasks = w[j2]; }
    }
}

// Configure the icons-only task manager like a macOS dock.
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("iconSpacing", 1);
tasks.writeConfig("maxStripes", 1);
tasks.writeConfig("showOnlyCurrentDesktop", false);
tasks.writeConfig("showOnlyCurrentActivity", false);
tasks.writeConfig("groupingStrategy", 1);       // by program
tasks.writeConfig("onlyGroupWhenFull", false);
tasks.writeConfig("indicateAudioStreams", true);
// Pin a starter set of launchers (edit to taste). Use preferred:// URLs so we don't
// pin a specific browser that may be absent/snap-named (e.g. plain firefox.desktop
// vs firefox_firefox.desktop) — an unresolved pin renders as a broken "?" tile.
// Trash pinned at the far right (macOS-style). Uses the shipped tahoe-trash.desktop
// (installed above); a raw "trash:/" is not a valid icontasks launcher pin.
tasks.writeConfig("launchers",
  "applications:org.kde.dolphin.desktop,preferred://browser,applications:org.kde.konsole.desktop,applications:systemsettings.desktop,applications:tahoe-trash.desktop");
tasks.reloadConfig();
JS

if command -v ${QDBUS:-qdbus} >/dev/null 2>&1; then
  ${QDBUS:-qdbus} org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$DOCK_JS" \
    && echo "==> Floating dock created (icons-only, ${ICON_PX}px, centered, hiding=${HIDING})." \
    || { echo "!! plasmashell scripting failed."; exit 1; }
else
  echo "!! ${QDBUS:-qdbus} not found — cannot script the dock."; exit 1
fi

# The 48px icon size is driven by panel thickness in an icons-only TM (icons
# scale to the panel). THICK=64 yields ~48px icons with padding. If you want to
# pin the exact icon size regardless of thickness, also set the global:
${KWRITECONFIG:-kwriteconfig5} --file kdeglobals --group KDE --key SmallestReadableFont "" 2>/dev/null || true

cat <<'EOF'
==> Dock notes:
    - Icon size ≈ 48px comes from the ~64px floating panel thickness.
    - To force auto-hide later:  AUTOHIDE=1 ./20-dock-panel.sh
    - Launchers are pre-pinned (SystemSettings, Dolphin, Firefox, Konsole);
      edit the "launchers" line in this script to change them.
EOF

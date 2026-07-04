#!/usr/bin/env bash
# 03-theme/aurorae/apply-aurorae.sh
# 1) Overwrite the installed MacTahoe Aurorae rc files with our retuned rc
#    (left traffic lights, 14/24/26pt).
# 2) Point KWin's decoration at the Aurorae theme AND set the button layout at
#    the KDecoration level (ButtonsOnLeft/ButtonsOnRight) so it matches the rc.
#
# Run AFTER install-base.sh. Idempotent. Applies the DARK deco by default;
# the auto switcher (04-configs) flips theme between the Light/Dark variants.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

AUR_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/aurorae/themes"
[[ -d "$AUR_DIR" ]] || { echo "!! $AUR_DIR missing — run install-base.sh first"; exit 1; }

# Drop the retuned rc into every installed MacTahoe scale variant. The rc file
# inside an Aurorae theme dir is named "<ThemeDirName>rc".
install_rc() {
  local variant="$1" src="$2"          # variant e.g. MacTahoe-Dark-1.25x
  local dir="$AUR_DIR/$variant"
  [[ -d "$dir" ]] || return 0          # scale not installed, skip
  cp -f "$src" "$dir/${variant}rc"
  echo "   retuned $dir/${variant}rc"
}

echo "==> Installing retuned Aurorae rc files"
for v in MacTahoe-Dark MacTahoe-Dark-1.25x MacTahoe-Dark-1.5x; do
  install_rc "$v" "$HERE/Tahoe-Dark-rc"
done
for v in MacTahoe-Light MacTahoe-Light-1.25x MacTahoe-Light-1.5x; do
  install_rc "$v" "$HERE/Tahoe-Light-rc"
done

# Bump each theme's version so KWin invalidates its SVG/geometry cache.
for d in "$AUR_DIR"/MacTahoe-*; do
  [[ -f "$d/metadata.desktop" ]] || continue
  ${KWRITECONFIG:-kwriteconfig5} --file "$d/metadata.desktop" --group "Desktop Entry" \
    --key "X-KDE-PluginInfo-Version" "0.4-tahoe"
done

# --- Point KWin at the Aurorae theme (dark by default) ----------------------
DECO_THEME="__aurorae__svg__MacTahoe-Dark"
${KWRITECONFIG:-kwriteconfig5} --file kwinrc --group org.kde.kdecoration2 --key library "org.kde.kwin.aurorae"
${KWRITECONFIG:-kwriteconfig5} --file kwinrc --group org.kde.kdecoration2 --key theme   "$DECO_THEME"

# --- Button layout AT THE KDECORATION LEVEL --------------------------------
# Aurorae reads LeftButtons/RightButtons from its own rc, but KWin also stores
# a KDecoration-level layout; set both so nothing overrides us. Letters:
#   X=Close I=Minimize A=Maximize M=Menu S=OnAllDesktops F=KeepAbove
#   B=KeepBelow H=Help L=Shade
# Traffic lights on the LEFT, nothing on the right.
${KWRITECONFIG:-kwriteconfig5} --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft  "XIA"
${KWRITECONFIG:-kwriteconfig5} --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight ""
# Optional macOS feel: no border, show tooltips.
${KWRITECONFIG:-kwriteconfig5} --file kwinrc --group org.kde.kdecoration2 --key BorderSize      "None"
${KWRITECONFIG:-kwriteconfig5} --file kwinrc --group org.kde.kdecoration2 --key BorderSizeAuto  "false"

# Reload KWin so the decoration + button layout take effect (Wayland & X11).
if command -v ${QDBUS:-qdbus} >/dev/null 2>&1; then
  ${QDBUS:-qdbus} org.kde.KWin /KWin reconfigure 2>/dev/null || true
elif command -v qdbus >/dev/null 2>&1; then
  qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true
fi

echo "==> Aurorae applied: theme=$DECO_THEME, ButtonsOnLeft=XIA (red/yellow/green)."

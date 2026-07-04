#!/usr/bin/env bash
# 03-theme/install-icons.sh
# Install vinceliuice/MacTahoe-icon-theme — the macOS icons AND cursors that
# MacTahoe-kde does NOT ship. Without this, kdeglobals points at a "MacTahoe-dark"
# icon theme that doesn't exist on disk -> everything falls back to Breeze, and the
# cursor stays Breeze too. Idempotent; user-level install (no sudo).
#
# GOTCHA baked in: the cursor themes install to ~/.local/share/icons, but Xcursor
# only searches ~/.icons:/usr/share/icons — so plasma-apply-cursortheme can't find
# them there. We symlink them into ~/.icons so they're discoverable.
set -euo pipefail

REPO_URL="https://github.com/vinceliuice/MacTahoe-icon-theme.git"
WORK="${XDG_CACHE_HOME:-$HOME/.cache}/tahoe-liquid-glass/MacTahoe-icon-theme"

echo "==> Fetching MacTahoe-icon-theme into $WORK"
if [[ -d "$WORK/.git" ]]; then
  git -C "$WORK" pull --ff-only || true
else
  mkdir -p "$(dirname "$WORK")"
  git clone --depth 1 "$REPO_URL" "$WORK"
fi

cd "$WORK"

# Icons: default install lays down MacTahoe / MacTahoe-light / MacTahoe-dark into
# ~/.local/share/icons. (-t blue is the default folder accent; matches macOS.)
echo "==> Installing MacTahoe icon themes (light + dark)"
./install.sh >/dev/null

# Cursors: separate installer under cursors/ -> MacTahoe-cursors + MacTahoe-dark-cursors.
if [[ -x cursors/install.sh ]]; then
  echo "==> Installing MacTahoe cursor themes"
  ( cd cursors && ./install.sh >/dev/null )
fi

# Make the cursor themes discoverable via the classic Xcursor path (~/.icons).
mkdir -p "$HOME/.icons"
for c in MacTahoe-cursors MacTahoe-dark-cursors; do
  if [[ -d "$HOME/.local/share/icons/$c" ]]; then
    ln -sfn "$HOME/.local/share/icons/$c" "$HOME/.icons/$c"
  fi
done

command -v gtk-update-icon-cache >/dev/null 2>&1 \
  && gtk-update-icon-cache -qtf "$HOME/.local/share/icons/MacTahoe-dark" 2>/dev/null || true

echo "==> Icons + cursors installed. Icon theme + cursor are selected in 04-configs/00-apply-lookandfeel.sh"
echo "    (icon: MacTahoe-dark · cursor: MacTahoe-cursors). Live-apply with:"
echo "      plasma-apply-cursortheme MacTahoe-cursors ; plasma-changeicons MacTahoe-dark"

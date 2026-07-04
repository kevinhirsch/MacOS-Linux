#!/usr/bin/env bash
# 03-theme/color-schemes/install-colors.sh
# Install the Tahoe .colors schemes and apply the dark one by default.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DEST="${XDG_DATA_HOME:-$HOME/.local/share}/color-schemes"
mkdir -p "$DEST"

for f in TahoeLight.colors TahoeDark.colors TahoeLight-Contrast.colors; do
  install -m 0644 "$HERE/$f" "$DEST/$f"
  echo "   installed $DEST/$f"
done

# Apply dark by default (the auto switcher will manage light/dark thereafter).
if command -v plasma-apply-colorscheme >/dev/null 2>&1; then
  plasma-apply-colorscheme TahoeDark || true
  echo "==> Applied TahoeDark."
else
  echo "!! plasma-apply-colorscheme not found; scheme files installed but not applied."
fi

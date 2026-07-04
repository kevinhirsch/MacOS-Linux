#!/usr/bin/env bash
# 03-theme/install-base.sh
# Install vinceliuice/MacTahoe-kde as the BASE, then let the other scripts in
# this dir drop Tahoe-Liquid-Glass overrides on top. Idempotent.
#
# Usage:  ./install-base.sh            # user install (~/.local, ~/.config)
#         PREFIX=/usr sudo ./install-base.sh   # system-wide
set -euo pipefail

REPO_URL="https://github.com/vinceliuice/MacTahoe-kde.git"
WORK="${XDG_CACHE_HOME:-$HOME/.cache}/tahoe-liquid-glass/MacTahoe-kde"

echo "==> Fetching MacTahoe-kde base into $WORK"
if [[ -d "$WORK/.git" ]]; then
  git -C "$WORK" pull --ff-only
else
  mkdir -p "$(dirname "$WORK")"
  git clone --depth 1 "$REPO_URL" "$WORK"
fi

cd "$WORK"

# Real upstream install.sh flags (verified):
#   -d, --dest DIR     destination (default: $HOME -> user install)
#   -n, --name NAME    theme name (default: MacTahoe)
#   -c, --color light|dark   omit to install ALL variants (what we want)
#
# Omitting -c installs BOTH light + dark; default name MacTahoe is what our
# override scripts expect. The *look* is retuned afterward by the overrides.
ARGS=()
if [[ -n "${PREFIX:-}" ]]; then
  ARGS+=(-d "${PREFIX}/share")
fi

./install.sh "${ARGS[@]}"

echo "==> Base MacTahoe-kde installed."
echo "==> Now run, in order:"
echo "      ./apply-kvantum-overrides.sh"
echo "      ./aurorae/apply-aurorae.sh"
echo "      ./color-schemes/install-colors.sh"
echo "    then the 04-configs scripts."

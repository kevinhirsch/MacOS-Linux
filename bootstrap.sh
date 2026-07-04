#!/usr/bin/env bash
# =============================================================================
#  bootstrap.sh — one-command first-boot setup for Tahoe Liquid Glass
# =============================================================================
#  Fresh Kubuntu 26 (Plasma 6) — run this ONE line (keeps your terminal so sudo
#  can prompt for a password):
#
#      bash <(curl -fsSL https://raw.githubusercontent.com/kevinhirsch/MacOS-Linux/main/bootstrap.sh)
#
#  Or, from an existing checkout:  ./bootstrap.sh
#
#  It: installs prerequisites (git, the matching-Qt Kvantum, python3-astral),
#  clones the repo if needed (→ $HOME/MacOS-Linux, override with TAHOE_DIR=…),
#  then runs install.sh — Phase A on Plasma 5.27, +Phase B (KWin 6 refraction
#  effect) on Plasma 6. Idempotent; safe to re-run.
# =============================================================================
set -euo pipefail

REPO_URL="https://github.com/kevinhirsch/MacOS-Linux.git"
DEST="${TAHOE_DIR:-$HOME/MacOS-Linux}"

c()    { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!! \033[0m%s\n' "$*" >&2; }
die()  { printf '\033[1;31mxx \033[0m%s\n' "$*" >&2; exit 1; }

command -v sudo   >/dev/null 2>&1 || die "sudo not found."
command -v apt-get>/dev/null 2>&1 || die "this bootstrap targets Debian/Ubuntu/Kubuntu (apt)."

# Run-from-checkout? Use it. (BASH_SOURCE is empty when piped — guarded for set -u.)
HERE="$(cd "$(dirname "${BASH_SOURCE[0]:-.}")" 2>/dev/null && pwd || true)"
if [[ -n "$HERE" && -f "$HERE/install.sh" && -f "$HERE/tokens/tahoe.json" ]]; then
  DEST="$HERE"; c "Using existing checkout: $DEST"
fi

# Detect Plasma generation → the right Kvantum package. Default to Qt6 (Kubuntu 26)
# unless we clearly see a Plasma-5-only box.
if command -v kwriteconfig5 >/dev/null 2>&1 && ! command -v kwriteconfig6 >/dev/null 2>&1; then
  KVANTUM_PKG="qt5-style-kvantum"; GEN="5.27"
else
  KVANTUM_PKG="qt6-style-kvantum"; GEN="6"
fi
c "Plasma generation: $GEN   (Kvantum package: $KVANTUM_PKG)"

c "Priming sudo (you may be prompted for your password)…"
sudo -v || die "sudo authentication failed."

c "Installing prerequisites: git, $KVANTUM_PKG, python3-astral"
sudo apt-get update -qq || warn "apt update had warnings; continuing"
sudo apt-get install -y git "$KVANTUM_PKG" python3-astral \
  || warn "some prerequisites failed; install.sh will report what's missing"

if [[ ! -f "$DEST/install.sh" ]]; then
  c "Cloning $REPO_URL → $DEST"
  git clone --depth 1 "$REPO_URL" "$DEST"
fi

cd "$DEST"
c "Handing off to install.sh --glass-deps"
echo
exec ./install.sh --glass-deps "$@"

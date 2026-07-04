#!/usr/bin/env bash
# 03-theme/install-rounded-corners.sh
# Round ALL FOUR window corners (the Aurorae decoration only rounds the titlebar top).
# Uses the KWin "ShapeCorners" effect (matinlotfali/KDE-Rounded-Corners): a GL compositing
# pass that clips every window to a squircle and clips the decoration's native shadow to
# that corner (UseNativeDecorationShadows). Pairs with the squared/hairline-free
# decoration.svg overrides (03-theme/aurorae) so ONE clean squircle renders — no
# titlebar-vs-effect double arc, no bevel lines. Plasma 6 / KWin 6 only.
#
# ⚠ Needs a RELOGIN to first-load a freshly compiled KWin effect (Wayland can't hot-load
#   it; `unloadEffect`/`loadEffect` over dbus are no-ops on this box). Config is written
#   now and activates on next login.
# ⚠ Do NOT also enable the Better Blur / forceblur fork — on this hybrid-GPU box it loads
#   but renders NOTHING and blocks stock blur + ShapeCorners (see memory). Keep stock blur.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KW="${KWRITECONFIG:-kwriteconfig6}"

SO="/usr/lib/x86_64-linux-gnu/qt6/plugins/kwin/effects/plugins/kwin4_effect_shapecorners.so"
SRC="${TAHOE_RC_SRC:-$HOME/Desktop/KDE-Rounded-Corners}"

if [[ -f "$SO" ]]; then
  echo "==> ShapeCorners already installed ($SO)"
else
  echo "==> Building KDE-Rounded-Corners (ShapeCorners KWin effect)"
  command -v cmake >/dev/null 2>&1 || sudo apt-get install -y git cmake g++ extra-cmake-modules \
    kwin-dev qt6-base-private-dev qt6-base-dev-tools libkf6kcmutils-dev libdrm-dev \
    || { echo "!! build deps failed; skipping (corners will be titlebar-only)"; exit 0; }
  [[ -d "$SRC/.git" ]] || git clone --depth 1 https://github.com/matinlotfali/KDE-Rounded-Corners "$SRC" \
    || { echo "!! clone failed; skipping"; exit 0; }
  ( set -e; cd "$SRC"; rm -rf build; mkdir build; cd build; cmake .. >/dev/null; cmake --build . -j"$(nproc)" >/dev/null; sudo make install >/dev/null ) \
    || { echo "!! ShapeCorners build failed; skipping (windows keep titlebar-only rounding)"; exit 0; }
  echo "   built + installed ShapeCorners"
fi

echo "==> Writing [Round-Corners] config (radius 12 squircle, no outline, native shadow)"
rc() { "$KW" --file kwinrc --group Round-Corners --key "$1" "$2"; }
rc Size 12;                    rc InactiveCornerRadius 12
rc UseSquircleShape true;      rc Squircleness 0.55
rc RoundedCornersAntialiasing 1 2>/dev/null || true
# no outline strokes (macOS has none) — the effect's default draws a black+white bevel
rc OutlineThickness 0;         rc InactiveOutlineThickness 0
rc SecondOutlineThickness 0;   rc InactiveSecondOutlineThickness 0
rc OuterOutlineThickness 0;    rc InactiveOuterOutlineThickness 0
# no effect-drawn shadow — we use the Aurorae decoration's asymmetric shadow instead
rc ShadowSize 0;               rc InactiveShadowSize 0
# round maximized + tiled windows too (macOS zoom rounds them)
rc DisableRoundMaximize false; rc DisableRoundTile false

# Enable ShapeCorners + keep STOCK blur (frost). Never enable forceblur here.
"$KW" --file kwinrc --group Plugins --key kwin4_effect_shapecornersEnabled true
"$KW" --file kwinrc --group Plugins --key blurEnabled true
"$KW" --file kwinrc --group Plugins --key forceblurEnabled false 2>/dev/null || true

echo "    ShapeCorners config written — takes effect on next login (fresh KWin)."

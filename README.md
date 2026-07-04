# Tahoe Liquid Glass — for Ubuntu / KDE Plasma

A package of packages + configs that reproduces the **macOS Tahoe "Liquid Glass"**
aesthetic on Linux as closely as the platform allows — grounded, token-by-token,
in the Apple HIG and Tahoe screenshots (see [`tokens/tahoe.json`](tokens/tahoe.json),
the source of truth, and the full [`corpus/`](corpus/INDEX.md)). Aesthetic parity only; no Apple code.

It runs **alongside GNOME** on the same machine — installing it does not disturb
your GNOME login. You pick the **"Plasma (X11)"** session to get the Tahoe look.

---

## The honest reality (read this first)

Liquid Glass is a **compositor** effect. GNOME's Mutter can't hand a custom shader
the framebuffer *behind* a surface; **KWin can** — which is why the substrate is
Plasma. That split has one hard consequence on Ubuntu 24.04:

| | Frost (blur behind glass) | Refraction / lensing (the "liquid") |
|---|---|---|
| **What it needs** | stock **KWin Blur** effect | a custom **KWin 6** GLSL effect plugin |
| **Plasma 5.27** (24.04 LTS default) | ✅ real, ships in the box | ❌ old effect API — not viable |
| **Plasma 6** (Kubuntu 26 dual-boot) | ✅ | ✅ (fork *Better Blur* + our shader) |

**Ubuntu 24.04 ships Plasma 5.27, and Plasma 6 is not available for it** — not in
the repos, not via the Kubuntu Backports PPA (verified: it only serves 5.27.x).
So the work is split into two phases:

- **Phase A — everything except the lens (this installer).** Full static parity
  *plus real frosted glass* via stock KWin Blur. Runs today on the installed
  Plasma 5.27. Realistic ceiling ≈ **85%** of the Tahoe look.
- **Phase B — the refraction lens (the last ~10–15%).** The custom KWin effect in
  [`02-glass-effect/`](02-glass-effect/) is written and calibrated to the Figma
  glass numbers, but it only builds against **Plasma 6 / KWin 6**. The plan is a
  **Kubuntu 26 dual-boot**, where the *same* `./install.sh` auto-detects Plasma 6
  and builds + enables it (see [Dual-boot](#dual-boot-ubuntu-2404--kubuntu-26)).
  Ubuntu 24.04 stays on Phase A.

Nothing in Phase A is throwaway: the Kvantum theme, color-schemes, Aurorae
decorations and all configs carry forward to Plasma 6 **unchanged** — only the
one effect `.so` gets built when/if you land on Plasma 6.

---

## What Phase A gives you

- **Real frosted glass** behind windows, menus, panels and the dock (KWin Blur +
  Kvantum translucency + blur regions).
- **Kvantum widget theme** tuned to the tokens — 15px scrollbars, 28/24px control
  heights, 24px menu items, selection fill `#2962D9`/`#0058D0`, links `#4380E8`,
  text never tinted.
- **Aurorae window decorations** with left-side traffic-lights at the measured
  calibration — **14pt** diameter, **24pt** center-to-center, **26pt** inset.
- **Color-schemes** (light / dark / light-contrast) with the `#0A84FF` focus ring
  and the full palette mapped to Plasma's semantic roles.
- **Global menu bar** (Plasma appmenu applet + GTK export) — the macOS menu-at-top.
- **Floating, centered, icons-only dock** (48px, `org.kde.plasma.icontasks`).
- **SF Pro** system font at the macOS type ramp (you supply Apple's fonts; falls
  back to Inter/Noto — SF Pro isn't redistributable).
- **Tahoe-Beach wallpaper** (dynamic day/dark).
- **Auto light/dark** at true Phoenix sunrise/sunset via a self-rearming
  `systemd --user` timer (no DST).
- **Accessibility toggles** — independent transparency / contrast / reduce-motion.

---

## Requirements

- Ubuntu 24.04 with `kde-plasma-desktop` (Plasma 5.27) — or Kubuntu 26 (Plasma 6).
- **Kvantum** for the matching Qt: `qt5-style-kvantum` on 24.04, `qt6-style-kvantum` on Kubuntu 26.
- `git`, `python3-astral` (for the sun switcher), a running Plasma session to *see* it.
- Apple **SF Pro** + **SF Mono** fonts for exact type (optional; auto-fallback otherwise).

## Install

**Fastest on Kubuntu 26** — one command (clone + deps + full Phase A/B):
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/kevinhirsch/MacOS-Linux/main/bootstrap.sh)
```

Or manually:
```bash
# Ubuntu 24.04 (Plasma 5.27) — Phase A: static + frost
./install.sh              # full install (user-level; safe for GNOME)
./install.sh --dry-run    # print every step, change nothing
./install.sh --uninstall  # restore the pre-install Plasma config snapshot

# Kubuntu 26 (Plasma 6) — Phase A + Phase B (refraction), first run:
./install.sh --glass-deps # also apt-installs the KWin-6 build deps, then builds the effect
```

**One script, both OSes.** It detects Plasma 5 vs 6 automatically
(`lib/plasma-tools.sh`): on 5.27 it does Phase A + frost and skips the effect; on
Plasma 6 it *also* builds and enables the refraction effect. It backs up every
Plasma config it touches to `~/.local/state/tahoe-liquid-glass/backup/` before the
first change, and is idempotent. Then **log out → "Plasma (X11)"**.

### Dual-boot (Ubuntu 24.04 + Kubuntu 26)

The two installs have **separate roots** — `git clone`/copy this repo into the
Kubuntu 26 install and run `./install.sh --glass-deps` there; it detects Plasma 6
and gives you full Phase A + B. Ubuntu 24.04 keeps Phase A. Same tokens, same
theme, same configs on both — only the one KWin `.so` is Plasma-6-exclusive.

⚠️ **Keep `/home` separate between the two OSes** (the normal dual-boot default). A
*shared* `/home` makes Plasma 5.27 and Plasma 6 fight over the same `~/.config`
(`kdeglobals`/`kwinrc` differ across versions) — theme breakage, not data loss. If
you must share a data partition, keep the two users' `~/.config` distinct.

---

## Repo layout

```
tokens/tahoe.json      the source of truth — 9 dimensions + load-bearing HIG rules
01-substrate/          notes on the Plasma-alongside-GNOME substrate
02-glass-effect/       Phase B: KWin 6 Liquid-Glass effect (GLSL + C++, Figma-calibrated) — built by install.sh on Plasma 6
03-theme/              Kvantum widget theme · Aurorae traffic-lights · color-schemes
04-configs/            global menu · dock · fonts · wallpaper · auto light/dark · a11y
lib/plasma-tools.sh    resolves kwriteconfig/qdbus for Plasma 5 or 6
install.sh             orchestrator — Phase A on Plasma 5/6; +Phase B auto on Plasma 6 (idempotent, reversible)
parity/                render → compare → tune worksheets (dock, toolbar, Settings)
corpus/                FULL reference corpus (214 MB) — Apple HIG docs, WWDC transcripts, ~80
                       screenshots, the 25 MB Figma file, scripts, artifacts. See corpus/INDEX.md
```

## Parity ceiling — honest

| Surface | Phase A (Plasma 5.27) | With Phase B (Plasma 6) |
|---|---|---|
| Window shape, traffic-lights, decorations | ~95% | ~95% |
| Widgets / controls / type (Kvantum) | ~90% | ~90% |
| Menus / dock / panels **frost** | ~85% | ~90% |
| **Refraction / lensing / specular** | ~0% (not viable on KWin 5) | ~85% |
| Overall feel | **≈85%** | **≈95%** |

The remaining gap to 100% is the part Apple derives at render time (concentric
radii, adaptive-ink flip) and the Figma-kit-only shadow layer values — see
`tokens/tahoe.json` `rules[]` and the low-confidence tokens.

## Phase B — the refraction lens (Kubuntu 26)

`02-glass-effect/` forks **Better Blur** (`taj-ny/kwin-effects-forceblur`, archived
2025-11 at v1.5.0 / Plasma 6.4) and adds Snell refraction (IOR ≈ 2.4), a superellipse
height field, Fresnel-Schlick, Blinn specular, chromatic aberration, and the
adaptive-ink flip. Its default uniforms are **calibrated to the Figma glass numbers**
(Refraction 100 / Depth 16 / Frost 7·12·14 / Splay 6 / Light −45°; see
[`parity/figma-extract.md`](parity/figma-extract.md)). It compiles only on Plasma 6.

On Kubuntu 26, `./install.sh --glass-deps` does the whole thing. To build by hand
or iterate (see [`02-glass-effect/README.md`](02-glass-effect/README.md) §3):

```bash
cd 02-glass-effect && cmake -B build -DCMAKE_INSTALL_PREFIX=/usr && cmake --build build
sudo cmake --install build
kwriteconfig6 --file kwinrc --group Plugins --key tahoe_liquid_glassEnabled true
kwriteconfig6 --file kwinrc --group Plugins --key blurEnabled false   # they conflict
```

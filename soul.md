# soul.md — project context & session handoff

> **Fresh Claude session: read this first.** It's the whole story so Kevin doesn't
> have to re-explain. Then skim `tokens/tahoe.json`, `corpus/INDEX.md`, and
> `parity/figma-extract.md`. This file is the handoff that survives across machines
> (the `~/.claude` memory does NOT travel between the Ubuntu and Kubuntu installs —
> the git repo does).

## What this project is
Pixel-parity **macOS Tahoe "Liquid Glass"** aesthetic for Linux / KDE Plasma.
Aesthetic parity only — **no Apple code**. The machine-readable source of truth is
[`tokens/tahoe.json`](tokens/tahoe.json) (every value carries a `conf` provenance tier).

**Standing rule:** *when in doubt, the Apple HIG and Tahoe screenshots are the corpus.*
Kevin wants it **exact**. He's decisive and wants exhaustive, thorough work — surface
real tradeoffs, don't hedge or pad, and don't re-litigate settled decisions.

## Where we are (2026-07-03)
- **Ubuntu 24.04** (Plasma 5.27 alongside GNOME): Phase A built & verified — Kvantum
  theme, Aurorae left traffic-lights (14/24/26pt), Tahoe color-schemes, SF Pro,
  floating dock, global menu, sun-timed auto light/dark, a11y toggles.
- **Calibrated** to the "macOS 26 (Community)" Figma kit: exact shadow elevation
  system, material vibrancy ramp, component radii, type ramp, and the Liquid Glass
  shader recipe — all folded into `tokens/tahoe.json` as `figma-community` tier.
- **Pushed** to https://github.com/kevinhirsch/MacOS-Linux (`main`).
- **Kevin is now dual-booting Kubuntu 26 (Plasma 6) — the Phase-B target.**

## The one load-bearing fact
Liquid Glass = **frost** (backdrop blur; works on Plasma 5.27's stock KWin Blur) +
**refraction/lensing** (needs a custom **KWin 6** GLSL effect — only builds on
Plasma 6). Plasma 6 is unavailable on Ubuntu 24.04. **Kubuntu 26 is where the
refraction lens finally works** — that's the whole reason for the dual-boot.

## ▶ What to do on Kubuntu 26 (Plasma 6) — the immediate next steps
```bash
sudo apt install -y qt6-style-kvantum        # Kvantum for Qt6 (vs qt5 on 24.04)
git clone https://github.com/kevinhirsch/MacOS-Linux   # if not already cloned
cd MacOS-Linux
./install.sh --glass-deps                     # auto-detects Plasma 6:
                                              #  Phase A + builds & enables the
                                              #  KWin 6 refraction effect
# then log out → pick the Plasma session
```
After it's applied, run the **parity loop** on Kevin's three priority surfaces —
**dock, toolbar, Settings window**: render → compare against
`corpus/screenshots/` → tune `tokens/tahoe.json` → rebuild. Exact targets already
live in the tokens (`shadow.system`, `geometry` radii, `material.glass.figma`,
`material.tint.*`).

## Map of the repo
| Path | What |
|---|---|
| `tokens/tahoe.json` | **Source of truth** — 9 dims + `rules[]`; `conf` tiers: apple / figma-community / measured / estimate / derived |
| `install.sh` | Dual-OS orchestrator. Plasma 5.27 → static + frost; Plasma 6 → +refraction. Idempotent, reversible (`--uninstall`), auto-detects via `lib/plasma-tools.sh` |
| `02-glass-effect/` | KWin 6 Liquid Glass effect (fork of Better Blur). `src/liquidglass.h` defaults are Figma-calibrated. Effect Id `tahoe_liquid_glass` |
| `03-theme/` `04-configs/` | Kvantum + Aurorae + color-schemes; global menu, dock, fonts, wallpaper, auto light/dark, a11y |
| `corpus/INDEX.md` | The entire reference corpus catalog — Apple HIG docs, 3 WWDC transcripts, ~80 Tahoe screenshots, the 25MB Figma extraction, analysis scripts, artifacts |
| `parity/figma-extract.md` | The exact numbers pulled from the Figma kit |

## Gotchas
- **Keep `/home` separate** between the 24.04 and Kubuntu 26 installs — a shared
  `~/.config` makes Plasma 5.27 and 6 fight over `kdeglobals`/`kwinrc`.
- **SF Pro / SF Mono** aren't redistributable — install Apple's fonts on Kubuntu 26
  or the theme falls back to Inter/Noto.
- The community Figma numbers are `figma-community` tier (expert repro, not
  Apple-official) — strong, but flagged where they disagreed with a direct measure
  (e.g. sheet radius: kit 26 vs our screenshot 20).
- The repo is **public** and includes the full corpus (Kevin's informed choice).

## Kevin
Ubuntu 24.04, X11, timezone America/Phoenix. Email kevin@kevinhirsch.com. Also runs
a local dual-2080Ti vLLM stack (separate project). Prefers GNOME keyring at default.

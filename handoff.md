# handoff.md — project context & session handoff

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

## Update — 2026-07-04 (Kubuntu 26 / Plasma 6, Wayland, 1.95× — NOW LIVE)
Ran the install on the real Plasma-6 box. Phase A applied but the stock scripts
produced a **non-macOS desktop**; fixed live and now at strong Tahoe parity (menu
bar + floating dock + macOS icons/cursors + frost + SF Pro all verified on screen).
**Fixes (cmake ones baked into repo; theme/config ones still live-only unless noted):**
- **⚠⚠ NVIDIA hybrid box — flashing gray-line artifacts (CONFIRMED FIX 2026-07-04).**
  This box = Intel iGPU (`card1`) + 2× RTX 2080 Ti (`card0`/`card2`); the monitor is on the
  Intel iGPU (`card1-HDMI-A-2`), leaving both NVIDIA GPUs free for vLLM. Symptom: gray-line
  junk flashing in just-updated screen regions (streaming text / typing). **Root cause = a
  KWin partial-repaint / buffer-age bug on this Intel-Mesa-26 / kernel-7.0 / triple-GPU
  stack. THE FIX — force full-screen repaints:**
  `echo 'KWIN_USE_BUFFER_AGE=0' > ~/.config/environment.d/71-kwin-fullrepaint.conf` then log
  out/in once. That alone fixes it, and blur/frost can then stay ON with no artifacts.
  - **Red herrings — do NOT chase these:** disabling blur or `AllowTearing` did NOT fix it;
    forcing the Intel GPU via `KWIN_DRM_DEVICES` made it WORSE (that tweak was removed). Do
    still keep `kwinrc [Compositing] AllowTearing=false` — KWin 6 defaults it true; off is
    strictly better for a desktop.
  - X11 is NOT a simple alternative here: `plasma-session-x11 + kwin-x11` are installed, but
    the X11 Plasma session crashes on the hybrid PRIME-offload GLX path (Xorg starts fine on
    the Intel display — "terminated successfully (0)" — then plasma exits → black screen →
    back to SDDM). Only viable if you physically move the monitor to a 2080 Ti output +
    `sudo prime-select nvidia` (which dedicates one GPU to the display).
  - Fresh session flashing again? Check `~/.config/environment.d/71-kwin-fullrepaint.conf`
    exists and `echo $XDG_SESSION_TYPE` (should be `wayland`).
- **Icons + cursors were never installed.** `MacTahoe-kde` ships no icons/cursors —
  also install `vinceliuice/MacTahoe-icon-theme` (icons) + its `cursors/`. Cursors
  land in `~/.local/share/icons` but Xcursor only searches `~/.icons:/usr/share/icons`
  → **symlink them into `~/.icons`** or Plasma can't find them.
- **Panel layout never applied.** `00-apply-lookandfeel.sh` set appearance but not the
  layout; the custom `10-global-menu.sh`/`20-dock-panel.sh` JS built a broken bar.
  Real fix: `plasma-apply-lookandfeel -a com.github.vinceliuice.MacTahoe-Dark
  --resetLayout` → macOS top bar (Apple + global menu left; tray/clock right) + floating
  icons-only dock. Then top panel `floating=false` height≈30 (menuBar token 31px);
  dock `floating=true hiding=none`.
- **Dock float caveat:** Plasma flattens the floating gap under a *maximized* window
  (KWin engine limit — no always-float; "Windows Go Below" scripting value rejected on
  6.6). Floats fine in windowed use; auto-hide is the alternative.
- **Fonts:** neither SF Pro nor Inter was installed → UI fell back to Noto Sans. Install
  `fonts-inter` + real **SF Pro** (Apple's `San-Francisco-Pro-Fonts` pack) → `SF Pro
  Text`/`SF Pro Display` resolve correctly.
- **Panel opacity:** panels default to Adaptive → the menu bar + dock go solid/dark
  whenever ANY window is maximized. `00-apply-lookandfeel.sh` now forces `panelOpacity=2`
  (Translucent) per panel-id so they stay frosted.
- **⚠ Global-Theme reset gotcha:** the **"Defaults" button** (or applying another Global
  Theme like Kubuntu Dark / Oxygen) in System Settings → Colors & Themes reverts
  EVERYTHING (look-and-feel, icons, colors, widget style, panel layout) to the distro
  default in one click — this is what "all my settings disappeared" looks like. One-line
  recovery: **`./install.sh --no-base --no-glass`** (re-applies theme + configs, ~1 min).
- **Avoid hard-killing plasmashell** (`systemctl stop`) mid-write — it truncated
  `kcminputrc` to 0 bytes once (lost the cursor theme). Use `kquitapp6 plasmashell`.
- **Phase B build deps:** needs `libdrm-dev` (KWin's cmake transitively requires Libdrm)
  and `KWin::kwineffects` → **`KWin::kwin`** (KWin 6.6 folded the effects target into
  one). ✅ Both baked into `install.sh` + `02-glass-effect/{,src/}CMakeLists.txt`.

## ⚠ Phase B reality-check (this handoff earlier OVERSTATED it)
`02-glass-effect/` is a **DRAFT SKELETON, not a buildable-and-working effect.** Shaders
(`liquid_glass.frag`, 288 lines), factory, uniforms, shader-loading are real — but
`liquidglass.cpp`'s render pipeline (backdrop FBO capture, dual-Kawase down/upsample,
the final lens **draw call**) is all stubbed `TODO`. Even after the cmake fixes it
compiles + loads but **paints nothing** (and enabling it disables stock blur → worse).
To make the lens real: **fork `taj-ny/kwin-effects-forceblur`** (working KWin-6
backdrop+Kawase pipeline) and graft `liquid_glass.frag` onto its final upsample pass.
That is the marquee remaining work — budget it as a real build, not a "run install".

## The one load-bearing fact
Liquid Glass = **frost** (backdrop blur; works on Plasma 5.27's stock KWin Blur) +
**refraction/lensing** (needs a custom **KWin 6** GLSL effect — only builds on
Plasma 6). Plasma 6 is unavailable on Ubuntu 24.04. **Kubuntu 26 is where the
refraction lens finally works** — that's the whole reason for the dual-boot.

## ▶ What to do on Kubuntu 26 (Plasma 6) — the immediate next steps
**One command** (clone + deps + full install; keeps the terminal so sudo can prompt):
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/kevinhirsch/MacOS-Linux/main/bootstrap.sh)
```
Or step by step:
```bash
sudo apt install -y qt6-style-kvantum        # Kvantum for Qt6 (vs qt5 on 24.04)
git clone https://github.com/kevinhirsch/MacOS-Linux && cd MacOS-Linux
./install.sh --glass-deps                     # auto-detects Plasma 6: Phase A +
                                              #  builds & enables the KWin 6 refraction effect
```
Then **log out → pick the Plasma session.**

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

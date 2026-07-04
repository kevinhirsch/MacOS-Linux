# 02 — Tahoe Liquid Glass (KWin 6 desktop effect)

A custom **KWin 6 / Plasma 6** binary desktop effect that renders macOS-Tahoe
"Liquid Glass" (refraction + Fresnel + specular + squircle + adaptive tint)
behind functional surfaces — panels, docks, menus, and window decorations.

Everything here is **draft code**: a real, Plasma-6-correct shader plus the C++
plugin/CMake/metadata scaffolding, with the inherited-from-Better-Blur FBO plumbing
marked as clearly-scoped `TODO`s. It is meant to be dropped into the package and
iterated, not shipped as-is.

---

## 1. Recommendation: FORK Better Blur — do not start from scratch

**Fork `taj-ny/kwin-effects-forceblur` ("Better Blur", GPL-2.0).** Rationale:

- **The hard part is already solved and battle-tested.** Grabbing the region
  *behind* a surface into an offscreen FBO, running an N-iteration dual-Kawase
  down/upsample, tracking the per-window blur region, handling HiDPI/output scale,
  X11 **and** Wayland, and doing it without tanking the frame budget — that is
  ~600 lines of fiddly, backend-sensitive code. Better Blur has shipped it for
  years across many Plasma releases.
- **It already grew Liquid-Glass optics.** PRs #225 (DaddelZeit) and #235/#239
  (iGerman00) added an SDF rounded-rect, a gradient-derived surface normal, a
  concave/convex "lens" mode, per-channel chromatic aberration, and a corner-radius
  control — merged into `src/shaders/upsample.glsl`. So a refractive fork is a
  *proven* shape, not a research bet. Our `liquid_glass.frag` is a superset of that
  shader: same SDF+normal spine, **plus** the pieces it lacks — true Snell
  `refract()` with a tunable IOR, a superellipse thickness profile, Fresnel
  (Schlick), a Blinn specular streak, a material tint, Regular/Clear variants, the
  Clear dim, and the "materialize by lensing" animation hook.
- **From-scratch buys you almost nothing.** You would rewrite the blur chain to
  arrive at the same place. The only from-scratch win is a cleaner class name and
  no GPL-2 lineage — not worth months of backend debugging.

**Important:** Better Blur was **archived (read-only) on 2025-11-20** at v1.5.0,
targeting **Plasma 6.4+**. Fork the archived tree (it still builds against 6.4+),
and be ready to track KWin's effect ABI yourself going forward — that is the real
maintenance cost you are taking on. Active community forks to watch:
`xarblu/kwin-effects-better-blur-dx`, `Fadouse/kwin-effects-better-blur-dx`, and
the Darkly-paired `4v3ngR/kwin-effects-glass`.

### Why NOT the JavaScript ScriptedEffect route

Plasma 6's **JS `ScriptedEffect` still cannot run a custom GLSL fragment shader**
over a backdrop. KWin MR !2227 added `addFragmentShader`/`addShader` to scripted
effects, but that API only feeds shaders into `animate()`/`set()` transforms of a
*whole window texture* — it has no way to sample "the region behind this surface"
or to run a multi-pass blur. For refraction of a live backdrop you **must** write a
**C++ binary effect** (a Qt plugin KWin loads by metadata Id). That is the modern,
and only, correct route. This package takes it.

### Why the C++ effect (not QML `SceneEffect`, not a Plasma theme alone)

- QML `SceneEffect` (the `develop.kde.org/docs/plasma/kwineffect` tutorial) is for
  full-screen scene compositions (overviews, grids). It cannot post-process an
  arbitrary window's backdrop with GLSL.
- A Plasma **theme** (SVG + a QML `FrameSvg`) can *fake* frosted glass with a
  pre-blurred image, but it cannot do live refraction of moving content behind it.
  The theme's job (in `03-theme`) is complementary: it applies the **adaptive-ink
  text recolor** at the same 0.36 luminance threshold this shader uses, and sets
  panel opacity so the effect's backdrop is visible.

---

## 2. What's in this directory

```
02-glass-effect/
├── CMakeLists.txt              top-level build (C++20, Qt6 6.6+, KF6, KWin 6.4+)
├── README.md                   this file
└── src/
    ├── CMakeLists.txt          builds + installs the .so plugin
    ├── main.cpp                KWIN_EFFECT_FACTORY_SUPPORTED_ENABLED(...)
    ├── metadata.json           KPlugin block, Id = tahoe_liquid_glass
    ├── liquidglass.h           LiquidGlassEffect (Effect subclass) + settings + uniforms
    ├── liquidglass.cpp         shader load, uniform binding, per-frame dispatch (draft)
    ├── liquidglass.qrc         compiles shaders into the .so
    └── shaders/
        ├── vertex.vert / _core.vert            pass-through + MVP
        ├── roundedcorners.glsl                 shared squircle mask + geometry uniforms
        ├── downsample.frag / _core.frag        clean Kawase downsample
        └── liquid_glass.frag / _core.frag      ★ the Tahoe optics (upsample + lens)
```

`liquid_glass.frag` is the deliverable to read first — it is heavily commented and
carries the actual optics. The `_core.frag` files are the GLSL 1.40 twins KWin
selects on a desktop core-profile context; **keep each pair in sync**.

---

## 3. Build, install, enable (Plasma 6)

### 3a. Dependencies

**Ubuntu / Debian (Wayland + X11):**
```bash
sudo apt install -y git cmake g++ extra-cmake-modules qt6-tools-dev kwin-dev \
  libkf6configwidgets-dev gettext libkf6crash-dev libkf6globalaccel-dev \
  libkf6kio-dev libkf6service-dev libkf6notifications-dev libkf6kcmutils-dev \
  libkdecorations3-dev libxcb-composite0-dev libxcb-randr0-dev libxcb-shm0-dev \
  libepoxy-dev
```
**Arch:** `sudo pacman -S base-devel git extra-cmake-modules qt6-tools kwin libepoxy`
**Fedora:** `sudo dnf install git cmake extra-cmake-modules gcc-g++ kwin-devel \
  kf6-kcmutils-devel kf6-kconfigwidgets-devel kf6-ki18n-devel kdecoration-devel \
  libepoxy-devel qt6-qtbase-private-devel`

### 3b. Build

```bash
cd 02-glass-effect
rm -rf build            # ALWAYS wipe build/ before rebuilding a KWin effect
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr
make -j"$(nproc)"
sudo make install
```

This installs the plugin to KWin's binary-effect dir, e.g.
`/usr/lib/x86_64-linux-gnu/qt6/plugins/kwin/effects/plugins/kwin_tahoe_liquid_glass.so`
(path varies by distro/arch). Note: binary effects live under the Qt **plugin**
dir, **not** `~/.local/share/kwin/effects/` — that latter path is only for QML/JS
scripted effects and will silently do nothing for a GLSL effect.

### 3c. Enable

GUI: **System Settings → Colors & Themes → Desktop Effects**, find **Tahoe Liquid
Glass** (category *Appearance*), **disable the stock Blur** (and any Better Blur
fork — they conflict), tick ours, Apply.

CLI (works on Wayland and X11):
```bash
kwriteconfig6 --file kwinrc --group Plugins --key tahoe_liquid_glassEnabled true
kwriteconfig6 --file kwinrc --group Plugins --key blurEnabled false
qdbus6 org.kde.KWin /KWin org.kde.KWin.reconfigure    # Wayland
# X11 alternative to reload effects:  kwin_x11 --replace &
```

For the glass to be visible the target surface must be **translucent**. Set panel
opacity in `04-configs` / the Plasma theme, or use a transparent color scheme
(e.g. "Alpha"), or a window rule dropping opacity. Fully-opaque surfaces show no
backdrop, hence no glass.

### 3d. Iterating on the shader

Shaders are compiled into the `.so` via `AUTORCC`, so shader edits need a rebuild
(`make && sudo make install` + `qdbus6 ... reconfigure`). During heavy shader
iteration it is faster to temporarily load the `.frag` from a file path with
`QStandardPaths::locate` (as `KDE-Rounded-Corners/shapecorners.cpp` does) so you
skip the recompile; switch back to the `.qrc` for release.

---

## 4. Honest gaps and constraints

**What KWin can and cannot glass:**

| Surface | Reachable? | How |
|---|---|---|
| **Panels / docks** | Yes | They are `Dock`-type windows KWin composites; matched by `EffectWindow::isDock()`. |
| **App menus, context menus, combo popups, tooltips** | Yes | Override-redirect popup windows; matched by `isPopupMenu()/isDropdownMenu()/isTooltip()`. |
| **Window decorations (titlebars/borders)** | Yes, separately | KWin renders decorations into their own texture; glass them via the decoration paint path (or pair with a KDecoration like `kwin-effects-glass`'s Darkly fork). |
| **Normal app windows** | Only opt-in | Via `_KDE_NET_WM_BLUR_BEHIND_REGION` or a "force"/window-rule list (Better Blur's force-blur mechanism). Off by default to avoid glassing everything. |
| **The plasmashell desktop background, widgets drawn *inside* plasmashell, SDDM/lock, GRUB, the cursor** | **No** | Anything painted in-process by plasmashell (not a separate composited window) or outside the compositor is unreachable by a KWin effect. Krunner and the app launcher **are** separate windows, so those are reachable. |

**Per-window vs. shell chrome:** a KWin effect operates per *composited window*.
There is no single "shell chrome" surface to target; you glass each panel/menu/deco
window individually by class/role. Widgets embedded inside a panel cannot be glassed
independently of the panel.

**Performance caps:**
- Each glassed surface costs a backdrop grab + N blur passes + the lens pass every
  frame it (or content behind it) changes. Many simultaneous translucent surfaces
  (busy panels + open menu + several force-blurred windows) multiply that cost.
- Mitigations, all inherited from Better Blur: a **static-blur** mode (blur the
  wallpaper once, skip live re-blur) for panels over a static background; capping
  blur iterations (`blurStrength`); and the chromatic-aberration/specular being
  cheap adds on top of a blur you were already paying for.
- Recommend a hard cap in the KCM on how many *live* (non-static) glass surfaces
  render per frame, and defaulting panels to static blur.

**X11 vs Wayland:**
- Both are supported (Better Blur supports both; our CMake keeps both paths). The
  optics are backend-agnostic — it is the backdrop capture that differs, and that
  is exactly the code inherited from Better Blur.
- Wayland is the primary target for Plasma 6. Known Wayland perf knobs if the
  cursor lags under GPU load: `KWIN_DRM_NO_AMS=1`, and try
  `KWIN_FORCE_SW_CURSOR=0`/`1`.
- On X11, unredirected fullscreen windows (games) bypass the compositor, so no
  glass there — expected.

**GLSL variant upkeep:** every shader ships a 1.10 (`.frag`) and a 1.40
(`_core.frag`) copy; KWin picks per GL context. Edits must land in both.

**Draft `TODO`s to finish (the Better-Blur-inherited plumbing):**
1. Backdrop capture into `m_renderTargets[0]` (blit current render target region).
2. The dual-Kawase down/upsample loop; issue the lens shader only on the final tap.
3. `reconfigure()` reading `LiquidGlassSettings` from KConfig (group
   `TahoeLiquidGlass`).
4. Per-window `materialize` TimeLine on windowAdded/windowClosed (OutCubic ~200ms).
5. The window-decoration glass path and the KCM (`src/kcm/`).
6. `downsample_core.frag`/`liquid_glass_core.frag` parity checks in CI.

---

## 5. Optics reference (what the shader implements and why)

Adapted from the `ryohsuke1231/liquid-glass` GNOME approach and the Better Blur
refraction PRs, tuned to the Tahoe tokens:

- **Snell refraction** — `refract(-V, N, 1.0/ior)`, `ior ≈ 2.4`. Straight-on view
  `V=(0,0,1)`; the refracted ray's XY becomes a backdrop displacement, scaled by
  `(1 - height)` so **only the bezel bends** (restrained, edge-localized — not a
  global fisheye).
- **Superellipse thickness** — `height = (1 - (1 - x)^n)^(1/n)`, `n ≈ 4`. A squircle
  shoulder: rises fast off the rim, flattens on the interior. Feeds both the normal
  tilt and the specular/Fresnel gating.
- **Surface normal** — from the 2D gradient of the rounded-rect SDF, lifted to 3D
  with `height` as z. Rim ⇒ tilted normal (big bend + strong Fresnel); interior ⇒
  `(0,0,1)` (no bend, clean).
- **Fresnel (Schlick)** — `F0 = ((1-ior)/(1+ior))²`, `F = F0 + (1-F0)(1-cosθ)⁵`.
  Additive white rim brightening.
- **Blinn specular** — half-vector highlight along `lightDir`, gated into the bezel.
- **Chromatic aberration** — split the refraction displacement per channel
  (R bends most, B least) by `rgbFringing`; kept subtle per the tokens.
- **Tint the surface, not the text** — a translucent tint wash over the *refracted
  backdrop only*; the app/text KWin paints afterward is untouched. Regular carries
  tint + a faint inner shade; **Clear** is near-tint-free but applies a **~35% dim**
  gated by backdrop luminance so white foreground stays legible over bright content.
- **Adaptive ink @ 0.36** — the shader cross-fades its tint bias around relative
  luminance 0.36; the **hard dark↔light text flip** lives in the `03-theme` color
  logic reading the *same* threshold, so glass and text agree.
- **Materialize by lensing, not opacity** — the show/hide animation ramps a
  `materialize` uniform that scales refraction + Fresnel + specular while `opacity`
  stays put, so panels appear to *form out of glass*.

### Provenance / licenses
- Blur chain, SDF normal, chromatic aberration, rounded-corner mask: **Better Blur**
  / KWin stock blur — **GPL-2.0-or-later**. This effect inherits that license.
- Snell/superellipse/Fresnel/ink-flip optics concepts: `ryohsuke1231/liquid-glass`
  — **MIT**. Reimplemented here in GLSL for KWin.
```

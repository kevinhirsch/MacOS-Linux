# Pixel-Parity Backlog → macOS Tahoe

Single organized worklist to drive the theme to full parity with the corpus.
Grounded in `corpus/artifacts/` (calibration sheet = numbers, rulebook = laws) and
`corpus/screenshots/` (visual ground truth). Method per surface: **render → set beside
the Apple shot → measure delta → tune → repeat** (3–10 passes each).

**Reachability tiers** (from the strategy doc — be honest about the ceiling):
- **T1 THEME** — fully closable, pixel-exact target (colors, radii, fonts, spacing, metrics, panel materials).
- **T2 COMPOSITOR (KWin)** — convincing, not bit-exact (live glass, refraction, squircle masks).
- **T3 TOOLKIT** — NOT fully closable; per-app at best (dynamic ink on 3rd-party text, real springs).

Status: `todo` / `wip` / `done` / `ceiling` (accepted limit).

---

## P0 — THEME (T1): the closable 80%, do first

| # | Surface / gap | Corpus target | Current | Status |
|---|---|---|---|---|
| 1 | **Panels don't change on maximize** | menu bar transparent + dock frosted, CONSTANT | was Adaptive (`opacityMode`) → fixed to Translucent(2) | wip — verify |
| 2 | **Window sidebar vibrancy** (Dolphin/Finder sidebar translucent+blurred, not flat white) | sidebars float in glass, content extends beneath; dark.material #2B2E31 | flat, not translucent | todo |
| 3 | Traffic lights | d14 / space24 / inset26 pt, left, red/yellow/green | ~on token (verify @2x) | todo-verify |
| 4 | Window radii | 16 / 20 / 26 pt (⚠ corpus flags as *derived/unverified* — converge visually) | Aurorae default | todo |
| 5 | Control metrics | button med 24 / large 28 (capsule r14); ctrl corner ~12; switch 32×21; slider thumb 19 | Kvantum default | todo |
| 6 | List/card metrics | card r9 · row 44 · sidebar-sel 33 · menu item 24 · sheet r20 · toolbar ~50–52 | Kvantum default | todo |
| 7 | Colors | accent #007AFF · **selection #2962D9 (distinct!)** · focus ring #0a84ff/3px · dark.material #2B2E31 · dark.windowBg #24282A | partial | todo |
| 8 | Type ramp | SF Pro Text/Display; body 13/16, headline 13/16 Bold, title 15/17/22, largeTitle 26/32; app-name **semibold** | SF Pro installed; ramp partial | todo |
| 9 | Menu styling | Tahoe menus: 4 rounded corners r~13, translucent, shadow `0 10 30 .22 + hairline` | default | todo |
| 10 | Dock polish | icon 48 · running-dots · tight spacing · NO parabolic magnify (Plasma limit) | good base | todo |
| 11 | Menu bar | height 31px · app name semibold · tray = macOS Control-Center glyphs (hard) | height ok; glyphs Breeze | todo/partial |
| 12 | Shadows | window focused `0 24 60 .45 + 0 2 4 .30`, unfocused receded; ⚠ NEVER the poison `0 8 32 rgba(31,38,135)` | Aurorae default | todo |
| 13 | Wallpaper | exact Tahoe-Beach (day/dark) | dynamic MacTahoe applied | done-ish |
| 14 | Desktop icons | macOS = top-right | top-left (Plasma folder-view can't right-align) | ceiling |

## P1 — COMPOSITOR (T2): live glass, KWin-only

| # | Gap | Target | Current | Status |
|---|---|---|---|---|
| 15 | Live backdrop **frost** on windows+menus | σ≈24 blur behind translucent surfaces | stock KWin blur on; not tuned per-surface | wip |
| 16 | **Liquid Glass lens** (refraction+specular+chromatic) | the Lab shader (`blur24·refract.75·edge56·spec.5·chroma.15·squircle4·vib.5`) ported to KWin | `02-glass-effect` is a **skeleton** (pipeline stubbed) → fork `taj-ny/kwin-effects-forceblur`, graft `liquid_glass.frag` | todo (big) |
| 17 | Squircle window masks | continuous n≈4 corners | Aurorae rounded, not squircle | todo |
| 18 | Materialize-not-fade transitions | modulate lensing not opacity | n/a until 16 | todo |
| 19 | Glass discipline | one plane · never glass-on-glass · morph @40pt | enforce in effect allowlist | todo |

## P2 — TOOLKIT (T3): documented ceilings (accept / partial)

| # | Gap | Why capped | Plan |
|---|---|---|---|
| 20 | **Dynamic ink** (adaptive fg flip @ luminance Y≈0.36) | app owns its glyphs; even macOS auto-applies only to system chrome | do it for shell chrome + shader-drawn only; 3rd-party app text = **ceiling** |
| 21 | **Animations / springs** ("all wrong") | shells do easing curves (Back/Elastic), not real spring physics; real springs = GTK4 app-code (AdwSpringParams) only | tune KWin/Plasma easing to ~macOS 0.25s/0.5s feel; true springs = **ceiling** |
| 22 | True concentric widget corners | needs GTK/Qt cooperation per-app | Kvantum approximation only |

---

## Parity-pass order (the named surfaces)
1. **Dock** (icon48/float/glass) → 2. **Toolbar/window** (~50–52pt, 3-zone, traffic lights) →
3. **Settings window** (card9/row44/sel33/sidebar225–275) → 4. Menus → 5. Controls.
Each: live screenshot vs `corpus/screenshots/` reference → measure → tune tokens/Kvantum → repeat.

## Honest ceiling: ~95% of the desktop. The residual is #14, #20, #21, and bit-exact #16.

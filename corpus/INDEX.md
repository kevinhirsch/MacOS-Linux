# The Corpus — macOS Tahoe / Liquid Glass reference log

Exhaustive, self-contained record of **every** source, screenshot, extraction, script,
artifact, and derived value behind [`tokens/tahoe.json`](../tokens/tahoe.json). Nothing
lives only in a chat or a temp dir anymore — it's all here under `corpus/`.

> **Standing rule:** *when in doubt, the Apple HIG and Tahoe screenshots are the corpus.*
> The token values are measured/derived; the **rules** (in `tokens/tahoe.json` `rules[]`
> and `apple-hig/`) are the real payload.

- **172 files · 214 MB.** Every file is checksummed in [`MANIFEST.txt`](MANIFEST.txt).
- Provenance is tracked per token in `tokens/tahoe.json` (`conf` field). Current tally:

| Tier | Count | Meaning |
|---|---:|---|
| `apple` | 51 | Apple-documented / design-figure / HIG-stated |
| `figma-community` | 18 | Exact from the "macOS 26 (Community)" Figma kit (expert repro, not Apple-official) |
| `measured` | 17 | Our screenshot measurement @2× (see `analysis/`) |
| `estimate` | 8 | Reconstruction — the remaining soft spots |
| `derived` | 1 | Computed via the concentric rule |

---

## 1. Apple design knowledge — `apple-hig/`

The written corpus: Apple's Human Interface Guidelines Liquid Glass pages, developer
docs, and three WWDC25 transcripts, mirrored to Markdown (from the *orwell* design
export), plus ~40 HIG reference images. **9 MB, 73 files.**

### 1a. Synthesised reference docs — `apple-hig/liquid-glass/*.md`
| File | What |
|---|---|
| `LIQUID_GLASS_REFERENCE.md` | The master synthesis — optics, materials, the one-glass-plane law |
| `ADAPTIVE_LEGIBILITY_REFERENCE.md` | Dynamic ink: the light↔dark flip at relative-luminance ≈0.36 |
| `ELEMENT_KIT.md` | Per-component construction notes (windows, menus, sheets, controls) |
| `REFERENCE_MANIFEST.md` | The orwell export's own index of what it captured |
| `README.md` | orwell corpus entry point |
| `APPLE_GENIUS.md` | Broader Apple design-philosophy notes (`apple-hig/APPLE_GENIUS.md`) |

### 1b. Apple HIG / developer source docs — `apple-hig/liquid-glass/sources/` (30)
| File | Topic |
|---|---|
| `lg_text_lg_data_foundations.md` | Foundations — Liquid Glass overview |
| `lg_text_lg_data_materials.md` | Materials (ultraThin…ultraThick, Regular/Clear) |
| `lg_text_lg_data_layout.md` | Layout & spacing |
| `lg_text_lg_data_comp_color.md` | Color |
| `lg_text_lg_data_comp_typography.md` | Typography |
| `lg_text_lg_data_comp_dark-mode.md` | Dark Mode |
| `lg_text_lg_data_comp_accessibility.md` | Accessibility (Reduce Transparency/Motion, Increase Contrast) |
| `lg_text_lg_data_comp_motion.md` | Motion |
| `lg_text_lg_data_comp_right-to-left.md` | Right-to-left |
| `lg_text_lg_data_comp_buttons.md` | Buttons |
| `lg_text_lg_data_comp_menus.md` | Menus |
| `lg_text_lg_data_comp_the-menu-bar.md` | The menu bar |
| `lg_text_lg_data_comp_popovers.md` | Popovers |
| `lg_text_lg_data_comp_sheets.md` | Sheets |
| `lg_text_lg_data_comp_search-fields.md` | Search fields |
| `lg_text_lg_data_comp_tab-bars.md` | Tab bars |
| `lg_text_lg_data_comp_sidebars.md`, `..._components_sidebars.md` | Sidebars (two captures) |
| `lg_text_lg_data_comp_toolbars.md`, `..._components_toolbars.md` | Toolbars (two captures) |
| `lg_text_lg_data_comp_icons.md` | Icons |
| `lg_text_lg_data_comp_app-icons.md` | App icons (Icon Composer, layers, modes) |
| `lg_text_lg_data_adopting_liquidglass.md` | Adopting Liquid Glass |
| `lg_text_lg_data_techoverview_liquidglass.md` | Technology overview — Liquid Glass |
| `lg_text_applying_lg_custom.md` | Applying Liquid Glass to custom views |
| `lg_text_kube_liquid_glass_css_svg.md` | External technique: Liquid Glass via CSS/SVG |
| `lg_text_landmarks_app.md` | Apple *Landmarks* sample-app adoption notes |

### 1c. WWDC25 transcripts — `apple-hig/liquid-glass/sources/`
| File | Session (role in our corpus) |
|---|---|
| `lg_wwdc_219_transcript.md` | "Meet Liquid Glass" — the material's intent & optics |
| `lg_wwdc_310_appkit_new_design.md` | AppKit + the new design system (controls, sizing, tint prominence) |
| `lg_wwdc_356_transcript.md` | Shape geometry — fixed / capsule (r=h/2) / **concentric** (r=parent−inset) |

### 1d. HIG reference images — `apple-hig/liquid-glass/images/` (~40)
Apple's own figures: `lg_color_*` (correct/incorrect glass tint usage, light/dark),
`lg_hig_materials_*` (thin/regular/thick backgrounds), `lg_hig_toolbar_*` /
`lg_hig_sidebar_*` / `lg_hig_tab_bar_*` (before/after + grouping), `lg_hig_slider_*`,
`lg_hig_segmented_*`, `lg_nr_*` (newsroom hero/clear/dark-tint/Icon-Composer),
`macos_settings_tahoe.png`. Full list with checksums in `MANIFEST.txt`.

---

## 2. Screenshot measurement corpus — `screenshots/` (79 files, 180 MB)

Ground-truth pixels. Measured @2× (retina) with the scripts in `analysis/`.

| Set | Location | What |
|---|---|---|
| Aqua screenshot library | `screenshots/aqua-library/` | `26-Tahoe-*` — Finder, Settings, menus, alerts, Print, TextEdit, Control Center, Appearance. From 512pixels.net (see §7). Includes `-scaled` variants. |
| Curated captures | `screenshots/mine/` | ~60 shots — every **Settings-*** pane, apps (Calculator, Calendar, Contacts, Mail, Maps, Notes, Preview, Reminders, Safari, Activity Monitor, Disk Utility), Finder views, all 8 **Appearance accent** colors, Clear/Tinted styles, and `x_*` crops used for measurement |
| Misc references | `screenshots/` | `orig_*` (originals), `shot_finder/macstories/reddit` (third-party Tahoe shots), `t_*` (appearance/control/get-info/settings crops) |

Self-calibration: traffic-light diameter = 28 px @2× → 14 pt, giving ppt≈2.0 for every
other measurement (zero deviation across 27 windows).

---

## 3. Figma extraction — `figma/`

| File | What |
|---|---|
| `figma_file.json` | The **entire** "macOS 26 (Community)" file via Figma REST API — 25 MB, 42 pages, 1654 drop-shadows, 485 GLASS effects. The raw source for every `figma-community` token. |
| `figma-extract.md` | The distilled findings: shadow elevation system, material vibrancy ramp, radii, type ramp, and the Liquid-Glass parametric recipe (also at [`../parity/figma-extract.md`](../parity/figma-extract.md)). |

Note: the REST API returns the GLASS effect as `{"type":"GLASS"}` only — its params
(Refraction 100 / Depth 16 / Frost 7·12·14 / Splay 6 / Light −45°) were read off the
Figma **canvas** by hand; that is the sole source for them.

---

## 4. Analysis — `analysis/` (10 files)

| File | What |
|---|---|
| `measure.py`, `measure_chrome.py`, `measure_controls.py`, `measure_surfaces.py` | PIL/numpy pixel measurement (radii, chrome, controls, dock/toolbar/sidebar) |
| `dark_measure.py` | Dark-mode fill/selection sampling |
| `accent_diff.py`, `batch_mine.py` | Accent-palette diffing + batch screenshot crunching |
| `mining-results.json`, `accent-palette.json`, `tahoe-tokens.json` | Machine outputs the token file was built from |

---

## 5. Published artifacts — `artifacts/` (8 HTML)

Browsable deliverables built during the project (mirrored here; several were also
published as claude.ai Artifacts).

| File | What |
|---|---|
| `tahoe-calibration-sheet.html` / `tahoe-calibration.html` | The token source-of-truth, rendered |
| `liquid-glass-rulebook.html` | The load-bearing HIG laws |
| `liquid-glass-lab.html` | Live shader/optics playground calibrated to the tokens |
| `materials.html` | Material/vibrancy explorer |
| `tahoe-strategy.html` | Substrate strategy (why Plasma) |
| `tahoe-package-plan.html` | The package plan |
| `tahoe.html` | Combined reference |

---

## 6. Derived — the token ledger

[`../tokens/tahoe.json`](../tokens/tahoe.json) is the machine-readable source of truth
(9 dimensions: geometry, controls, layout, material, type, shadow, icon, motion, color;
plus `$meta` and `rules[]`). Every value carries a `conf` tier (§0) and often a `consumers` list naming
which layer reads it (`glass-effect`, `theme`, `gtk4-apps`). Consumed by:
`02-glass-effect/` (shader uniforms), `03-theme/` (Kvantum + color-schemes + Aurorae),
`04-configs/` (fonts, dock, menu).

---

## 7. External sources & tools (canonical URLs)

| Source | URL / identifier |
|---|---|
| Apple HIG — Materials / Liquid Glass | developer.apple.com/design/human-interface-guidelines/materials |
| WWDC25 — Meet Liquid Glass / AppKit new design / shape geometry | developer.apple.com/videos (sessions 219 · 310 · 356) |
| Aqua screenshot library (macOS 26 Tahoe) | 512pixels.net/projects/aqua-screenshot-library/macos-26-tahoe/ |
| Figma kit — "macOS 26 (Community)" | figma.com/design/OlF3YkJSK7K2bTOaAM7lir (key `OlF3YkJSK7K2bTOaAM7lir`) |
| ryohsuke1231/liquid-glass (GLSL optics, MIT) | github.com/ryohsuke1231/liquid-glass |
| Better Blur — kwin-effects-forceblur (GPL-2, the effect's base) | github.com/taj-ny/kwin-effects-forceblur |
| MacTahoe GTK theme (vinceliuice) | github.com/vinceliuice/MacTahoe-gtk-theme |
| MacTahoe KDE (Kvantum/Aurorae base) | github.com/vinceliuice/MacTahoe-kde |
| Prismal (evaluated for glass rendering) | github.com/styropyr0/Prismal |

---

## 8. Maintenance

- **Regenerate the manifest** after adding files:
  `cd corpus && find . -type f -not -name MANIFEST.txt | sort | while read f; do printf '%-72s %10d  %s\n' "${f#./}" "$(stat -c%s "$f")" "$(sha256sum "$f"|cut -c1-16)"; done > MANIFEST.txt`
- **Heavy binaries** (`screenshots/`, `figma/figma_file.json`) dominate the 214 MB. If
  this ever becomes a git repo, put them behind git-LFS or `.gitignore` and keep the
  text corpus + `MANIFEST.txt` versioned.
- The corpus is **append-only knowledge**; the package (`install.sh`, `0x-*`) is the
  implementation that reads `tokens/tahoe.json`. Keep the two concerns separate.

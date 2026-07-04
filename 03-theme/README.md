# 03-theme — macOS Tahoe · KDE Plasma 6 theme layer

Draft theme layer for the Tahoe "Liquid Glass" Plasma 6 package (2026). Everything here is
**based on** [`vinceliuice/MacTahoe-kde`](https://github.com/vinceliuice/MacTahoe-kde) and then
retuned to our calibration tokens (see `../tokens/`).

We do **not** fork the whole upstream repo. We install upstream once, then drop our overrides on
top. That keeps us rebaseable when upstream ships a new Tahoe revision.

## What upstream ships (verified against the repo, Jul 2026)

| Component            | Upstream path                                                | Installs to                                   |
|---------------------|---------------------------------------------------------------|-----------------------------------------------|
| Kvantum theme       | `Kvantum/MacTahoe/{MacTahoe,MacTahoeDark}.{kvconfig,svg}`      | `~/.config/Kvantum/MacTahoe/`                 |
| Aurorae decoration  | `aurorae/MacTahoe-{Light,Dark}[-1.25x/-1.5x]/decoration.svg` + `aurorae/{Light,Dark}rc` + `aurorae/icons-{Light,Dark}/*.svg` | `~/.local/share/aurorae/themes/MacTahoe-<Color>[<scale>]/` |
| Color schemes       | `color-schemes/MacTahoe{Light,Dark}.colors`                   | `~/.local/share/color-schemes/`               |
| Look-and-feel       | `plasma/look-and-feel/com.github.vinceliuice.MacTahoe-{Light,Dark}/` | `~/.local/share/plasma/look-and-feel/`  |
| Plasma desktoptheme | `plasma/desktoptheme/…`                                        | `~/.local/share/plasma/desktoptheme/`         |
| Wallpapers          | `wallpapers/MacTahoe{,-Light,-Dark}/` (3840x2160, day+dark)   | `~/.local/share/wallpapers/`                  |

Note the light Kvantum config is `MacTahoe.kvconfig` (`window.color=#f5f5f5`); the dark one is
`MacTahoeDark.kvconfig` (`window.color=#242424`). Both share the one `MacTahoe` Kvantum theme dir.

Upstream Aurorae already puts the traffic lights on the **left** (`LeftButtons=XIA`) at
`ButtonWidth=16 / ButtonSpacing=10`. Our job is to retune those metrics, not invent them.

## Files in this directory

- `install-base.sh` — clone + run upstream `install.sh` (light **and** dark, all scales), then
  apply our overrides. Idempotent.
- `kvantum/MacTahoe.kvconfig.override` + `MacTahoeDark.kvconfig.override` — the `[%General]` /
  `[GeneralColors]` / `[Hacks]` / control-metric keys we override on top of upstream. Merge, don't
  replace (see `apply-kvantum-overrides.sh`).
- `apply-kvantum-overrides.sh` — merges the override keys into the installed kvconfigs with
  `kwriteconfig6` (kvconfig is INI, so kwriteconfig6 edits it cleanly).
- `aurorae/Tahoe-Light-rc` + `Tahoe-Dark-rc` — full retuned Aurorae rc (traffic lights, left,
  14pt / 24pt / 26pt).
- `aurorae/apply-aurorae.sh` — installs the retuned rc over the upstream Aurorae theme and points
  KWin at it.
- `color-schemes/TahoeLight.colors`, `TahoeDark.colors`, `TahoeLight-Contrast.colors` — regenerated
  from our palette (accent / selection / focus mapped to Plasma roles).
- `color-schemes/install-colors.sh` — copies the `.colors` into place.

Radii like 16/20/26pt and 9pt live in the SVG geometry (Kvantum `.svg`, Aurorae `decoration.svg`),
not in kvconfig keys — Kvantum has **no** numeric `corner_radius` key. Where a radius is enforced by
config we say so; where it is baked into SVG we call out the SVG element to patch in
`SVG-RADII-NOTES.md`.

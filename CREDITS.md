# Credits & Third-Party Notices

The **code and configuration** in this repository are © its contributors and
licensed **GPL-3.0-or-later** (see [`LICENSE`](LICENSE)).

## Upstream projects this builds on
- **KWin "Better Blur"** (`taj-ny/kwin-effects-forceblur`) — GPL-2.0-or-later.
  [`02-glass-effect/`](02-glass-effect/) is a derivative work; its files are
  GPL-2.0-or-later (compatible with this repo's GPL-3.0-or-later).
- **ryohsuke1231/liquid-glass** — MIT. Snell/superellipse/Fresnel optics concepts,
  reimplemented here in GLSL for KWin.
- **MacTahoe** GTK & KDE themes (`vinceliuice`) — GPL-3.0. Used as the theme base
  (installed/cloned by `03-theme/install-base.sh`, not vendored here).

## Reference corpus (`corpus/`) — NOT licensed by this repo
`corpus/` bundles third-party reference material, included for research and
pixel-parity work only. It is **not** covered by this repo's license and remains
the property of its respective owners:

- `corpus/apple-hig/` — Apple Human Interface Guidelines text & figures, and WWDC
  transcripts — **© Apple Inc.**
- `corpus/screenshots/` — screenshots of the macOS Tahoe UI — **© Apple Inc.**;
  some sourced from the **512pixels.net** Aqua screenshot library.
- `corpus/figma/` — data extracted from the community "macOS 26" Figma file.

No copyright claim is made over any of the above, and their inclusion grants no
license to them. If you are a rights holder and want material removed, open an issue.

## Fonts
**SF Pro / SF Mono** are Apple's and are **not** redistributed here. The theme
falls back to Inter/Noto when they are absent; install Apple's fonts yourself for
exact typography.

## Aesthetic parity only
This project reproduces a *look*. It contains **no Apple code** and is not
affiliated with or endorsed by Apple Inc. "macOS", "Tahoe", "Liquid Glass", and
"SF Pro" are trademarks of Apple Inc.

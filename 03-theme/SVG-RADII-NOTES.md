# SVG radii notes — where the geometric corner radii actually live

Kvantum and Aurorae draw frames from **SVG tiles**, not from numeric radius keys. So the
calibration radii are enforced by editing SVG geometry, and kvconfig only sizes/spaces things.
This file records exactly which SVG element controls which token, so the retune is reproducible.

## Calibration radii → where they live

| Token                                  | Value  | Enforced by                                                                 |
|----------------------------------------|--------|------------------------------------------------------------------------------|
| Window radius — titlebar               | 16pt   | Aurorae `decoration.svg`, `#decoration-active-top{left,right}` corner tiles + `PaddingTop`/border geometry. Round the top corners of the active/inactive `top*` tiles to r=16. |
| Window radius — compact                | 20pt   | Aurorae `decoration.svg` alt corner set (used for tool/compact windows) — same tiles, r=20 variant if you ship a compact Aurorae. |
| Window radius — toolbar / unified head | 26pt   | Kvantum `.svg` `toolbar` element rounding + Aurorae `TitleHeight`/edge geometry. Round the `toolbar` frame tile to r=26. |
| Card radius                            | 9pt    | Kvantum `.svg` `group`/`frame` element (used by GroupBox, cards, list frames). Set the corner arcs of the `group` tile to r=9. |
| Control — button rounded               | 24pt h | height = kvconfig `min_height=24` ([PanelButtonTool]); corner = `.svg` `button` element arc. For a 24pt-tall pill, button arc r≈12. |
| Control — capsule                      | 28pt h | height = kvconfig `min_height=28` ([PanelButtonCommand]); capsule = fully rounded, `button` element arc r=14 (= height/2). |
| Min control                            | 28×20  | kvconfig `min_width=28 / min_height=20` where applicable. |
| Concentric radii                       | —      | Rule of thumb baked into the SVGs: inner_r = outer_r − padding. When editing a nested frame (e.g. a selected row inside a 9pt card with 3px inset), draw the inner arc at r=6 so the gap is visually constant. Keep this relationship when regenerating tiles. |
| Scrollbar groove                       | 15pt   | width = kvconfig `scroll_width=15`; the groove/handle rounding is the `.svg` `scrollbarslidercursor` element (fully rounded → r = 15/2 ≈ 7). |
| Menu item                              | 24pt   | height = kvconfig [MenuItem] `min_height=24`; selected-item highlight rounding = `.svg` `menuitem` element (r≈6, concentric inside the menu's own radius). |

## How to edit the SVGs

Upstream ships `Kvantum/MacTahoe/MacTahoe.svg` (light) and `MacTahoeDark.svg` (dark), and
`aurorae/MacTahoe-<Color>[<scale>]/decoration.svg`. They are Inkscape SVGs with named
`id="…"` elements matching Kvantum's element names (`button`, `toolbar`, `group`, `menuitem`,
`scrollbarslidercursor`, …) and Aurorae's `decoration-{active,inactive}-{top,topleft,…}`.

Recommended flow (kept out of this draft — it is a graphics pass, not a config pass):

1. Open the `.svg` in Inkscape, select the tile by id, edit its corner arc radius, re-export
   keeping the same id and viewBox.
2. Re-run `kvantummanager --set MacTahoe` (or just re-log) so Kvantum re-reads the tiles.
3. For Aurorae, bump `X-KDE-PluginInfo-Version` in `metadata.desktop` so KWin drops its SVG cache,
   then reload the decoration.

Everything a config file *can* control is already in the `.kvconfig.override` and Aurorae `rc`
files in this directory. This note is the boundary line: radii = SVG, sizes/spacing/colors = config.

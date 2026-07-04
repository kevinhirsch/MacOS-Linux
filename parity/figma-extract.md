# Figma extraction — "macOS 26 (Community)" (file OlF3YkJSK7K2bTOaAM7lir, 42 pages)
# Confidence: figma-community (expert reproduction, NOT Apple's official file). Strong reference.
# GLASS params come from BROWSER (REST API returns {"type":"GLASS"} only). Everything else = REST API (exact).
# Extracted 2026-07-03.

## TYPE RAMP  (SF Pro; size/lineHeight px; weight; tracking 0 everywhere)  — CONFIRMS existing tokens
Large Title 26/32   w400 / Emph w700
Title 1     22/26   w400 / Emph w700
Title 2     17/22   w400 / Emph w700
Title 3     15/20   w400 / Emph w590
Headline    13/16   w700 / Emph w860
Body        13/16   w400 / Emph w590
Callout     12/15   w400 / Emph w590
Subheadline 11/14   w400 / Emph w590
Footnote    10/13   w400 / Emph w590
Caption 1   10/13   w400 / Emph w510
Caption 2   10/13   w510 / Emph w590
(XLTitle1   48/56   w700  — cover only, non-standard)
# weights: Regular=400, Medium=510, Semibold=590, Bold=700, Heavy=860

## MATERIALS — vibrancy levels (tint + 30px backdrop blur, constant)
Light (tint #F6F6F6):  Ultrathin 36% · Thin 48% · Medium 60% · Thick 72% · Ultrathick 84%
Dark  (tint #000000):  Ultrathin 10% · Thin 20% · Medium 29% · Thick 40% · Ultrathick 50%
blur = 30px for all.

## LIQUID GLASS — Figma native "Glass" effect (params only from BROWSER; API hides them)
CONSTANT: Light -45°/67% · Refraction 100 · Depth 16 · Dispersion 0 · Splay 6
FROST scales w/ element size:  Small(48,capsule) 7 · Medium(160,r34) 12 · Large(160,r34) 14
Medium/Light tint: #F5F5F5@67% over #262626@100%; glass-layer fill #000@20%; elem shadow 0/8/40 #000@12%
Used in 485 places across the file.
# shader map: Refraction→IOR bend, Depth→thickness, Dispersion→chromatic aberration,
#             Splay→edge spread, Frost→backdrop blur px, Light→specular angle/intensity

## SHADOW ELEVATION SYSTEM  (x/y/blur/spread  color@alpha)
# recurring ambient card shadow  ("Fill + Shadow" everywhere): drop 0/8/40/0 #000@12%
Window (Titlebar)  r16  : drop 0/16/48/0 #000@35%  + contour 0/0/0/1 #000@23%
Sheet              r26  : drop 0/16/48/0 #000@35%  + contour 0/0/0/1 #000@23%
Dialog             r26  : drop 0/16/48/0 #000@35%  + contour 0/0/0/1 #000@23%
Alert (modal)      r26  : drop 0/17/45/0 #000@50%  + contour 0/0/1/0 #000@20%  (+ambient 0/8/40 @12%)
Menu               r13  : drop 0/0/25/0 #000@16%   + 0/0/2/0 #000@10%
Popover            r20  : drop 0/8/15/6 #000@18%   + 0/2/4/0 #000@15%  + INNER 0/0.5/1/0.5 #FFF@50% (top edge highlight)
Notification banner r16 : drop 0/8/40/0 #000@12%
Sidebar card       r18  : drop 0/8/40/0 #000@12%
Dock               r15  : contour 0/0/0/1 #000@20% + soft 0/0/6/0 #000@15%
Tooltip            r1?  : drop 0/1/3/0 #000@20%   (r1 suspicious — low conf)
Toolbar button    capsule: focus ring #007AFF 0/0/0/3.5 @25%  + 0/0/0/1 @15%

## COLORS
accent/tint blue : #007AFF   (from focus ring)
system gray      : #98989D
black / label    : #000000
focus ring       : #007AFF  double: 3.5px spread @25% + 1px spread @15%

## RADII SUMMARY (pt)
window/titlebar 16 · sheet 26 · dialog 26 · alert 26 · popover 20 · menu 13 · notification 16 ·
sidebar-card 18 · dock 15 · glass-medium/large 34 · glass-small capsule · toolbar-button capsule
# NB: earlier token had sheet=20; kit says 26. window=16 confirmed.

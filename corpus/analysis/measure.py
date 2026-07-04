#!/usr/bin/env python3
"""Measure Tahoe UI metrics off a real screenshot, self-calibrated by the
known 14pt window-control ('traffic light') diameter."""
import numpy as np
from PIL import Image
import sys

path = sys.argv[1] if len(sys.argv) > 1 else 'shot_finder.jpg'
im = np.asarray(Image.open(path).convert('RGB')).astype(int)
H, W, _ = im.shape
R, G, B = im[:, :, 0], im[:, :, 1], im[:, :, 2]
print(f"image {path}: {W}x{H}")

# --- locate the window (dominant bright region) ---
bright = (R > 200) & (G > 200) & (B > 200)
colsum, rowsum = bright.sum(0), bright.sum(1)
xs = np.where(colsum > colsum.max() * 0.30)[0]
ys = np.where(rowsum > rowsum.max() * 0.30)[0]
wx0, wx1, wy0, wy1 = xs.min(), xs.max(), ys.min(), ys.max()
print(f"window bbox: x[{wx0}..{wx1}] y[{wy0}..{wy1}]  ({wx1-wx0}x{wy1-wy0})")

# --- traffic lights: search the window's top-left band ---
def mask(t, tol=48):
    return (np.abs(R-t[0])<tol)&(np.abs(G-t[1])<tol)&(np.abs(B-t[2])<tol)
bx1 = wx0 + int(0.28*(wx1-wx0)); by1 = wy0 + int(0.16*(wy1-wy0))
band = np.zeros((H, W), bool); band[wy0:by1, wx0:bx1] = True
targets = {'red':(236,106,95), 'yellow':(245,190,80), 'green':(95,197,90)}
dots = {}
for name, t in targets.items():
    m = mask(t) & band
    ycs, xcs = np.where(m)
    if len(xcs) < 20:
        print(f"  {name}: not found ({len(xcs)} px)"); continue
    cx, cy = int(np.median(xcs)), int(np.median(ycs))
    # diameter = span of matched px through the center row/col
    dw = mask(t)[cy, :]; run = np.where(dw[max(0,cx-40):cx+40])[0]
    diam = (run.max()-run.min()+1) if len(run) else 0
    dots[name] = (cx, cy, diam)
    print(f"  {name}: center=({cx},{cy}) diameter~{diam}px  px={len(xcs)}")

# --- scale from 14pt diameter ---
if len(dots) == 3:
    diam_px = np.mean([d[2] for d in dots.values()])
    ppt = diam_px / 14.0
    print(f"\nmean traffic-light diameter: {diam_px:.1f}px  ->  {ppt:.2f} px/pt (14pt anchor)")
    rc, yc, gc = dots['red'], dots['yellow'], dots['green']
    sp1 = abs(yc[0]-rc[0]); sp2 = abs(gc[0]-yc[0])
    print(f"spacing red->yellow: {sp1}px = {sp1/ppt:.1f}pt | yellow->green: {sp2}px = {sp2/ppt:.1f}pt")
    # inset from window outer edge (measure outer-left at the traffic-light row)
    row = bright[rc[1], max(0,wx0-30):rc[0]]
    outer_left = np.where(row)[0]
    olx = (outer_left.min()+max(0,wx0-30)) if len(outer_left) else wx0
    print(f"red-center inset from window left edge: {rc[0]-olx}px = {(rc[0]-olx)/ppt:.1f}pt")
    print(f"traffic-light vertical center from window top: {rc[1]-wy0}px = {(rc[1]-wy0)/ppt:.1f}pt")

    # --- window outer corner radius (top-left) ---
    leftmost = []
    for y in range(wy0, min(wy0+160, H)):
        seg = bright[y, max(0,wx0-8):wx0+220]
        idx = np.where(seg)[0]
        leftmost.append(idx.min()+max(0,wx0-8) if len(idx) else np.nan)
    leftmost = np.array(leftmost, float)
    x_straight = np.nanmin(leftmost[60:160])
    indent = leftmost[0] - x_straight                      # x method
    reach = next((i for i,v in enumerate(leftmost) if v <= x_straight+2), np.nan)  # y method
    print(f"\ncorner radius (x-indent): {indent:.0f}px = {indent/ppt:.1f}pt")
    print(f"corner radius (y-reach):  {reach:.0f}px = {reach/ppt:.1f}pt")

    # --- menu bar: vertical extent of top status/menu row ---
    # menu bar is transparent; estimate height from top to where wallpaper-only begins
    # measure using the top-right clock text band isn't robust; report scale note instead
    print(f"\n(scale note: 1pt = {ppt:.2f}px in this capture)")

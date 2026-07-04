#!/usr/bin/env python3
import numpy as np
from PIL import Image
im = np.asarray(Image.open('orig_26-Tahoe-Settings-General.png').convert('RGB')).astype(int)
H, W, _ = im.shape
R, G, B = im[:, :, 0], im[:, :, 1], im[:, :, 2]

def cmask(t, tol=48): return (np.abs(R-t[0])<tol)&(np.abs(G-t[1])<tol)&(np.abs(B-t[2])<tol)
band = np.zeros((H, W), bool); band[70:260, 110:420] = True
diam = []
for t in [(236,106,95),(245,190,80),(95,197,90)]:
    m = cmask(t)&band; ys, xs = np.where(m)
    if len(xs) > 20:
        cy = int(np.median(ys)); run = np.where(cmask(t)[cy])[0]; diam.append(run.max()-run.min()+1)
ppt = np.mean(diam)/14.0
print(f"scale: {ppt:.2f} px/pt")

# --- selection pill: rows with a LONG contiguous blue run (fill), not icons ---
blue = (R<115)&(G>75)&(G<180)&(B>195)
runlen = np.zeros(H, int); runx0 = np.zeros(H, int)
for y in range(H):
    idx = np.where(blue[y, :560])[0]
    if len(idx):
        segs = np.split(idx, np.where(np.diff(idx) > 1)[0]+1)
        longest = max(segs, key=len); runlen[y] = len(longest); runx0[y] = longest[0]
pill_rows = np.where(runlen > 180)[0]
py0, py1 = pill_rows.min(), pill_rows.max()
midy = (py0+py1)//2
midrow = np.where(blue[midy, :560])[0]
sx = int(np.median(midrow))
r, g, b = im[midy, sx]
print(f"\nsidebar selection pill: height {py1-py0}px = {(py1-py0)/ppt:.1f}pt")
print(f"  accent (solid fill sample): rgb({r},{g},{b}) = #{r:02X}{g:02X}{b:02X}   (token #007AFF)")
# corner radius of the pill (left edge indent over the rounded top)
lefts = runx0[py0:py1+1].astype(float)
xstr = lefts.min()
r_pill = next((i for i, v in enumerate(lefts) if v <= xstr+1), np.nan)
print(f"  pill corner radius ~{r_pill/ppt:.1f}pt  (height/2 = {(py1-py0)/2/ppt:.1f}pt => fully rounded if equal)")

# --- grouped content card corner radius (relaxed white threshold) ---
card = (R>243)&(G>243)&(B>243); card[:, :600] = False
cols = card.sum(0); cx0 = np.where(cols > cols.max()*0.25)[0].min()
ytop = None
for y in range(170, H):
    if card[y, cx0:cx0+400].sum() > 150: ytop = y; break
if ytop:
    leftw = []
    for y in range(ytop, min(ytop+140, H)):
        idx = np.where(card[y, max(0,cx0-6):cx0+320])[0]
        leftw.append(idx.min()+max(0,cx0-6) if len(idx) else np.nan)
    leftw = np.array(leftw, float); xw = np.nanmin(leftw[60:140])
    r_card = next((i for i, v in enumerate(leftw) if v <= xw+1), np.nan)
    print(f"\ngrouped card corner radius ~{r_card/ppt:.1f}pt")
else:
    print("\ngrouped card: not isolated")

# --- list-row pitch via row icons (dark glyphs in a strip at card-left) ---
sx0 = cx0 + 15
strip = im[:, sx0:sx0+55, :].mean(2)
darks = strip.min(1) < 175
centers = []; y = 400
while y < H-1:
    if darks[y]:
        y0 = y
        while y < H-1 and darks[y]: y += 1
        if y-y0 > ppt*6: centers.append((y0+y)//2)   # icon-sized dark blob
    else: y += 1
if len(centers) >= 3:
    p = np.diff(centers[:6])
    print(f"list-row pitch: {list(p)}px  median {np.median(p)/ppt:.1f}pt")

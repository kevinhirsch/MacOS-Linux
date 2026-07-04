#!/usr/bin/env python3
import numpy as np, glob, os
from PIL import Image

files = sorted(glob.glob('mine/Apperance-Light-*.png'))
ims = [np.asarray(Image.open(f).convert('RGB')) for f in files]
minh = min(im.shape[0] for im in ims); minw = min(im.shape[1] for im in ims)
ims = [im[:minh, :minw].astype(int) for im in ims]
stack = np.stack(ims)                       # (N,H,W,3)
# pixels that VARY across accent settings = the accent-colored UI
var = stack.std(0).mean(2)
mask = var > 22
print(f"{len(files)} accent samples, {mask.sum()} accent-varying pixels\n")
print("accent palette (median of accent-colored pixels per sample):")
pal = {}
for f, im in zip(files, ims):
    px = im[mask]
    sat = px.max(1) - px.min(1)
    sel = px[sat > 45]                       # keep the saturated fill, drop greys
    if len(sel) < 50:
        print(f"  {os.path.basename(f)[:-4]:26s} (too few)"); continue
    med = np.median(sel, 0).astype(int)
    name = os.path.basename(f)[:-4].replace('Apperance-Light-','')
    pal[name] = '#%02X%02X%02X' % tuple(med)
    print(f"  {name:12s} {pal[name]}   rgb{tuple(med)}")
import json; json.dump(pal, open('accent-palette.json','w'), indent=1)

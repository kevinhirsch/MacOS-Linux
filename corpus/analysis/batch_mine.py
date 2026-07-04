#!/usr/bin/env python3
import numpy as np, glob, os, json
from PIL import Image

def load(p):
    im = np.asarray(Image.open(p).convert('RGB')).astype(int)
    return im, im[:,:,0], im[:,:,1], im[:,:,2]

def cmask(R,G,B,t,tol=50): return (np.abs(R-t[0])<tol)&(np.abs(G-t[1])<tol)&(np.abs(B-t[2])<tol)

def measure_window(p):
    im,R,G,B = load(p); H,W,_ = im.shape
    bright = (R>200)&(G>200)&(B>200)
    cs, rs = bright.sum(0), bright.sum(1)
    if cs.max()==0: return None
    xs = np.where(cs>cs.max()*0.30)[0]; ys = np.where(rs>rs.max()*0.30)[0]
    if len(xs)<5 or len(ys)<5: return None
    wx0,wx1,wy0,wy1 = xs.min(),xs.max(),ys.min(),ys.max()
    # traffic lights in top-left band
    band = np.zeros((H,W),bool)
    band[wy0:wy0+int(0.18*(wy1-wy0)), wx0:wx0+int(0.30*(wx1-wx0))] = True
    dots={}
    for name,t in {'r':(236,106,95),'y':(245,190,80),'g':(95,197,90)}.items():
        m=cmask(R,G,B,t)&band; yc,xc=np.where(m)
        if len(xc)<20: continue
        cx,cy=int(np.median(xc)),int(np.median(yc))
        run=np.where(cmask(R,G,B,t)[cy, max(0,cx-40):cx+40])[0]
        dots[name]=(cx,cy,(run.max()-run.min()+1) if len(run) else 0)
    if len(dots)<3: return None
    diam=np.mean([d[2] for d in dots.values()]); ppt=diam/14.0
    if ppt<1.2 or ppt>2.6: return None
    sp=(abs(dots['y'][0]-dots['r'][0])+abs(dots['g'][0]-dots['y'][0]))/2/ppt
    row=bright[dots['r'][1], max(0,wx0-30):dots['r'][0]]; ol=np.where(row)[0]
    olx=(ol.min()+max(0,wx0-30)) if len(ol) else wx0
    inset=(dots['r'][0]-olx)/ppt
    # corner radius
    lm=[]
    for y in range(wy0, min(wy0+170,H)):
        seg=bright[y, max(0,wx0-8):wx0+240]; idx=np.where(seg)[0]
        lm.append(idx.min()+max(0,wx0-8) if len(idx) else np.nan)
    lm=np.array(lm,float); xstr=np.nanmin(lm[70:170])
    reach=next((i for i,v in enumerate(lm) if v<=xstr+2), np.nan)
    return dict(ppt=round(ppt,2), diam_pt=round(diam/ppt,1), spacing_pt=round(sp,1),
                inset_pt=round(inset,1), corner_pt=round(reach/ppt,1) if reach==reach else None)

def measure_accent(p):
    im,R,G,B = load(p); H,W,_ = im.shape
    sat = (np.maximum(np.maximum(R,G),B)-np.minimum(np.minimum(R,G),B))
    colored = (sat>45) & (np.maximum(np.maximum(R,G),B)>110)
    best=None
    for y in range(H):
        idx=np.where(colored[y, :600])[0]
        if len(idx)<180: continue
        segs=np.split(idx, np.where(np.diff(idx)>1)[0]+1)
        longest=max(segs,key=len)
        if len(longest)>180:
            best=(y, int(np.median(longest))); break
    if not best: return None
    y,x=best; r,g,b=im[y,x]
    return '#%02X%02X%02X'%(r,g,b)

WIN, ACC = [], {}
for p in sorted(glob.glob('mine/*.png')):
    name=os.path.basename(p)[:-4]
    if name.startswith('Apperance'):
        h=measure_accent(p)
        if h: ACC[name.replace('Apperance-Light-','').replace('Apperance-Style-','')]=h
    else:
        m=measure_window(p)
        if m: m['name']=name; WIN.append(m)

def stats(key):
    v=[w[key] for w in WIN if w.get(key) is not None]
    return (round(np.mean(v),1), round(np.std(v),1), round(np.median(v),1), len(v), min(v), max(v))

print(f"=== windows measured: {len(WIN)} ===")
for k in ['diam_pt','spacing_pt','inset_pt','ppt']:
    m,s,md,n,lo,hi=stats(k)
    print(f"  {k:11s} mean {m}  median {md}  std {s}  (n={n}, range {lo}-{hi})")
print("  corner_pt distribution:", sorted([w['corner_pt'] for w in WIN if w.get('corner_pt')]))
print(f"\n=== accent palette (selection-fill hex) ===")
for k,v in sorted(ACC.items()): print(f"  {k:16s} {v}")

json.dump({'windows':WIN,'accents':ACC}, open('mining-results.json','w'), indent=1)
print("\nsaved mining-results.json")

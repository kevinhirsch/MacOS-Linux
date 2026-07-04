#!/usr/bin/env python3
import numpy as np
from PIL import Image

def load(p):
    im=np.asarray(Image.open(p).convert('RGB')).astype(int)
    return im, im[:,:,0], im[:,:,1], im[:,:,2]
def cmask(R,G,B,t,tol=50): return (np.abs(R-t[0])<tol)&(np.abs(G-t[1])<tol)&(np.abs(B-t[2])<tol)

def traffic(im,R,G,B):
    H,W,_=im.shape
    bright=(R>195)&(G>195)&(B>195); cs,rs=bright.sum(0),bright.sum(1)
    xs=np.where(cs>cs.max()*0.30)[0]; ys=np.where(rs>rs.max()*0.30)[0]
    wx0,wx1,wy0,wy1=xs.min(),xs.max(),ys.min(),ys.max()
    band=np.zeros((H,W),bool); band[wy0:wy0+int(0.16*(wy1-wy0)),wx0:wx0+int(0.28*(wx1-wx0))]=True
    diam=[]; red=None
    for name,t in [('r',(236,106,95)),('y',(245,190,80)),('g',(95,197,90))]:
        m=cmask(R,G,B,t)&band; yc,xc=np.where(m)
        if len(xc)<20: continue
        cx,cy=int(np.median(xc)),int(np.median(yc))
        run=np.where(cmask(R,G,B,t)[cy,max(0,cx-40):cx+40])[0]; diam.append(run.max()-run.min()+1)
        if name=='r': red=(cx,cy)
    return (np.mean(diam)/14.0 if len(diam)==3 else 2.0),(wx0,wx1,wy0,wy1),red

print("#### DOCK + TOOLBAR + SIDEBAR from shot_finder.jpg ####")
im,R,G,B=load('shot_finder.jpg'); H,W,_=im.shape
ppt,(wx0,wx1,wy0,wy1),red=traffic(im,R,G,B)
print(f"image {W}x{H}  ppt={ppt:.2f}")

# --- DOCK: bottom band, colored icon blobs inside a translucent bar ---
b0=int(0.86*H); band=im[b0:,:]; sat=band.max(2)-band.min(2)
colored=(sat>55)&(band.max(2)>90)
colcount=colored.sum(0)
active=np.where(colcount>colcount.max()*0.15)[0]
if len(active):
    dx0,dx1=active.min(),active.max()
    # dock bar vertical extent: rows in the dock x-range that are non-wallpaper (brighter/translucent)
    dcol=im[b0:, dx0:dx1].mean(2); rowvar=dcol.std(1)
    # icons: count peaks in colcount across the dock
    prof=colcount[dx0:dx1]; thr=prof.max()*0.35
    on=prof>thr; edges=np.diff(on.astype(int))
    starts=np.where(edges==1)[0]; ends=np.where(edges==-1)[0]
    n=min(len(starts),len(ends))
    if n>=3:
        centers=[(starts[i]+ends[i])/2+dx0 for i in range(n)]
        widths=[ends[i]-starts[i] for i in range(n)]
        pitch=np.median(np.diff(centers))
        print(f"  dock: {n} icon blobs, width~{np.median(widths):.0f}px={np.median(widths)/ppt:.0f}pt, pitch {pitch:.0f}px={pitch/ppt:.0f}pt, span {(dx1-dx0)/ppt:.0f}pt")
    # dock bar corner radius (top-left of the dock rect): detect the translucent bar top edge
    # the bar is brighter than wallpaper; find its top row
    barmask=(im[:, (dx0+dx1)//2-100:(dx0+dx1)//2+100].mean(2)>120)
    col=barmask.sum(1)
    dtop=next((y for y in range(H-1,b0-40,-1) if col[y]<50), b0)  # first dark row scanning up = bar top
    print(f"  dock bar height ~{(H-8-dtop)/ppt:.0f}pt (approx, translucent-edge)")

# --- TOOLBAR height: window top to first content divider (below traffic lights) ---
if red:
    # scan a column just right of traffic lights, downward, for the toolbar/content boundary
    x=wx0+int(0.5*(wx1-wx0)); colprof=im[wy0:wy0+300, x].mean(1)
    # toolbar is light; content list starts where a horizontal divider/row appears
    th=2*(red[1]-wy0)
    print(f"  toolbar height ~{th/ppt:.0f}pt (traffic-center proxy)")
# --- SIDEBAR width: sustained white content start at mid-height ---
white=(R>247)&(G>247)&(B>247); midy=(wy0+wy1)//2
idx=np.where(white[midy, wx0+30:wx1])[0]
if len(idx):
    segs=np.split(idx,np.where(np.diff(idx)>6)[0]+1); lo=max(segs,key=len)
    sw=lo[0]+wx0+30-wx0
    print(f"  sidebar width ~{sw/ppt:.0f}pt (white-content-start)")

print("#### SETTINGS SIDEBAR from orig_26-Tahoe-Settings-General.png ####")
im,R,G,B=load('orig_26-Tahoe-Settings-General.png'); H,W,_=im.shape
ppt2,(wx0,wx1,wy0,wy1),_=traffic(im,R,G,B)
white=(R>248)&(G>248)&(B>248)
# content cards start where the first TALL white column begins (right of sidebar)
colwhite=white[wy0:wy1, :].sum(0)
tall=np.where(colwhite>(wy1-wy0)*0.4)[0]
tall=tall[tall>wx0+40]
if len(tall):
    content_x0=tall.min(); sw=(content_x0-wx0)/ppt2
    print(f"  settings sidebar width ~{sw:.0f}pt (content-card left edge)")

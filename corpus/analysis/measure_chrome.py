#!/usr/bin/env python3
import numpy as np
from PIL import Image

def load(p):
    im=np.asarray(Image.open(p).convert('RGB')).astype(int)
    return im, im[:,:,0], im[:,:,1], im[:,:,2]
def cmask(R,G,B,t,tol=50):
    return (np.abs(R-t[0])<tol)&(np.abs(G-t[1])<tol)&(np.abs(B-t[2])<tol)

def traffic(im,R,G,B):
    H,W,_=im.shape
    bright=(R>200)&(G>200)&(B>200)
    cs,rs=bright.sum(0),bright.sum(1)
    xs=np.where(cs>cs.max()*0.30)[0]; ys=np.where(rs>rs.max()*0.30)[0]
    wx0,wx1,wy0,wy1=xs.min(),xs.max(),ys.min(),ys.max()
    band=np.zeros((H,W),bool); band[wy0:wy0+int(0.18*(wy1-wy0)),wx0:wx0+int(0.30*(wx1-wx0))]=True
    diam=[];reds=None
    for name,t in [('r',(236,106,95)),('y',(245,190,80)),('g',(95,197,90))]:
        m=cmask(R,G,B,t)&band; yc,xc=np.where(m)
        if len(xc)<20: continue
        cx,cy=int(np.median(xc)),int(np.median(yc))
        run=np.where(cmask(R,G,B,t)[cy,max(0,cx-40):cx+40])[0]
        diam.append(run.max()-run.min()+1)
        if name=='r': reds=(cx,cy)
    ppt=np.mean(diam)/14.0 if len(diam)==3 else 2.0
    return ppt,(wx0,wx1,wy0,wy1),reds

def corner_radius(mask, x0, y0, ppt, depth=170, wide=300):
    """rounded-rect top-left corner radius from a boolean region mask."""
    H,W=mask.shape
    lm=[]
    for y in range(y0, min(y0+depth,H)):
        seg=mask[y, max(0,x0-8):x0+wide]; idx=np.where(seg)[0]
        lm.append(idx.min()+max(0,x0-8) if len(idx) else np.nan)
    lm=np.array(lm,float)
    if np.all(np.isnan(lm)): return None
    xstr=np.nanmin(lm[60:depth])
    reach=next((i for i,v in enumerate(lm) if v<=xstr+2), np.nan)
    return reach/ppt if reach==reach else None

print("="*54)
im,R,G,B=load('mine/x_Finder-Home.png'); H,W,_=im.shape
ppt,(wx0,wx1,wy0,wy1),red=traffic(im,R,G,B)
print(f"FINDER-HOME {W}x{H}  ppt={ppt:.2f}  window x[{wx0}-{wx1}] y[{wy0}-{wy1}]")
# sidebar width: mid-height, first sustained WHITE run = content start
white=(R>243)&(G>243)&(B>243)
midy=(wy0+wy1)//2
idx=np.where(white[midy, wx0:wx1])[0]
if len(idx):
    segs=np.split(idx,np.where(np.diff(idx)>4)[0]+1)
    longest=max(segs,key=len); content_x0=longest[0]+wx0
    sw=content_x0-wx0
    print(f"  sidebar width : {sw}px = {sw/ppt:.1f}pt")
# toolbar height: 2 x (traffic-light center from window top)
if red:
    th=2*(red[1]-wy0)
    print(f"  toolbar height: {th}px = {th/ppt:.1f}pt  (traffic-center proxy, approx)")

print("="*54)
im,R,G,B=load('mine/x_Mail-Warning.png'); H,W,_=im.shape
ppt2=2.0
# the alert card = brightest large region; parent is dimmed
bright=(R>235)&(G>235)&(B>235)
cs,rs=bright.sum(0),bright.sum(1)
xs=np.where(cs>cs.max()*0.35)[0]; ys=np.where(rs>rs.max()*0.35)[0]
cx0,cy0=xs.min(),ys.min()
print(f"MAIL-WARNING sheet {W}x{H}  ppt~{ppt2}  card top-left ({cx0},{cy0})")
r=corner_radius(bright,cx0,cy0,ppt2,depth=120,wide=250)
print(f"  sheet corner radius: {r:.1f}pt" if r else "  sheet corner: n/a")

print("="*54)
im,R,G,B=load('mine/x_Go-Menu.png'); H,W,_=im.shape
ppt3=2.0
# menu = a locally-bright, low-variance rounded rect in the upper-left area
# detect: bright-ish (blurred light material) region, exclude very top (menu bar)
sub=im[40:H//2, :W//2]
br=(sub[:,:,0]>150)&(sub[:,:,1]>150)&(sub[:,:,2]>150)
cs,rs=br.sum(0),br.sum(1)
if cs.max()>0 and rs.max()>0:
    xs=np.where(cs>cs.max()*0.5)[0]; ys=np.where(rs>rs.max()*0.5)[0]
    mx0,mx1,my0,my1=xs.min(),xs.max(),ys.min()+40,ys.max()+40
    print(f"GO-MENU {W}x{H}  ppt~{ppt3}  menu bbox x[{mx0}-{mx1}] y[{my0}-{my1}] ({(mx1-mx0)/ppt3:.0f}x{(my1-my0)/ppt3:.0f}pt)")
    r=corner_radius(br,xs.min(),ys.min(),ppt3,depth=90,wide=200)
    print(f"  menu corner radius: {r:.1f}pt (approx)" if r else "  menu corner: n/a")
    # item pitch: dark text rows within menu band
    band=im[my0:my1, mx0+20:mx1-20].mean(2)
    dark=(band<120).sum(1)  # count dark(text) px per row
    rows=np.where(dark>8)[0]
    if len(rows)>4:
        # cluster into text rows, measure centroid pitch
        groups=np.split(rows,np.where(np.diff(rows)>6)[0]+1)
        centers=[int(np.mean(g))+my0 for g in groups if len(g)>1]
        if len(centers)>=3:
            p=np.diff(centers[:8])
            print(f"  menu item pitch: {list(p)}px  median {np.median(p)/ppt3:.1f}pt (approx)")

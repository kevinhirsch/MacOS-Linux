import numpy as np
from PIL import Image
im = np.asarray(Image.open('mine/x_Apperance-Style-Dark.png').convert('RGB')).astype(int)
H,W,_=im.shape; R,G,B=im[:,:,0],im[:,:,1],im[:,:,2]
# selection pill = longest horizontal saturated-blue run
blue=(B>110)&(B-R>40)&(B-G>25)&(R<150)
best=(0,0,0)
for y in range(H):
    idx=np.where(blue[y])[0]
    if len(idx)<120: continue
    segs=np.split(idx,np.where(np.diff(idx)>1)[0]+1)
    lo=max(segs,key=len)
    if len(lo)>best[0]: best=(len(lo),y,int(np.median(lo)))
if best[0]:
    ln,y,x=best; r,g,b=im[y,x]
    print(f"dark selection fill: run {ln}px  rgb({r},{g},{b}) = #{r:02X}{g:02X}{b:02X}")
    # sample a dark card/content patch: 200px right of the pill, neutral dark
    for dx in (250,400,550):
        px=x+dx
        if px<W:
            patch=im[y-4:y+4, px-8:px+8].reshape(-1,3)
            m=patch.mean(0).astype(int); sat=int(max(m)-min(m))
            if sat<14:
                print(f"  dark card/content bg near pill: rgb{tuple(m)} = #{m[0]:02X}{m[1]:02X}{m[2]:02X}"); break
# dark sidebar bg: sample a neutral dark patch left of the pill
px=max(0,x-60)
patch=im[y-30:y+30, px-10:px+10].reshape(-1,3); m=patch.mean(0).astype(int)
print(f"  dark sidebar bg (left of pill): rgb{tuple(m)} = #{m[0]:02X}{m[1]:02X}{m[2]:02X}")

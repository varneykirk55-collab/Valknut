"""Cuts legend frames out of the source sheets in valknut/art/source (baked checkerboard
backgrounds keyed out, label text and neighbouring frames dropped)."""
from PIL import Image
from collections import deque
import os
# Run from the repo root's tools/ folder; writes raw_<frame>.png into the working dir.
U=os.path.join(os.path.dirname(os.path.abspath(__file__)),'..','valknut','art','source')+'/'

def is_bg(c, maxv):
    r,g,b=c[:3]
    return max(r,g,b)<=maxv and max(r,g,b)-min(r,g,b)<=9

def key(im, maxv):
    """Flood-fill neutral dark checker pixels from the region border to transparent."""
    im=im.convert('RGBA'); w,h=im.size; px=im.load()
    seen=bytearray(w*h); q=deque()
    for x in range(w): q.append((x,0)); q.append((x,h-1))
    for y in range(h): q.append((0,y)); q.append((w-1,y))
    while q:
        x,y=q.popleft(); i=y*w+x
        if seen[i]: continue
        seen[i]=1
        if not is_bg(px[x,y],maxv): continue
        px[x,y]=(0,0,0,0)
        for nx,ny in ((x+1,y),(x-1,y),(x,y+1),(x,y-1)):
            if 0<=nx<w and 0<=ny<h and not seen[ny*w+nx]: q.append((nx,ny))
    return im

def components(im):
    w,h=im.size; px=im.load(); lab={}; comps=[]
    for y in range(h):
        for x in range(w):
            if px[x,y][3]==0 or (x,y) in lab: continue
            q=deque([(x,y)]); lab[(x,y)]=len(comps); pts=0; x0=x1=x; y0=y1=y
            while q:
                cx,cy=q.popleft(); pts+=1
                x0=min(x0,cx);x1=max(x1,cx);y0=min(y0,cy);y1=max(y1,cy)
                for nx,ny in ((cx+1,cy),(cx-1,cy),(cx,cy+1),(cx,cy-1)):
                    if 0<=nx<w and 0<=ny<h and px[nx,ny][3] and (nx,ny) not in lab:
                        lab[(nx,ny)]=len(comps); q.append((nx,ny))
            comps.append((pts,(x0,y0,x1+1,y1+1)))
    return comps,lab

def clean(im, min_area=150, min_h=26):
    """Drop specks and text: keep components that are big and tall enough."""
    comps,lab=components(im); px=im.load()
    keep={i for i,(a,bb) in enumerate(comps) if a>=min_area and bb[3]-bb[1]>=min_h}
    for (x,y),i in lab.items():
        if i not in keep: px[x,y]=(0,0,0,0)
    return im

def pockets(im, maxv, min_area=50):
    """Checker pockets fully enclosed by the character: bg-coloured blobs that aren't thin lines."""
    w,h=im.size; px=im.load(); seen=set()
    for y in range(h):
        for x in range(w):
            if (x,y) in seen or px[x,y][3]==0 or not is_bg(px[x,y],maxv): continue
            q=deque([(x,y)]); seen.add((x,y)); pts=[]
            while q:
                cx,cy=q.popleft(); pts.append((cx,cy))
                for nx,ny in ((cx+1,cy),(cx-1,cy),(cx,cy+1),(cx,cy-1)):
                    if 0<=nx<w and 0<=ny<h and (nx,ny) not in seen and px[nx,ny][3] and is_bg(px[nx,ny],maxv):
                        seen.add((nx,ny)); q.append((nx,ny))
            xs=[p[0] for p in pts]; ys=[p[1] for p in pts]
            if len(pts)>=min_area and max(xs)-min(xs)>=5 and max(ys)-min(ys)>=5:
                for p in pts: px[p]=(0,0,0,0)
    return im

def main_parts(im):
    comps,lab=components(im); px=im.load(); w,h=im.size
    biggest=max(range(len(comps)),key=lambda i:comps[i][0])
    def touches(bb): return bb[0]<=1 or bb[1]<=1 or bb[2]>=w-1 or bb[3]>=h-1
    keep={i for i,(a,bb) in enumerate(comps) if i==biggest or (a>=150 and bb[3]-bb[1]>=26 and not touches(bb))}
    for (x,y),i in lab.items():
        if i not in keep: px[x,y]=(0,0,0,0)
    return im

def cut(src, box, maxv, inset=0):
    x0,y0,x1,y1=box
    im=Image.open(U+src).convert('RGB').crop((x0+inset,y0+inset,x1-inset,y1-inset))
    im=main_parts(pockets(key(im,maxv),maxv))
    bb=im.getbbox()
    return im.crop(bb)

frames={}
# Valkyrie: 4 x 3, no grid lines.
V='valkyrie_sheet_source.jpg'; vx=[0,292,584,876,1168]; vy=[0,261,522,784]
for r in range(3):
    for c in range(4):
        frames['valkyrie_%d'%(r*4+c)]=cut(V,(vx[c],vy[r],vx[c+1],vy[r+1]),46)
# Frame 11's spear reaches up into the row above.
frames['valkyrie_11']=cut(V,(vx[3],440,vx[4],vy[3]),46)
# Berserker: labelled grid; top 34 px of each cell is the label strip.
B='berserker_sheet_source.jpg'; bx=[4,233,451,674,905,1163]; by=[5,254,491,777]
names=[['idle','walk1','walk2','walk3','walk4'],['jump','fall','hurt','attack_neutral','attack_side']]
for r in range(2):
    for c in range(5):
        frames['berserker_'+names[r][c]]=cut(B,(bx[c],by[r],bx[c+1],by[r+1]),34,inset=3)
frames['berserker_attack_down']=cut(B,(8,by[2],250,by[3]),34,inset=3)
frames['berserker_rage1']=cut(B,(400,by[2],655,by[3]),34,inset=3)
frames['berserker_rage2']=cut(B,(655,by[2],905,by[3]),34,inset=3)
for k,im in frames.items():
    im.save('raw_%s.png'%k); print(k, im.size)

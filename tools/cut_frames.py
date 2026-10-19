"""Cuts the labelled legend sheets in valknut/art/source into game frames.

  python3 tools/cut_frames.py          (needs Pillow)

Writes valknut/characters/<legend>/frames/<legend>_<pose>.png:
  * transparent background (the baked-in dark checkerboard is keyed out),
  * 128x128 with the feet anchored at (64, 124), so idle/walk/attack frames stay grounded,
  * attack_active is 256x128 with the same anchor (its thrust/swing and motion lines are
    wider than a 128 cell at character scale; AnimatedSprite2D centres every frame, so
    the anchor still lines up).
One scale per legend, the largest at which every pose fits. Pose boxes are hand-placed
in BOXES (source-pixel rectangles); adjust them if a sheet is redrawn.
"""
import os, json
from collections import deque
from PIL import Image

ROOT=os.path.join(os.path.dirname(os.path.abspath(__file__)),'..')
SRC=os.path.join(ROOT,'valknut','art','source')
CHARS=os.path.join(ROOT,'valknut','characters')


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


BOXES={
 'valkyrie':('valkyrie_sheet.jpg',{
   'idle':(282,4,412,182),'walk_01':(478,20,645,185),'walk_02':(645,20,802,185),'walk_03':(802,20,957,185),
   'walk_04':(957,20,1130,185),'jump':(292,174,475,294),'fall':(292,291,470,403),'hurt':(302,394,470,507),
   'attack_startup':(298,507,478,624),'attack_active':(570,505,985,650),'attack_recovery':(292,625,482,765)}),
 'berserker':('berserker_sheet.jpg',{
   'idle':(318,0,460,124),'walk_01':(318,127,450,257),'walk_02':(508,112,642,260),'walk_03':(688,112,822,260),
   'walk_04':(872,112,1006,260),'jump':(326,252,456,382),'hurt':(316,377,446,494),
   'attack_startup':(310,488,462,614),'attack_active':(570,462,960,618),'attack_recovery':(318,612,462,752)}),
}
def isolate(im):
    """Main body + anything fully inside the crop (motion lines, slash arcs, blood drops)."""
    comps,lab=components(im); px=im.load(); w,h=im.size
    big=max(range(len(comps)),key=lambda i:comps[i][0])
    def touches(bb): return bb[0]<=1 or bb[1]<=1 or bb[2]>=w-1 or bb[3]>=h-1
    body=comps[big][1]
    def colour(i):
        pts=[p for p,j in lab.items() if j==i]
        r=sum(px[p][0] for p in pts)/len(pts); g=sum(px[p][1] for p in pts)/len(pts); b=sum(px[p][2] for p in pts)/len(pts)
        return r,g,b
    def wanted(i,a,bb):
        if i==big: return True
        if a<12 or touches(bb): return False
        if bb[3]<=body[1]+6: return False          # fully above the head: a neighbour's feet
        if a<150 and (bb[1]+bb[3])/2 < body[1]+0.3*(body[3]-body[1]): return False  # specks by the head
        r,g,b=colour(i)
        if a<80 and max(r,g,b)<70 and r-g<25: return False  # dark fleck (keep red blood drops)
        return True
    keep={i for i,(a,bb) in enumerate(comps) if wanted(i,a,bb)}
    for (x,y),i in lab.items():
        if i not in keep: px[x,y]=(0,0,0,0)
    return im, comps[big][1]
def anchor(im, body):
    px=im.load(); x0,y0,x1,y1=body
    rows=[y for y in range(y0,y1) if sum(1 for x in range(x0,x1) if px[x,y][3]>128)>=4]
    ay=max(rows); top=y0+int((y1-y0)*0.55); xs=n=0
    for y in range(top,y1):
        for x in range(x0,x1):
            if px[x,y][3]>128: xs+=x; n+=1
    return xs/n, ay
out={}
for leg,(src,boxes) in BOXES.items():
    sheet=Image.open(os.path.join(SRC,src)).convert('RGB'); raw={}
    for name,box in boxes.items():
        im,body=isolate(pockets(key(sheet.crop(box),50),50))
        ax,ay=anchor(im,body); bb=im.getbbox()
        raw[name]=(im,ax,ay,bb)
    # One scale per legend: biggest scale where every pose fits its canvas around the anchor.
    s=1.0
    for name,(im,ax,ay,bb) in raw.items():
        half=126 if name=='attack_active' else 62
        s=min(s, half/max(ax-bb[0], bb[2]-ax), 120/(ay-bb[1]))
    outdir=os.path.join(CHARS,leg,'frames'); os.makedirs(outdir,exist_ok=True); meta={}
    for name,(im,ax,ay,bb) in raw.items():
        W=256 if name=='attack_active' else 128
        sc=im.resize((max(1,round(im.width*s)),max(1,round(im.height*s))),Image.LANCZOS)
        cell=Image.new('RGBA',(W,128),(0,0,0,0))
        cell.alpha_composite(sc,(round(W/2-ax*s),round(124-ay*s)))
        cell.save(os.path.join(outdir,'%s_%s.png'%(leg,name))); meta[name]=[W,128]
    if leg=='berserker':  # the sheet has one sprite for both Jump and Fall
        Image.open(os.path.join(outdir,'berserker_jump.png')).save(os.path.join(outdir,'berserker_fall.png'))
    out[leg]={'scale':round(s,4),'frames':meta,'char_height_px':round((raw['idle'][2]-raw['idle'][3][1])*s,1)}
print(json.dumps(out, indent=1))
print("If a legend's char_height_px changed, update the Sprite node scale in its .tscn "
      "(game height / char_height_px: Valkyrie 84, Berserker 92).")

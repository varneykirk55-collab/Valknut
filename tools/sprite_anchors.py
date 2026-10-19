from PIL import Image, ImageDraw
import glob, json
def auto_anchor(im):
    w,h=im.size; px=im.load()
    # x: mass centre of the lower body band (hips to feet); y: lowest opaque row with real mass.
    xs=n=0
    for y in range(int(h*0.55),h):
        for x in range(w):
            if px[x,y][3]>128: xs+=x; n+=1
    ax=xs/n
    ay=max(y for y in range(h) if sum(1 for x in range(w) if px[x,y][3]>128)>=4)
    return [round(ax),ay]
A={}
for f in sorted(glob.glob('raw_*.png')):
    A[f[4:-4]]=auto_anchor(Image.open(f))
json.dump(A,open('anchors_auto.json','w'),indent=1)
print(A)

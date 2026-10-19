"""Lays out screenshot.tscn --combo-film captures as a labelled filmstrip.
  python3 tools/combo_filmstrip.py <capture_dir> <out.png> "<title>"
"""
import sys
from PIL import Image, ImageDraw
d, out, title = sys.argv[1], sys.argv[2], sys.argv[3]
rows = [l.split("|") for l in open(d + "/combo_labels.txt").read().splitlines()]
COLS, W, H = 12, 156, 105
tiles = []
for idx, take, move, mf, pose, ph in rows:
    im = Image.open("%s/combo_%03d.png" % (d, int(idx))).convert("RGB").resize((W, H))
    dr = ImageDraw.Draw(im)
    dr.rectangle((0, 0, W, 22), fill=(0, 0, 0))
    dr.text((3, 1), "%s f%s" % (move, mf), fill=(255, 255, 0))
    dr.text((3, 11), pose, fill=(255, 140, 30) if ph else (140, 255, 140))
    if ph:
        dr.rectangle((0, 0, W - 1, H - 1), outline=(255, 140, 30), width=2)
    tiles.append(im)
rows_n = (len(tiles) + COLS - 1) // COLS
sheet = Image.new("RGB", (COLS * W, rows_n * H + 26), (20, 20, 24))
ImageDraw.Draw(sheet).text((6, 7), title + "   (orange = placeholder pose awaiting art, green = final art)", fill=(255, 255, 255))
for i, t in enumerate(tiles):
    sheet.paste(t, ((i % COLS) * W, 26 + (i // COLS) * H))
sheet.save(out)
print(out, len(tiles), "frames")

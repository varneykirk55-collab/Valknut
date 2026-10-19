"""Split a transparent strip of N poses into art-set frames with ONE shared scale.

    python3 tools/import_strip.py <strip.png> <out_prefix> [--height=208]
        [--canvas=512x256 --feet=256,248]

Poses are found by empty columns between them. The scale is set so the FIRST pose is
--height px tall and the same factor is used for every pose (normalising each pose to
the same height would hide or invent breathing). Each pose is then placed so the
midpoint between its feet (outer edges of the lowest opaque row's two runs) sits on
--feet x, and its lowest pixel on --feet y. Writes <out_prefix>_01.png, _02.png, ...
"""
import sys
from PIL import Image


def segments(mask, length, gap=8):
    out, start, empty = [], None, 0
    for i in range(length):
        if mask(i):
            if start is None:
                start = i
            empty = 0
        elif start is not None:
            empty += 1
            if empty > gap:
                out.append((start, i - empty + 1))
                start, empty = None, 0
    if start is not None:
        out.append((start, length))
    return out


def feet_mid(im):
    px = im.load()
    y = im.getbbox()[3] - 4
    runs = segments(lambda x: px[x, y][3] > 128, im.width, 2)
    return (runs[0][0] + runs[-1][1]) / 2.0


def main(a):
    opts = dict(o[2:].split("=", 1) for o in a if o.startswith("--"))
    a = [x for x in a if not x.startswith("--")]
    height = int(opts.get("height", 208))
    cw, ch = (int(v) for v in opts.get("canvas", "512x256").split("x"))
    fx, fy = (int(v) for v in opts.get("feet", "256,248").split(","))
    strip = Image.open(a[0]).convert("RGBA")
    alpha = strip.getchannel("A").point(lambda v: 255 if v > 128 else 0)
    ap = alpha.load()
    cols = segments(lambda x: any(ap[x, y] for y in range(strip.height)), strip.width)
    poses = [strip.crop((x0, 0, x1, strip.height)) for x0, x1 in cols if x1 - x0 > 40]
    poses = [p.crop(p.getchannel("A").point(lambda v: 255 if v > 128 else 0).getbbox()) for p in poses]
    scale = height / poses[0].height
    for i, p in enumerate(poses, 1):
        mid = feet_mid(p)
        p = p.resize((round(p.width * scale), round(p.height * scale)), Image.LANCZOS)
        canvas = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
        canvas.alpha_composite(p, (round(fx - mid * scale), fy - p.height))
        path = "%s_%02d.png" % (a[1], i)
        canvas.save(path)
        print(path, "pose %dx%d -> %dx%d, scale %.4f" % (poses[i - 1].width, poses[i - 1].height, p.width, p.height, scale))


if __name__ == "__main__":
    main(sys.argv[1:])

"""Cut a single figure out of a flat-background character reference sheet.

    python tools/cut_reference.py <sheet.png> <x0> <y0> <x1> <y1> <out.png> [--flip]
        [--canvas=WxH --feet=X,Y --height=H]

The background (and the drop shadow under the feet) is a near-neutral grey; it's
flood-filled from the crop's border and made transparent. The dark outline stops the
fill, so nothing inside the character is touched. --flip mirrors the result so the
figure faces right (game convention). The colours are never changed and nothing is
redrawn: this only isolates pixels already in the approved art.

With --canvas/--feet/--height the figure is scaled (Lanczos) to H pixels tall and
placed with the bottom-centre of its bounds on the feet anchor, the convention every
frame of an art set shares (see tools/art_sets.py).
"""
import sys
from collections import deque
from PIL import Image


def is_backdrop(p) -> bool:
    r, g, b = p[:3]
    return max(r, g, b) - min(r, g, b) <= 10 and 38 <= max(r, g, b) <= 100


def cut(sheet: str, box: tuple, out: str, flip: bool, place: dict) -> None:
    im = Image.open(sheet).convert("RGBA").crop(box)
    w, h = im.size
    px = im.load()
    seen = bytearray(w * h)
    todo = deque((x, y) for x in range(w) for y in (0, h - 1))
    todo.extend((x, y) for y in range(h) for x in (0, w - 1))
    while todo:
        x, y = todo.popleft()
        if seen[y * w + x] or not is_backdrop(px[x, y]):
            continue
        seen[y * w + x] = 1
        px[x, y] = (0, 0, 0, 0)
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and not seen[ny * w + nx]:
                todo.append((nx, ny))
    _keep_largest(im)
    im = im.crop(im.getbbox())
    if flip:
        im = im.transpose(Image.FLIP_LEFT_RIGHT)
    if place:
        h = place["height"]
        im = im.resize((round(im.width * h / im.height), h), Image.LANCZOS)
        canvas = Image.new("RGBA", place["canvas"], (0, 0, 0, 0))
        fx, fy = place["feet"]
        canvas.alpha_composite(im, (fx - im.width // 2, fy - im.height))
        im = canvas
    im.save(out)
    print(out, im.size)


def _keep_largest(im: Image.Image) -> None:
    """Clear everything but the largest opaque island (bits of neighbouring figures)."""
    w, h = im.size
    px = im.load()
    label = [0] * (w * h)
    sizes = {}
    n = 0
    for sy in range(h):
        for sx in range(w):
            if label[sy * w + sx] or px[sx, sy][3] == 0:
                continue
            n += 1
            label[sy * w + sx] = n
            stack, count = [(sx, sy)], 0
            while stack:
                x, y = stack.pop()
                count += 1
                for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if 0 <= nx < w and 0 <= ny < h and not label[ny * w + nx] and px[nx, ny][3]:
                        label[ny * w + nx] = n
                        stack.append((nx, ny))
            sizes[n] = count
    keep = max(sizes, key=sizes.get)
    for y in range(h):
        for x in range(w):
            if label[y * w + x] != keep:
                px[x, y] = (0, 0, 0, 0)


if __name__ == "__main__":
    a = sys.argv[1:]
    opts = dict(o[2:].split("=", 1) for o in a if o.startswith("--") and "=" in o)
    place = {}
    if opts:
        place = {"canvas": tuple(int(v) for v in opts["canvas"].split("x")),
                 "feet": tuple(int(v) for v in opts["feet"].split(",")),
                 "height": int(opts["height"])}
    cut(a[0], tuple(int(v) for v in a[1:5]), a[5], "--flip" in a, place)

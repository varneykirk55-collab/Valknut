"""Artwork repair for the Berserker rig layers (reviewable copies, nothing is replaced).

    python3 tools/repair_berserker_layers.py

Reads valknut/characters/berserker/layers/ (the 17 approved layers) and writes repaired
copies to valknut/characters/berserker/layers_repaired/, plus
layers_repaired/masks/<layer>_new.png (every pixel that is new in a repaired layer) and
layers_repaired/report.json.

Rules every repair obeys:
  * Original visible pixels are kept. Where a pixel is moved between layers (a fragment of
    the fur outline that was filed under the arm), it only changes layer.
  * A new pixel may only be placed where the idle drawing already shows a layer ABOVE the
    repaired one (owner > layer). So the idle pose is unchanged: restacking the repaired
    layers reproduces idle_01 (checked at the end, max difference reported).
  * New art is drawn with the drawing's own cel vocabulary: flat base colour, one shade
    tone along the lower edge, a dark outline of the same weight and colour. No blur, no
    smeared inpainting, no stretching. It is procedural drawing, not an illustrator's work;
    the report lists where it falls short.
"""
import json
import math
import os
import sys

import cv2
import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from build_berserker_rig import idle_01  # noqa: E402

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
SRC = os.path.join(ROOT, "valknut/characters/berserker/layers")
OUT = os.path.join(ROOT, "valknut/characters/berserker/layers_repaired")

SKIN = np.array((239, 160, 119))
SKIN_SHADE = np.array((192, 117, 90))
SKIN_DEEP = np.array((160, 77, 63))
OUTLINE = np.array((21, 12, 10))

ORDER = ["cape", "mantle_back", "leg_lower_L", "leg_lower_R", "leg_upper_L", "leg_upper_R", "pelvis",
         "loincloth", "torso", "arm_upper_L", "arm_upper_R", "mantle_front", "head", "axe_L", "axe_R",
         "arm_fore_L", "arm_fore_R"]
IDX = {n: i for i, n in enumerate(ORDER)}


class Ctx:
    def __init__(self):
        self.orig = np.array(idle_01())
        self.H, self.W = self.orig.shape[:2]
        self.alpha = self.orig[:, :, 3] >= 250
        self.owner = np.array(Image.open(os.path.join(SRC, "reference", "owner_map.png"))).astype(int)
        self.layers = {n: np.array(Image.open(os.path.join(SRC, n + ".png")).convert("RGBA")) for n in ORDER}
        # Start from the approved visible pixels only: the earlier flat-colour fills of hidden
        # areas (masks/<layer>_reconstructed.png) are dropped and redrawn below.
        for n in ORDER:
            old = np.array(Image.open(os.path.join(SRC, "masks", n + "_reconstructed.png"))) > 0
            self.layers[n][old] = 0
        self.vis0 = {n: self.layers[n][:, :, 3] > 0 for n in ORDER}
        self.new = {n: np.zeros((self.H, self.W), bool) for n in ORDER}
        self.moved = {}
        self.yy, self.xx = np.mgrid[0:self.H, 0:self.W]

    def move(self, src, dst, mask):
        """Re-file approved visible pixels from one layer to another (idle is unchanged:
        every pixel is still drawn exactly once, with the same colour)."""
        mask = mask & self.vis0[src]
        self.layers[dst][mask] = self.layers[src][mask]
        self.layers[src][mask] = 0
        self.vis0[dst] |= mask
        self.vis0[src] &= ~mask
        self.owner[mask] = IDX[dst]
        self.moved[(src, dst)] = self.moved.get((src, dst), 0) + int(mask.sum())

    def allowed(self, n):
        """Pixels where a new pixel of layer n stays hidden at idle."""
        return (self.owner > IDX[n]) & (self.owner != 255) & self.alpha

    def visible(self, n):
        return self.vis0[n]

    def poly(self, pts):
        m = np.zeros((self.H, self.W), np.uint8)
        cv2.fillPoly(m, [np.array(pts, np.int32)], 1)
        return m > 0

    def disc(self, c, r):
        return (self.xx - c[0]) ** 2 + (self.yy - c[1]) ** 2 <= r * r

    def hull(self, *shapes):
        pts = np.argwhere(np.any(shapes, axis=0))[:, ::-1].astype(np.int32)
        m = np.zeros((self.H, self.W), np.uint8)
        cv2.fillConvexPoly(m, cv2.convexHull(pts), 1)
        return m > 0

    def paint(self, n, mask, colour):
        """Draw `mask` in layer n (never over its approved visible pixels, never where it
        would show at idle)."""
        mask = mask & self.allowed(n) & ~self.vis0[n]
        self.layers[n][mask, :3] = colour if np.ndim(colour) == 1 else colour[mask]
        self.layers[n][mask, 3] = 255
        self.new[n] |= mask

    def shade(self, shape, dx, dy):
        """Crescent along the lower-right edge of a shape: the part not covered by the same
        shape shifted up-left by (dx, dy): how the drawing models light (from upper left)."""
        sh = np.roll(np.roll(shape, -dy, 0), -dx, 1)
        return shape & ~sh

    def ring(self, shape, width):
        return shape & ~ndimage.binary_erosion(shape, iterations=width)


def repair_arm_upper(c, side):
    n = "arm_upper_" + side
    shoulder, elbow = ((c.disc((238, 188), 42), c.disc((164, 256), 31)) if side == "L"
                       else (c.disc((432, 194), 36), c.disc((462, 286), 28)))
    limb = c.hull(shoulder, elbow)
    # existing visible pixels of the arm layer define where the limb really is
    limb |= c.visible(n)
    free = limb & c.allowed(n) & ~c.visible(n)
    c.paint(n, free, SKIN)
    crescent = c.shade(limb, 9, 8) & free
    c.paint(n, crescent, SKIN_SHADE)
    outline = c.ring(limb, 3) & free
    c.paint(n, outline, OUTLINE)
    return limb


def _min_cut(err):
    """Vertical min-error path through err (h x w); returns a mask that is True right of it."""
    h, w = err.shape
    cost = err.copy()
    for y in range(1, h):
        left = np.r_[np.inf, cost[y - 1, :-1]]
        right = np.r_[cost[y - 1, 1:], np.inf]
        cost[y] += np.minimum(np.minimum(left, cost[y - 1]), right)
    x = int(np.argmin(cost[-1]))
    mask = np.zeros((h, w), bool)
    for y in range(h - 1, -1, -1):
        mask[y, x:] = True
        if y:
            lo, hi = max(x - 1, 0), min(x + 2, w)
            x = lo + int(np.argmin(cost[y - 1, lo:hi]))
    return mask


def quilt(c, n, zone, texture_mask, seed, block=20, overlap=6, tries=260):
    """Fills `zone` of layer n by image quilting (Efros-Freeman): blocks are copied from
    `texture_mask` (visible pixels of the same material), chosen to continue what is already
    there, and joined along minimum-error seams. Only the layer's own drawn pixels are used."""
    rng = np.random.default_rng(seed)
    img = c.layers[n][:, :, :3].astype(np.float32)
    known = c.vis0[n].copy()
    hidden = zone & c.allowed(n) & ~c.vis0[n]
    # valid block origins: every pixel of the block is texture
    tm = texture_mask.astype(np.uint8)
    integ = cv2.integral(tm)
    ys, xs = np.mgrid[0:c.H - block, 0:c.W - block]
    full = (integ[block:c.H, block:c.W] - integ[0:c.H - block, block:c.W] - integ[block:c.H, 0:c.W - block]
            + integ[0:c.H - block, 0:c.W - block]) == block * block
    cand = np.argwhere(full)
    if len(cand) == 0:
        return
    step = block - overlap
    by0, bx0 = np.nonzero(hidden)
    y_lo, y_hi, x_lo, x_hi = by0.min(), by0.max(), bx0.min(), bx0.max()
    for y in range(max(y_lo - overlap, 0), y_hi + 1, step):
        for x in range(max(x_lo - overlap, 0), x_hi + 1, step):
            y1, x1 = min(y + block, c.H), min(x + block, c.W)
            tgt = hidden[y:y1, x:x1]
            if not tgt.any():
                continue
            kn = known[y:y1, x:x1]
            h, w = y1 - y, x1 - x
            pick = cand[rng.integers(0, len(cand), tries)]
            best, best_e = None, np.inf
            for py, px in pick:
                patch = img[py:py + h, px:px + w]
                e = ((patch - img[y:y1, x:x1]) ** 2).sum(-1)[kn].sum() / max(kn.sum(), 1) if kn.any() else 0.0
                if e < best_e:
                    best, best_e = (py, px), e
            py, px = best
            patch = img[py:py + h, px:px + w]
            put = tgt.copy()
            if kn.any():
                err = ((patch - img[y:y1, x:x1]) ** 2).sum(-1)
                # keep the cut seams away from known pixels: the cut decides who wins in overlap
                ov_left = kn[:, :overlap].any() and w > overlap
                ov_top = kn[:overlap, :].any() and h > overlap
                use = np.ones((h, w), bool)
                if ov_left:
                    use[:, :overlap] = _min_cut(err[:, :overlap]) 
                if ov_top:
                    use[:overlap, :] &= _min_cut(err[:overlap, :].T).T
                put &= use | ~kn
                put &= ~kn | use
            put &= tgt
            sub = img[y:y1, x:x1]
            sub[put] = patch[put]
            kn |= put
    filled = hidden & known
    c.layers[n][filled, :3] = img[filled].astype(np.uint8)
    c.layers[n][filled, 3] = 255
    c.new[n] |= filled & ~c.vis0[n]


def sawtooth(c, p0, p1, amp, period, seed):
    """Polygon edge from p0 to p1 with fur-tuft teeth (deterministic)."""
    rng = np.random.default_rng(seed)
    p0, p1 = np.array(p0, float), np.array(p1, float)
    d = p1 - p0
    length = np.linalg.norm(d)
    u = d / length
    nrm = np.array((-u[1], u[0]))
    pts = [tuple(p0)]
    t = 0.0
    while t < length:
        w = period * rng.uniform(0.7, 1.3)
        a = amp * rng.uniform(0.6, 1.2)
        pts.append(tuple(p0 + u * (t + w * 0.5) + nrm * a))
        pts.append(tuple(p0 + u * min(t + w, length)))
        t += w
    return pts


def fur_strands(c, n, zone, direction, base, light, dark, seed, spacing=9, width=3):
    """Paint a fur mass: base colour, then strokes along `direction` (unit vector) in the
    lighter and darker tones, like the drawing's own fur."""
    rng = np.random.default_rng(seed)
    c.paint(n, zone, base)
    canvas = np.zeros((c.H, c.W, 3), np.uint8)
    ink = np.zeros((c.H, c.W), np.uint8)
    d = np.array(direction, float)
    nrm = np.array((-d[1], d[0]))
    ys, xs = np.nonzero(zone)
    cx, cy = xs.mean(), ys.mean()
    span = max(c.H, c.W)
    for off in np.arange(-span, span, spacing):
        o = rng.uniform(-2, 2)
        p = np.array((cx, cy)) + nrm * (off + o)
        for seg in range(-span, span, 28):
            L = rng.uniform(16, 34)
            a = p + d * (seg + rng.uniform(-6, 6))
            b = a + d * L
            tone = rng.choice(3, p=[0.45, 0.35, 0.2])
            colour = (light, base, dark)[tone]
            cv2.line(canvas, tuple(int(v) for v in a), tuple(int(v) for v in b), tuple(int(v) for v in colour),
                     int(width + rng.integers(0, 2)), cv2.LINE_8)
            cv2.line(ink, tuple(int(v) for v in a), tuple(int(v) for v in b), 1, int(width + rng.integers(0, 2)), cv2.LINE_8)
    mask = zone & (ink > 0)
    c.paint(n, mask, canvas.reshape(-1, 3)[np.arange(c.H * c.W)].reshape(c.H, c.W, 3))


def cloth_folds(c, n, zone, base, light, dark, seed, pitch=26):
    """Cape cloth: base colour with vertical fold bands, a lighter ridge and a darker
    crease on each, wobbled so they don't look ruled."""
    rng = np.random.default_rng(seed)
    c.paint(n, zone, base)
    colour = np.zeros((c.H, c.W, 3), np.uint8)
    colour[:] = base
    wob = np.sin(c.yy / 37.0 + rng.uniform(0, 6)) * 6 + np.sin(c.yy / 91.0) * 9
    phase = ((c.xx + wob + rng.uniform(0, pitch)) % pitch) / pitch
    colour[(phase > 0.30) & (phase < 0.52)] = light
    colour[(phase > 0.52) & (phase < 0.60)] = dark
    c.paint(n, zone, colour)


def classify(c):
    o = c.orig.astype(int)
    r, g, b = o[:, :, 0], o[:, :, 1], o[:, :, 2]
    skin = (r > 165) & (r - b > 45) & (g > 95) & (r - g > 22) & (b > 85)
    shade = (r > 140) & (r - b > 40) & (g > 80)
    dark = (r + g + b) < 150
    return skin | shade, dark


def repair_fragments(c):
    """Re-file pixels that sit in the wrong layer: the fur's lower outline and the torso's
    leather strap were filed under the rear arm. Nothing changes at idle."""
    skinlike, dark = classify(c)
    arm = c.vis0["arm_upper_L"]
    d_fur = ndimage.distance_transform_edt(c.owner != IDX["mantle_front"])
    d_skin = ndimage.distance_transform_edt(~(arm & skinlike))
    leather = arm & ~skinlike & ~dark & (c.xx > 232)
    c.move("arm_upper_L", "torso", leather)
    d_leather = ndimage.distance_transform_edt(~leather)
    outline_fur = arm & dark & (d_fur <= 3) & (d_fur < d_skin)
    outline_strap = arm & dark & (d_leather <= 3) & (d_leather < d_skin) & (c.xx > 232)
    c.move("arm_upper_L", "mantle_front", outline_fur)
    c.move("arm_upper_L", "torso", outline_strap)


def texture_of(c, n, margin=5):
    own = c.owner == IDX[n]
    return ndimage.binary_erosion(own, iterations=margin)


def repair_hidden_behind_rear_arm(c):
    """Back fur, cape and torso flank behind the rear arm (see the layer owner map)."""
    # --- mantle_back: dark back fur continues under the arm down to a ragged lower edge
    low = sawtooth(c, (246, 334), (112, 232), 9, 20, 3)
    zone_fur = c.poly([(96, 96), (282, 96), (282, 334)] + low + [(96, 190)])
    quilt(c, "mantle_back", zone_fur, texture_of(c, "mantle_back"), 21)
    edge_line = np.zeros((c.H, c.W), np.uint8)
    cv2.polylines(edge_line, [np.array(low, np.int32)], False, 1, 3)
    c.paint("mantle_back", (edge_line > 0) & c.new["mantle_back"] | ((edge_line > 0) & zone_fur & c.allowed("mantle_back")), (25, 11, 11))
    # --- cape: continuous cloth behind everything on the rear side
    zone_cape = c.poly([(0, 200), (300, 190), (300, 700), (0, 700)])
    quilt(c, "cape", zone_cape & ~zone_fur, texture_of(c, "cape", 4), 7, block=22, overlap=6)
    # --- torso: rib cage / lat flank under the rear upper arm, tapering to the belt end
    flank = c.poly([(278, 164), (250, 168), (230, 180), (214, 200), (209, 226), (218, 250), (232, 268),
                    (246, 278), (278, 278)])
    c.paint("torso", flank, SKIN)
    back_shade = flank & ~ndimage.binary_erosion(flank, structure=np.ones((3, 3)), iterations=16)
    back_shade &= (c.xx < 246)
    c.paint("torso", back_shade, SKIN_SHADE)
    c.paint("torso", c.ring(flank, 3) & (c.xx < 244), OUTLINE)


def repair_hidden_behind_front_arm(c):
    """Right flank, waist band, back fur and hip panel behind the front (attacking) arm."""
    # back fur behind the right shoulder (the visible brown tufts continue under the arm)
    zone_fur = c.poly([(398, 150), (494, 150), (500, 268), (398, 268)])
    quilt(c, "mantle_back", zone_fur, texture_of(c, "mantle_back"), 33)
    # waist band: the belt's leather and studs continue under the forearm cuff
    belt_tex = (c.owner == IDX["torso"]) & (c.yy >= 258) & (c.yy <= 294) & (c.xx >= 262) & (c.xx <= 404)
    belt_tex = ndimage.binary_erosion(belt_tex, iterations=2)
    band = c.poly([(396, 254), (446, 254), (462, 262), (468, 296), (396, 298)])
    quilt(c, "torso", band, belt_tex, 5, block=16, overlap=5)
    c.paint("torso", c.ring(band, 3) & (c.xx > 456) & c.new["torso"], OUTLINE)
    # hip panel: leather, studs and fur trim continue under the forearm to a rounded hip
    edge = sawtooth(c, (494, 296), (470, 408), 6, 16, 9)
    hip = c.poly([(410, 296), (494, 296)] + edge + [(416, 396)])
    quilt(c, "pelvis", hip, texture_of(c, "pelvis", 6), 17, block=18, overlap=6)
    c.paint("pelvis", c.ring(hip, 3) & (c.xx > 462) & c.new["pelvis"], OUTLINE)
    # right rib cage / flank under the front upper arm, down to the belt
    flank = c.poly([(398, 172), (428, 170), (448, 188), (456, 216), (452, 240), (446, 256), (424, 258), (398, 258)])
    c.paint("torso", flank, SKIN)
    c.paint("torso", flank & ~ndimage.binary_erosion(flank, structure=np.ones((3, 3)), iterations=14) & (c.xx > 428), SKIN_SHADE)
    c.paint("torso", c.ring(flank, 3) & (c.xx > 430) & (c.yy < 252), OUTLINE)


def main():
    c = Ctx()
    os.makedirs(os.path.join(OUT, "masks"), exist_ok=True)
    repair_fragments(c)
    repair_arm_upper(c, "L")
    repair_arm_upper(c, "R")
    repair_hidden_behind_rear_arm(c)
    repair_hidden_behind_front_arm(c)
    finish(c)


def finish(c):
    # idle check: restack == original
    stack = Image.new("RGBA", (c.W, c.H))
    report = {}
    for n in ORDER:
        stack.alpha_composite(Image.fromarray(c.layers[n]))
        Image.fromarray(c.layers[n]).save(os.path.join(OUT, n + ".png"))
        Image.fromarray((c.new[n] * 255).astype(np.uint8)).save(os.path.join(OUT, "masks", n + "_new.png"))
        report[n] = int(c.new[n].sum())
    s = np.array(stack).astype(int)
    diff = np.abs(s - c.orig.astype(int))[c.orig[:, :, 3] > 0].max()
    report["_idle_max_difference"] = int(diff)
    report["_pixels_moved_between_layers"] = {"%s->%s" % k: v for k, v in c.moved.items()}
    json.dump(report, open(os.path.join(OUT, "report.json"), "w"), indent=1)
    print("restack vs idle_01: max difference %d / 255" % diff)
    print({k: v for k, v in report.items() if v and not k.startswith("_")})


if __name__ == "__main__":
    main()

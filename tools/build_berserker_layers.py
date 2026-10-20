"""Splits the approved Berserker idle_01 drawing into rig layers.

    python3 tools/build_berserker_layers.py

Needs Pillow, numpy, scipy and opencv-python.

Source: pose 1 of art/source/berserker_v2_idle_v2/berserker_v2_idle_strip.png at its
full source resolution, 620x655 px.

1. **Partition.** Every visible pixel of the drawing goes to exactly one layer. Layers
   claim pixels top-down: a region polygon plus a colour rule (fur, hair, skin, cloth).
   Pixels nobody claimed (mostly the dark outlines) go to the nearest layer, with a
   small bias towards the occluding (upper) layer, since an outline at an overlap
   belongs to the object in front. Stacking the layers in DRAW_ORDER gives back the
   original image, pixel for pixel.
2. **Reconstruction.** Each layer has a FULL extent: its visible part plus polygons for
   anatomy that's hidden under other layers (shoulders under the mantle, thigh tops
   under the skirt, and so on). Hidden pixels are filled by extending the layer's
   adjacent colours (nearest fill, smoothed, snapped to a 4-colour palette from the layer's own neighbouring pixels: flat, cel-style) and given a dark outline
   where they form a new edge. Nothing is redrawn from scratch. Every reconstructed
   pixel is recorded in layers/masks/<layer>_reconstructed.png.
3. **Axe master.** The front (screen-right) axe becomes axe_master.png. Its handle
   under the fist is reconstructed by repeating the visible handle wrap along the
   handle's axis. The rear axe's own drawing is kept only for comparison
   (reference/axe_rear_original.png). The rig places the master in both hands; see
   pivots.json -> axes.

Outputs go to valknut/characters/berserker/layers/.
"""
import json
import os
import sys

import cv2
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from build_berserker_rig import idle_01  # noqa: E402

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
OUT = os.path.join(ROOT, "valknut/characters/berserker/layers")
OUTLINE = (24, 17, 14)

# Screen-left / screen-right (L / R) as seen in the drawing; he faces right.
# Bottom to top.
DRAW_ORDER = [
    "cape", "mantle_back", "leg_lower_L", "leg_lower_R", "leg_upper_L", "leg_upper_R",
    "pelvis", "loincloth", "torso", "arm_upper_L", "arm_upper_R", "mantle_front", "head",
    "axe_L", "axe_R", "arm_fore_L", "arm_fore_R",
]

# Visible handle stretches (the rear axe also shows its pommel above the fist).
HANDLE_L = [[(142, 318), (164, 330), (160, 346), (140, 338)], [(68, 396), (104, 358), (118, 372), (84, 410)]]
HANDLE_R = [[(496, 380), (506, 373), (534, 385), (530, 405), (500, 398)]]

# Claim polygons (visible extent) and colour rules, applied top-down.
CLAIM = {
    "arm_fore_L": ([(95, 245), (130, 225), (170, 232), (210, 262), (218, 300), (188, 314), (168, 335),
                    (158, 362), (148, 388), (118, 398), (90, 390), (80, 350), (78, 300)], "not_handle_L"),
    "arm_fore_R": ([(415, 298), (440, 272), (472, 258), (502, 262), (528, 290), (534, 332), (526, 372),
                    (512, 398), (488, 402), (466, 392), (452, 366), (436, 342), (424, 320)], "not_handle_R"),
    "axe_L": ([(118, 372), (100, 410), (120, 455), (125, 520), (100, 575), (5, 580), (5, 445), (15, 400),
               (60, 385), (68, 392), (104, 356)], "axe_L"),
    "axe_L_pommel": ([(140, 316), (166, 330), (162, 348), (140, 340)], "axe_L"),
    "axe_R": ([(495, 368), (512, 362), (540, 380), (560, 378), (610, 395), (618, 440),
               (612, 575), (580, 580), (500, 450), (505, 420), (535, 405), (500, 390)], "axe_R"),
    "head": ([(205, 85), (215, 62), (250, 38), (300, 10), (345, 0), (395, 0), (414, 20), (414, 60),
              (402, 74), (400, 100), (400, 128), (392, 140), (366, 148), (345, 150), (322, 142),
              (312, 128), (300, 106), (272, 100), (242, 97), (212, 96)], "head"),
    "braid_L": ([(292, 96), (312, 96), (330, 150), (334, 226), (318, 230), (302, 160)], "hair"),
    "braid_R": ([(380, 120), (400, 120), (402, 190), (386, 190)], "hair"),
    "mantle_front": ([(180, 95), (240, 82), (305, 92), (318, 130), (305, 172), (272, 184), (240, 194),
                      (205, 196), (178, 200), (160, 175), (168, 130)], "mantle_front"),
    "mantle_front_R": ([(392, 104), (430, 108), (472, 158), (484, 232), (462, 238), (442, 202),
                        (420, 190), (398, 176), (392, 130)], "mantle_front"),
    "arm_upper_L": ([(148, 160), (242, 158), (272, 185), (278, 232), (268, 276), (240, 288), (198, 272),
                     (168, 246), (148, 214)], "skin"),
    "arm_upper_R": ([(404, 165), (440, 178), (472, 214), (488, 254), (492, 292), (470, 302), (440, 302),
                     (420, 292), (410, 262), (403, 220)], "skin"),
    "torso": ([(255, 140), (300, 128), (320, 140), (345, 150), (380, 140), (400, 150), (406, 170),
               (410, 230), (416, 262), (442, 282), (456, 300), (440, 310), (400, 306), (330, 302),
               (260, 306), (244, 292), (240, 250), (255, 220), (264, 190)], "all"),
    "loincloth": ([(304, 296), (392, 296), (394, 360), (390, 430), (382, 500), (372, 584), (328, 588),
                   (310, 520), (300, 430), (298, 350)], "red"),
    "pelvis": ([(150, 410), (175, 380), (205, 330), (232, 300), (458, 300), (468, 340), (458, 380),
                (448, 405), (420, 412), (396, 430), (390, 455), (360, 462), (305, 462), (300, 440),
                (280, 420), (258, 405), (236, 400), (200, 405)], "not_red"),
    "leg_upper_L": ([(160, 400), (252, 392), (278, 420), (272, 472), (258, 502), (220, 508), (172, 498),
                     (152, 470), (158, 430)], "not_red"),
    "leg_upper_R": ([(366, 398), (452, 398), (488, 428), (494, 482), (474, 508), (420, 508), (378, 494),
                     (366, 452)], "not_red"),
    "leg_lower_L": ([(138, 488), (268, 488), (264, 560), (246, 620), (256, 655), (80, 655), (106, 600),
                     (126, 540)], "not_red"),
    "leg_lower_R": ([(378, 488), (500, 488), (506, 560), (566, 636), (566, 655), (396, 655), (392, 600),
                     (386, 530)], "not_red"),
    "mantle_back": ([(0, 180), (60, 120), (130, 90), (205, 85), (250, 160), (270, 280), (200, 300),
                     (120, 250), (40, 240)], "not_red"),
    "mantle_back_R": ([(420, 160), (470, 160), (500, 250), (470, 270), (430, 250)], "not_red"),
}
# Claim order (top-down). Sub-claims (braid_*, *_R regions) map to their layer.
CLAIM_ORDER = ["arm_fore_L", "arm_fore_R", "axe_L", "axe_L_pommel", "axe_R", "head", "braid_L", "braid_R",
               "mantle_front", "mantle_front_R", "arm_upper_L", "arm_upper_R", "torso", "loincloth",
               "pelvis", "leg_upper_L", "leg_upper_R", "leg_lower_L", "leg_lower_R", "mantle_back",
               "mantle_back_R"]
LAYER_OF = {"axe_L_pommel": "axe_L", "braid_L": "head", "braid_R": "head", "mantle_front_R": "mantle_front", "mantle_back_R": "mantle_back"}
CLASPS = [((270, 147), 24), ((411, 152), 22)]   # gold mantle clasps (centre, radius)

# Joint pivots for a future skeleton (source px, idle_01 at 620x655).
PIVOTS = {
    "spine_root": (345, 300), "neck": (342, 145),
    "shoulder_L": (236, 182), "elbow_L": (160, 258), "wrist_L": (118, 352),
    "shoulder_R": (432, 194), "elbow_R": (462, 286), "wrist_R": (492, 368),
    "hip_L": (222, 404), "knee_L": (208, 490), "hip_R": (420, 404), "knee_R": (446, 492),
    "grip_L": (112, 362), "grip_R": (500, 382),
}

# Hidden anatomy to reconstruct, added to a layer's visible extent: polygons, or
# ("ellipse", (cx, cy), (rx, ry)) for rounded joint ends.
HIDDEN = {
    "torso": [[(262, 160), (292, 150), (298, 250), (272, 282), (252, 252)],                # side under L arm
              [(398, 160), (424, 170), (432, 258), (446, 292), (414, 292), (402, 240)],    # side under R arm
              [(306, 118), (398, 118), (398, 165), (306, 165)],                            # under the beard
              [(294, 140), (340, 140), (342, 236), (296, 236)],                            # under the L braid
              [(378, 130), (404, 130), (406, 196), (380, 196)]],                           # under the R braid
    "arm_upper_L": [("ellipse", (234, 180), (36, 22)), ("ellipse", (160, 258), (30, 26))],  # shoulder, elbow
    "arm_upper_R": [("ellipse", (432, 192), (30, 20)), ("ellipse", (462, 288), (28, 22))],
    "leg_upper_L": [("ellipse", (222, 402), (46, 30))],                                     # hip under skirt
    "leg_upper_R": [("ellipse", (420, 402), (48, 30))],
    "leg_lower_L": [("ellipse", (205, 488), (52, 18))],                                     # knee under fur
    "leg_lower_R": [("ellipse", (445, 490), (52, 18))],
    "pelvis": [[(300, 296), (392, 296), (394, 462), (300, 462)]],                           # under loincloth
    "mantle_front": [("ellipse", (255, 90), (56, 16))],                                     # fur under the hair
}


def shape_mask(shape_def, shape):
    if shape_def[0] == "ellipse":
        _, (cx, cy), (rx, ry) = shape_def
        yy, xx = np.mgrid[0:shape[0], 0:shape[1]]
        return ((xx - cx) / rx) ** 2 + ((yy - cy) / ry) ** 2 <= 1.0
    return poly_mask(shape_def, shape)


def flat_fill(rgb, own, recon):
    """Cel-style fill: extend the nearest visible colours, smooth out the streaks, then
    snap every pixel to a 4-colour palette taken from the layer's own pixels nearby."""
    _, (iy, ix) = ndimage.distance_transform_edt(~own, return_indices=True)
    fill = np.ascontiguousarray(rgb[iy, ix])
    fill = cv2.medianBlur(fill, 9)
    near = own & ndimage.binary_dilation(recon, iterations=14)
    samples = rgb[near].astype(np.float32)
    if len(samples) < 8:
        return fill
    k = min(4, len(samples))
    _, _, centres = cv2.kmeans(samples, k, None, (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 20, 1.0),
                               3, cv2.KMEANS_PP_CENTERS)
    px = fill[recon].astype(np.float32)
    nearest = ((px[:, None, :] - centres[None, :, :]) ** 2).sum(-1).argmin(1)
    out = fill.copy()
    out[recon] = centres[nearest].astype(np.uint8)
    return out


def poly_mask(pts, shape):
    m = Image.new("L", (shape[1], shape[0]), 0)
    ImageDraw.Draw(m).polygon(pts, fill=255)
    return np.array(m) > 0


def colour_rules(rgb):
    r, g, b = [rgb[:, :, i].astype(int) for i in range(3)]
    mx = np.maximum(np.maximum(r, g), b)
    mn = np.minimum(np.minimum(r, g), b)
    hsv = cv2.cvtColor(rgb, cv2.COLOR_RGB2HSV).astype(int)   # H 0-179
    h, s, v = hsv[:, :, 0], hsv[:, :, 1], hsv[:, :, 2]
    dark = (r + g + b) < 150
    skin = (r > 165) & (r - b > 45) & (g > 95) & (r - g > 22) & (b > 85)
    warp = (r > 140) & (g < 95) & (b < 95) & (r - g > 60)
    hair = (h >= 8) & (h <= 26) & (s > 110) & (v > 90) & ~skin
    fur = (mx > 135) & ((mx - mn) < 62)
    red = (r > 3 * g) & (r * 10 > 22 * b) & (r > 55) & ~skin     # cape/loincloth crimson, not red-brown leather
    return dict(dark=dark, skin=skin | warp, hair=hair, fur=fur, red=red)


def main():
    src = idle_01()
    rgba = np.array(src)
    rgb = np.ascontiguousarray(rgba[:, :, :3])
    alpha = rgba[:, :, 3] > 0
    H, W = alpha.shape
    c = colour_rules(rgb)
    clasp = np.zeros_like(alpha)
    yy, xx = np.mgrid[0:H, 0:W]
    for (cx, cy), rad in CLASPS:
        clasp |= (xx - cx) ** 2 + (yy - cy) ** 2 <= rad ** 2
    handle_l = np.any([poly_mask(p, alpha.shape) for p in HANDLE_L], axis=0)
    handle_r = np.any([poly_mask(p, alpha.shape) for p in HANDLE_R], axis=0)
    rules = {
        "all": np.ones_like(alpha),
        "head": (c["hair"] | c["skin"]) & ~c["fur"] & ~clasp,
        "hair": c["hair"],
        "skin": c["skin"],
        "red": c["red"],
        "mantle_front": (c["fur"] & ~c["skin"]) | clasp,
        "not_red": ~c["red"],
        "axe_L": ~c["red"] | handle_l,
        "axe_R": ~c["red"] | handle_r,
        "red_or_dark": c["red"] | c["dark"],
        "not_handle_L": ~(handle_l & ~c["skin"]),
        "not_handle_R": ~(handle_r & ~c["skin"]),
    }
    layers = DRAW_ORDER
    idx = {n: i for i, n in enumerate(layers)}
    owner = np.full(alpha.shape, -1, int)
    regions = {n: np.zeros_like(alpha) for n in layers}
    for name in CLAIM_ORDER:
        pts, rule = CLAIM[name]
        lay = LAYER_OF.get(name, name)
        reg = poly_mask(pts, alpha.shape)
        regions[lay] |= reg
        take = reg & rules[rule] & alpha & (owner < 0)
        if rule not in ("all", "not_red", "axe_L", "axe_R"):
            take &= ~c["dark"]
            # The occluding layer owns the outline around what it claimed (3 px).
            take |= ndimage.binary_dilation(take, iterations=3) & reg & c["dark"] & alpha & (owner < 0)
        owner[take] = idx[lay]
    # The cape owns its own colour anywhere it isn't claimed.
    regions["cape"] = np.ones_like(alpha)
    owner[(owner < 0) & alpha & c["red"]] = idx["cape"]
    # Unclaimed pixels (outlines, shading): nearest layer, biased to upper layers, and
    # only layers whose region covers the pixel.
    todo = (owner < 0) & alpha
    best = np.full(alpha.shape, np.inf)
    pick = np.full(alpha.shape, idx["cape"])
    for n in layers:
        own = owner == idx[n]
        if not own.any():
            continue
        d = ndimage.distance_transform_edt(~own) - 0.12 * idx[n]
        d[~ndimage.binary_dilation(regions[n], iterations=4)] = np.inf   # fringe pixels just outside
        better = d < best
        best[better] = d[better]
        pick[better] = idx[n]
    owner[todo] = pick[todo]
    # Tidy: specks under 30 px, and stray islands under 300 px away from a layer's main
    # body, join the layer around them (cape, mantle_back and axe_L are naturally split).
    for _ in range(2):
        for i in range(len(layers)):
            lab, n = ndimage.label(owner == i)
            if n == 0:
                continue
            sizes = ndimage.sum(np.ones_like(lab), lab, range(1, n + 1))
            limit = 30 if layers[i] in ("cape", "mantle_back", "axe_L") else 300
            small = [k for k in np.nonzero(sizes < limit)[0] + 1 if k != sizes.argmax() + 1]
            for k in small:
                comp = lab == k
                ring = ndimage.binary_dilation(comp) & ~comp & alpha
                if ring.any():
                    owner[comp] = np.bincount(owner[ring]).argmax()
    assert ((owner >= 0) == alpha).all()

    os.makedirs(os.path.join(OUT, "masks"), exist_ok=True)
    os.makedirs(os.path.join(OUT, "reference"), exist_ok=True)
    report = {}
    for n in layers:
        own = owner == idx[n]
        full = own.copy()
        for shp in HIDDEN.get(n, []):
            full |= shape_mask(shp, alpha.shape)
        if n == "cape":
            # Behind everything: fill a 30 px band inward from its visible edge.
            band = ndimage.binary_dilation(own, iterations=30) & alpha
            full |= band & poly_mask([(0, 200), (300, 190), (300, 600), (440, 600), (440, 430), (0, 470)],
                                     alpha.shape)
        if n == "mantle_back":
            full |= ndimage.binary_dilation(own, iterations=18) & alpha & regions[n]
        # Hidden means hidden: only pixels a higher layer covers in the idle pose, so the
        # full stack still reproduces the original exactly.
        covered = (owner > idx[n]) & (rgba[:, :, 3] >= 250)   # source interiors are alpha 253
        recon = full & ~own & covered
        out = rgba.copy()
        out[:, :, 3] = np.where(own, rgba[:, :, 3], 0)
        if recon.any():
            out[recon, :3] = flat_fill(rgb, own, recon)[recon]
            out[recon, 3] = 255
            # New silhouette edge: a 2 px outline along the part's reconstructed outer edge.
            solid = own | recon
            edge = recon & ~ndimage.binary_erosion(solid, iterations=2)
            out[edge, :3] = OUTLINE
        Image.fromarray(out).save(os.path.join(OUT, n + ".png"))
        Image.fromarray((recon * 255).astype(np.uint8)).save(os.path.join(OUT, "masks", n + "_reconstructed.png"))
        report[n] = {"visible_px": int(own.sum()), "reconstructed_px": int(recon.sum())}

    # Partition check: stacking the visible pixels in draw order == original.
    stack = np.zeros_like(rgba)
    for n in layers:
        own = owner == idx[n]
        stack[own] = rgba[own]
    assert (stack[alpha] == rgba[alpha]).all() and not stack[~alpha, 3].any(), \
        "partition does not reassemble the original"
    full_stack = Image.new("RGBA", (W, H))
    for n in layers:
        full_stack.alpha_composite(Image.open(os.path.join(OUT, n + ".png")))
    # The source's interior alpha is 253, not 255, so a reconstructed pixel under it tints
    # the result by at most ~2% (<= 6 levels). Anything more means something shows through.
    fs = np.array(full_stack).astype(int)
    diff = np.abs(fs - rgba.astype(int))[alpha].max()
    assert diff <= 6, "reconstructed pixels show through in the idle pose (max diff %d)" % diff
    print("full stack vs original: max channel difference %d / 255" % diff)
    # Which layer owns each visible pixel (value = index in DRAW_ORDER, 255 = empty).
    Image.fromarray(np.where(alpha, owner, 255).astype(np.uint8)).save(os.path.join(OUT, "reference", "owner_map.png"))
    build_axe_master(rgba, owner == idx["axe_R"], owner == idx["axe_L"])
    axes = fit_rear_axe(rgba, owner == idx["axe_L"])
    with open(os.path.join(OUT, "layer_report.json"), "w") as f:
        json.dump(report, f, indent=1)
    with open(os.path.join(OUT, "pivots.json"), "w") as f:
        json.dump({"space": "source px of idle_01 (620x655); canvas px = source x %.4f" % (208 / H),
                   "draw_order": layers, "pivots": PIVOTS, "axes": axes}, f, indent=1)
    for n in layers:
        print("%-13s visible %6d px   reconstructed %6d px" % (n, report[n]["visible_px"], report[n]["reconstructed_px"]))


def build_axe_master(rgba, own_r, own_l):
    """Front axe + its handle continued through the fist: the axe is turned so the handle
    is horizontal, a visible 16 px stretch of the wrap is repeated back to the pommel
    end, and the result is turned back."""
    axe = rgba.copy()
    axe[:, :, 3] = np.where(own_r, rgba[:, :, 3], 0)
    rear = rgba.copy()
    rear[:, :, 3] = np.where(own_l, rgba[:, :, 3], 0)
    rimg = Image.fromarray(rear)
    rimg.crop(rimg.getbbox()).save(os.path.join(OUT, "reference", "axe_rear_original.png"))
    collar = (536.0, 394.0)              # where the handle meets the gold collar
    angle = 23.0                         # handle slope (degrees below horizontal, towards the head)
    length = 104.0                       # collar to pommel, as on the rear axe
    img = Image.fromarray(axe)
    flat = img.rotate(angle, resample=Image.BICUBIC, center=collar)       # handle now horizontal
    fa = np.array(flat)
    cx, cy = int(collar[0]), int(collar[1])
    band = fa[cy - 10:cy + 11, cx - 26:cx - 10].copy()                  # visible wrap, 16 px long
    rec = np.zeros(fa.shape[:2], bool)
    x = cx - 26
    while x - 16 > cx - length:
        x -= 16
        tile = band
        dst = fa[cy - 10:cy + 11, x:x + 16]
        put = (dst[:, :, 3] < 128) & (tile[:, :, 3] > 0)
        dst[put] = tile[put]
        rec[cy - 10:cy + 11, x:x + 16] |= put
    # Pommel: a dark outline cap, the width of the handle.
    end = int(cx - length)
    cv2.ellipse(fa, (end + 3, cy), (4, 7), 0, 0, 360, OUTLINE + (255,), -1)
    rec[cy - 7:cy + 8, end - 1:end + 8] = True
    back = Image.fromarray(fa).rotate(-angle, resample=Image.BICUBIC, center=collar)
    recm = Image.fromarray((rec * 255).astype(np.uint8)).rotate(-angle, center=collar)
    # Keep the visible pixels exactly as drawn (the rotation round-trip would soften them).
    out = np.array(back)
    out[own_r] = rgba[own_r]
    recm = np.array(recm) > 127
    recm &= ~own_r
    out[:, :, 3] = np.where(own_r | recm, out[:, :, 3], 0)
    res = Image.fromarray(out)
    bb = res.getbbox()
    res.crop(bb).save(os.path.join(OUT, "axe_master.png"))
    Image.fromarray((recm * 255).astype(np.uint8)).crop(bb).save(
        os.path.join(OUT, "masks", "axe_master_reconstructed.png"))
    with open(os.path.join(OUT, "reference", "axe_master_origin.json"), "w") as f:
        json.dump({"bbox_in_idle01": bb, "collar": collar, "handle_angle_deg": angle}, f)


# Matching points on the two drawn axes (source px): grip and the centre of the gold
# head block. (The blade tips don't correspond: the rear blade is drawn longer.)
AXE_POINTS_R = [(500, 382), (572, 415)]
AXE_POINTS_L = [(112, 362), (45, 430)]


def fit_rear_axe(rgba, own_l):
    """Where axe_master goes in the rear (screen-left) hand: mirrored, then the
    similarity transform (rotate + uniform scale + move) mapping the front axe's grip
    and head points onto the rear axe's. Returned as a 2x3 matrix from
    axe_master.png pixels to idle_01 source pixels. The front axe needs only a move."""
    with open(os.path.join(OUT, "reference", "axe_master_origin.json")) as f:
        bx, by = json.load(f)["bbox_in_idle01"][:2]
    mw = Image.open(os.path.join(OUT, "axe_master.png")).width
    # Master-image coords of the front points, mirrored (x -> mw - 1 - x).
    src = np.float32([(mw - 1 - (x - bx), y - by) for x, y in AXE_POINTS_R])
    dst = np.float32(AXE_POINTS_L)
    m, _ = cv2.estimateAffinePartial2D(src, dst)
    scale = float(np.hypot(m[0, 0], m[1, 0]))
    angle = float(np.degrees(np.arctan2(m[1, 0], m[0, 0])))
    err = np.abs((src @ m[:, :2].T + m[:, 2]) - dst).max()
    # Silhouette overlap with the original rear axe, for the report.
    master = np.array(Image.open(os.path.join(OUT, "axe_master.png")).transpose(Image.FLIP_LEFT_RIGHT))
    warped = cv2.warpAffine(master, m, (own_l.shape[1], own_l.shape[0]))[:, :, 3] > 128
    iou = (warped & own_l).sum() / max((warped | own_l).sum(), 1)
    print("rear axe: mirrored, rotated %.1f deg, scaled %.2f (point error %.1f px), overlap with the drawn "
          "rear axe IoU %.2f" % (angle, scale, err, iou))
    return {"R": {"mirror": False, "matrix": [[1, 0, bx], [0, 1, by]]},
            "L": {"mirror": True, "matrix": m.tolist(), "rotate_deg": round(angle, 1), "scale": round(scale, 3),
                  "iou_with_drawn_rear_axe": round(float(iou), 3)},
            "note": "matrix maps axe_master.png pixels (mirrored first when mirror is true) to idle_01 source px"}


if __name__ == "__main__":
    main()

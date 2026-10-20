"""Inspection images for the Berserker rig layers (build_berserker_layers.py output).

    python3 tools/berserker_layers_preview.py

Writes docs/previews/berserker_layers/:
  component_sheet.png   every layer on its own; magenta tint = reconstructed (hidden) pixels
  reassembled.png       original | layers restacked | master axe in both hands
  comparison.png        those again at gameplay scale (the in-game size), plus a difference map
  exploded.png          layers pulled apart around their joints, showing what was rebuilt
  partition.png         which layer owns each pixel of the drawing, with joint pivots
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from build_berserker_rig import idle_01  # noqa: E402

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
L = os.path.join(ROOT, "valknut/characters/berserker/layers")
OUT = os.path.join(ROOT, "docs/previews/berserker_layers")
BG = (62, 64, 72, 255)
LABELS = {
    "head": "head, hair, beard, neck, braids", "mantle_front": "fur mantle (front, both shoulders)",
    "mantle_back": "fur mantle (back)", "torso": "torso, chest straps, belt",
    "arm_upper_L": "upper arm L", "arm_upper_R": "upper arm R", "arm_fore_L": "forearm + hand L",
    "arm_fore_R": "forearm + hand R", "pelvis": "pelvis, hips, skirt", "loincloth": "hanging cloth",
    "leg_upper_L": "thigh L", "leg_upper_R": "thigh R", "leg_lower_L": "lower leg + boot L",
    "leg_lower_R": "lower leg + boot R", "cape": "cape", "axe_master": "axe (master, both hands)",
}


def on_bg(im):
    bg = Image.new("RGBA", im.size, BG)
    bg.alpha_composite(im)
    return bg


def stack(meta, master_axes=False):
    W, H = Image.open(os.path.join(L, "torso.png")).size
    out = Image.new("RGBA", (W, H))
    for n in meta["draw_order"]:
        if master_axes and n in ("axe_L", "axe_R"):
            out.alpha_composite(place_axe(meta, n[-1], (W, H)))
            continue
        out.alpha_composite(Image.open(os.path.join(L, n + ".png")))
    return out


def place_axe(meta, side, size):
    import cv2
    a = meta["axes"][side]
    m = Image.open(os.path.join(L, "axe_master.png"))
    if a["mirror"]:
        m = m.transpose(Image.FLIP_LEFT_RIGHT)
    out = cv2.warpAffine(np.array(m), np.float32(a["matrix"]), size, flags=cv2.INTER_CUBIC)
    return Image.fromarray(out)


def main():
    os.makedirs(OUT, exist_ok=True)
    meta = json.load(open(os.path.join(L, "pivots.json")))
    orig = idle_01()
    W, H = orig.size

    # Component sheet
    names = ["head", "mantle_front", "mantle_back", "torso", "arm_upper_L", "arm_upper_R", "arm_fore_L",
             "arm_fore_R", "pelvis", "loincloth", "leg_upper_L", "leg_upper_R", "leg_lower_L", "leg_lower_R",
             "cape", "axe_master"]
    cw, ch, cols = 300, 330, 4
    sheet = Image.new("RGB", (cw * cols, ch * ((len(names) + cols - 1) // cols)), (34, 34, 40))
    d = ImageDraw.Draw(sheet)
    for k, n in enumerate(names):
        im = Image.open(os.path.join(L, n + ".png"))
        rec = Image.open(os.path.join(L, "masks", n + "_reconstructed.png"))
        bb = im.getbbox()
        im, rec = im.crop(bb), rec.crop(bb)
        t = on_bg(im)
        tint = Image.alpha_composite(t, Image.new("RGBA", t.size, (255, 0, 255, 120)))
        t.paste(tint, (0, 0), rec)
        t.thumbnail((cw - 16, ch - 40), Image.LANCZOS)
        x, y = (k % cols) * cw, (k // cols) * ch
        sheet.paste(t, (x + 8, y + 34))
        d.text((x + 8, y + 6), "%s.png" % n, fill=(255, 220, 90))
        d.text((x + 8, y + 19), LABELS[n] + ("" if rec.getbbox() is None else "  (magenta = rebuilt)"),
               fill=(200, 200, 210))
    sheet.save(os.path.join(OUT, "component_sheet.png"))

    # Reassembly at full resolution
    restack = stack(meta)
    master = stack(meta, master_axes=True)
    full = Image.new("RGB", (W * 3 + 40, H + 30), (34, 34, 40))
    d = ImageDraw.Draw(full)
    for k, (title, im) in enumerate((("original idle_01", orig), ("layers restacked", restack),
                                      ("master axe in both hands", master))):
        full.paste(on_bg(im), (k * (W + 20), 30))
        d.text((k * (W + 20) + 6, 8), title, fill=(255, 220, 90))
    full.save(os.path.join(OUT, "reassembled.png"))

    # Gameplay scale (208 canvas px tall, shown at 0.5 -> 104 game px) and difference map
    gh = 104
    gw = round(W * gh / H)
    small = [on_bg(im).resize((gw, gh), Image.LANCZOS) for im in (orig, restack, master)]
    a0 = np.array(on_bg(orig)).astype(int)
    diff_r = np.abs(np.array(on_bg(restack)).astype(int) - a0)[:, :, :3].max(2)
    diff_m = np.abs(np.array(on_bg(master)).astype(int) - a0)[:, :, :3].max(2)
    zoom = 3
    comp = Image.new("RGB", (gw * 3 * zoom + 40 + W // 2 * 2 + 20, max(gh * zoom, H // 2) + 50), (34, 34, 40))
    d = ImageDraw.Draw(comp)
    for k, (title, im) in enumerate(zip(("original", "restacked", "master axes"), small)):
        comp.paste(im.resize((gw * zoom, gh * zoom), Image.NEAREST), (k * (gw * zoom + 20), 40))
        d.text((k * (gw * zoom + 20) + 4, 8), "%s - game size %dx%d px, shown x%d" % (title, gw, gh, zoom),
               fill=(255, 220, 90))
    x0 = gw * 3 * zoom + 40
    for k, (title, dm) in enumerate((("difference: restacked (max %d/255)" % diff_r.max(), diff_r),
                                     ("difference: master axes", diff_m))):
        heat = np.clip(dm * 4, 0, 255).astype(np.uint8)
        img = Image.fromarray(np.stack([heat, heat // 3, heat // 3], -1)).resize((W // 2, H // 2), Image.BILINEAR)
        comp.paste(img, (x0 + k * (W // 2 + 10), 40))
        d.text((x0 + k * (W // 2 + 10) + 4, 8), title, fill=(255, 220, 90))
    comp.save(os.path.join(OUT, "comparison.png"))

    # Exploded view: each layer pushed away from the body centre
    cx, cy = 345, 330
    ex = Image.new("RGBA", (int(W * 1.6), int(H * 1.5)), BG)
    offx, offy = int(W * 0.3), int(H * 0.25)
    for n in meta["draw_order"]:
        im = Image.open(os.path.join(L, n + ".png"))
        rec = Image.open(os.path.join(L, "masks", n + "_reconstructed.png"))
        tint = Image.alpha_composite(im, Image.new("RGBA", im.size, (255, 0, 255, 90)))
        shown = im.copy()
        shown.paste(tint, (0, 0), rec)
        bb = im.getbbox()
        mx, my = (bb[0] + bb[2]) / 2, (bb[1] + bb[3]) / 2
        dx, dy = (mx - cx) * 0.45, (my - cy) * 0.35
        if n in ("cape", "mantle_back"):
            dx, dy = dx * 0.3, dy * 0.3
        ex.alpha_composite(shown, (int(offx + dx), int(offy + dy)))
    ex.save(os.path.join(OUT, "exploded.png"))
    # Partition map
    owner = np.array(Image.open(os.path.join(L, "reference", "owner_map.png"))).astype(int)
    pal = np.array([(120, 0, 0), (110, 70, 30), (0, 90, 200), (0, 160, 255), (0, 200, 120), (0, 255, 180),
                    (200, 200, 0), (255, 40, 40), (255, 140, 0), (160, 0, 255), (255, 0, 255), (255, 255, 255),
                    (255, 220, 0), (0, 255, 0), (0, 140, 0), (80, 80, 255), (255, 120, 200)])
    src = np.array(orig)
    vis = owner < 255
    col = pal[np.clip(owner, 0, len(pal) - 1)]
    mix = np.where(vis[:, :, None], src[:, :, :3] * 0.45 + col * 0.55, 50).astype(np.uint8)
    edge = np.zeros(vis.shape, bool)
    edge[:-1] |= owner[:-1] != owner[1:]
    edge[:, :-1] |= owner[:, :-1] != owner[:, 1:]
    mix[edge & vis] = 0
    pm = Image.fromarray(mix).resize((W * 2, H * 2), Image.NEAREST)
    d = ImageDraw.Draw(pm)
    for k, n in enumerate(meta["draw_order"]):
        d.rectangle([6, 6 + k * 18, 20, 20 + k * 18], fill=tuple(int(v) for v in pal[k]))
        d.text((26, 7 + k * 18), "%d %s" % (k, n), fill="white")
    for name, (x, y) in meta["pivots"].items():
        d.ellipse([2 * x - 6, 2 * y - 6, 2 * x + 6, 2 * y + 6], outline=(0, 255, 255), width=3)
        d.text((2 * x + 8, 2 * y - 6), name, fill=(0, 255, 255))
    pm.save(os.path.join(OUT, "partition.png"))
    print("restacked vs original: max %d/255; master axes differ at %d px (rear axe redrawn by the master)"
          % (diff_r.max(), int((diff_m > 24).sum())))


if __name__ == "__main__":
    main()

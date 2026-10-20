"""Inspection images for the repaired Berserker layers (tools/repair_berserker_layers.py).

    python3 tools/berserker_repair_preview.py

Writes docs/previews/berserker_repair/: idle_identity.png, layers_repaired.png,
shoulder_compare.png, torso_compare.png, stress_shoulder_{before,after}.png,
stress_torso_{before,after}.png, gameplay_scale.png, torso_3q_feasibility.png.
"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from berserker_layer_stress import (SHOULDER_CASES, TORSO_CASES, load_layers, pose, sheet)  # noqa: E402
from build_berserker_rig import idle_01  # noqa: E402

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
BEFORE = os.path.join(ROOT, "valknut/characters/berserker/layers")
AFTER = os.path.join(ROOT, "valknut/characters/berserker/layers_repaired")
OUT = os.path.join(ROOT, "docs/previews/berserker_repair")
BG = (40, 42, 52, 255)
GOLD = (255, 220, 90)


def on_bg(im):
    b = Image.new("RGBA", im.size, BG)
    b.alpha_composite(im.convert("RGBA"))
    return b.convert("RGB")


def label(img, text, xy=(6, 5)):
    ImageDraw.Draw(img).text(xy, text, fill=GOLD)
    return img


def row(tiles, pad=4):
    w = sum(t.width for t in tiles) + pad * (len(tiles) - 1)
    s = Image.new("RGB", (w, max(t.height for t in tiles)), (20, 20, 26))
    x = 0
    for t in tiles:
        s.paste(t, (x, 0))
        x += t.width + pad
    return s


def main():
    os.makedirs(OUT, exist_ok=True)
    lb, la = load_layers(BEFORE), load_layers(AFTER)
    orig = idle_01()
    # 1-2 idle identity
    ref = on_bg(orig)
    rest_b, rest_a = on_bg(pose(lb, {})), on_bg(pose(la, {}))
    diff = np.abs(np.array(rest_a).astype(int) - np.array(ref).astype(int)).max(2)
    heat = Image.fromarray(np.clip(diff * 40, 0, 255).astype(np.uint8)).convert("RGB")
    row([label(ref.copy(), "original approved idle"), label(rest_a.copy(), "repaired layers restacked"),
         label(heat, "difference x40 (max %d / 255)" % diff.max())]).save(os.path.join(OUT, "idle_identity.png"))
    # 3-4 shoulder / torso, original vs reconstructed (isolated layers, new pixels tinted)
    def isolated(name, box, k=3):
        tiles = []
        for title, folder in (("%s: before (flat fill)" % name, BEFORE), ("%s: after (repaired)" % name, AFTER)):
            im = Image.open(os.path.join(folder, name + ".png"))
            m = Image.open(os.path.join(folder, "masks", name + ("_reconstructed.png" if folder == BEFORE else "_new.png")))
            b = Image.new("RGBA", im.size, BG)
            b.alpha_composite(im)
            tint = Image.alpha_composite(b, Image.new("RGBA", im.size, (255, 0, 255, 70)))
            b.paste(tint, (0, 0), m)
            t = b.convert("RGB").crop(box)
            tiles.append(label(t.resize((t.width * k, t.height * k), Image.NEAREST), title))
        return row(tiles)
    isolated("arm_upper_L", (120, 120, 320, 320)).save(os.path.join(OUT, "shoulder_compare.png"))
    isolated("torso", (195, 105, 475, 320), 2).save(os.path.join(OUT, "torso_compare.png"))
    # 6 cape and fur layers
    tiles = []
    for name in ("cape", "mantle_back", "mantle_front"):
        pair = []
        for title, folder in (("before", BEFORE), ("after", AFTER)):
            im = Image.open(os.path.join(folder, name + ".png"))
            t = on_bg(im).resize((310, 327), Image.LANCZOS)
            pair.append(label(t, "%s %s" % (name, title)))
        tiles.append(row(pair))
    s = Image.new("RGB", (tiles[0].width, sum(t.height for t in tiles) + 8), (20, 20, 26))
    y = 0
    for t in tiles:
        s.paste(t, (0, y))
        y += t.height + 4
    s.save(os.path.join(OUT, "layers_repaired.png"))
    # 7-8 stress sheets
    for tag, loaded in (("before", lb), ("after", la)):
        sheet(loaded, SHOULDER_CASES, os.path.join(OUT, "stress_shoulder_%s.png" % tag), (0, 0, 620, 655), 0.55, 5,
              "rear shoulder rotation, %s" % tag)
        sheet(loaded, TORSO_CASES, os.path.join(OUT, "stress_torso_%s.png" % tag), (0, 0, 620, 655), 0.55, 5,
              "torso (spine) rotation, %s" % tag)
    # actual gameplay scale: 98x104 px figure, shown 1:1 and 3x nearest
    cases = [("0", {}), ("sh+25", {"ShoulderL": 25}), ("sh+45", {"ShoulderL": 45}), ("sh+60", {"ShoulderL": 60}),
             ("sh+90", {"ShoulderL": 90}), ("spine+25", {"Spine": 25}), ("spine-25", {"Spine": -25})]
    rows = []
    for tag, loaded in (("before", lb), ("after", la)):
        tiles = []
        for name, ang in cases:
            im = on_bg(pose(loaded, ang)).resize((98, 104), Image.LANCZOS)
            tiles.append(label(im.resize((98 * 3, 104 * 3), Image.NEAREST), "%s %s" % (tag, name), (4, 3)))
        rows.append(row(tiles, 2))
    s = Image.new("RGB", (rows[0].width, rows[0].height * 2 + 4))
    s.paste(rows[0], (0, 0))
    s.paste(rows[1], (0, rows[0].height + 4))
    s.save(os.path.join(OUT, "gameplay_scale.png"))
    print("done")


if __name__ == "__main__":
    main()

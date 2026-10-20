"""Poses the Berserker's 17 layers on the rig's pivots, in Python, to inspect what a
rotation exposes. It follows the same hierarchy and rotation convention as the Godot rig
(berserker_fullrig_rig.tscn; positive = clockwise on screen) but works at the source
resolution (620x655) and on ANY layer folder, so repaired layers can be reviewed without
touching the rig textures.

    python3 tools/berserker_layer_stress.py <layers_dir> <out_dir> [--tag NAME]

Writes <out_dir>/shoulder_<tag>.png and torso_<tag>.png (labelled stress sheets).
The module's `pose()` is reused by the other reconstruction tools.
"""
import json
import math
import os
import sys

import cv2
import numpy as np
from PIL import Image, ImageDraw

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
LAYERS = os.path.join(ROOT, "valknut/characters/berserker/layers")
BG = (40, 42, 52)

# bone: (parent, pivot point in source px)
def _bones(piv):
    return {
        "Hips": (None, (321, 404)),
        "ThighL": ("Hips", piv["hip_L"]), "ShinL": ("ThighL", piv["knee_L"]),
        "ThighR": ("Hips", piv["hip_R"]), "ShinR": ("ThighR", piv["knee_R"]),
        "Cape": ("Hips", (330, 200)),
        "Spine": ("Hips", piv["spine_root"]), "Neck": ("Spine", piv["neck"]),
        "ShoulderL": ("Spine", piv["shoulder_L"]), "ElbowL": ("ShoulderL", piv["elbow_L"]),
        "AxeL": ("ElbowL", piv["grip_L"]),
        "ShoulderR": ("Spine", piv["shoulder_R"]), "ElbowR": ("ShoulderR", piv["elbow_R"]),
        "AxeR": ("ElbowR", piv["grip_R"]),
    }


BONE_OF = {
    "cape": "Cape", "mantle_back": "Spine", "leg_lower_L": "ShinL", "leg_lower_R": "ShinR",
    "leg_upper_L": "ThighL", "leg_upper_R": "ThighR", "pelvis": "Hips", "loincloth": "Hips",
    "torso": "Spine", "arm_upper_L": "ShoulderL", "arm_upper_R": "ShoulderR", "mantle_front": "Spine",
    "head": "Neck", "axe_L": "AxeL", "axe_R": "AxeR", "arm_fore_L": "ElbowL", "arm_fore_R": "ElbowR",
}


def _rot_about(deg, p):
    t = math.radians(deg)
    c, s = math.cos(t), math.sin(t)
    x, y = p
    return np.array([[c, -s, x - c * x + s * y], [s, c, y - s * x - c * y], [0, 0, 1]], float)


def world_matrices(angles, piv):
    bones = _bones(piv)
    out = {}

    def solve(name):
        if name in out:
            return out[name]
        parent, p = bones[name]
        base = np.eye(3) if parent is None else solve(parent)
        out[name] = base @ _rot_about(angles.get(name, 0.0), p)
        return out[name]

    for b in bones:
        solve(b)
    return out


def load_layers(folder):
    meta = json.load(open(os.path.join(LAYERS, "pivots.json")))
    order = meta["draw_order"]
    layers = {n: np.array(Image.open(os.path.join(folder, n + ".png")).convert("RGBA")) for n in order}
    return meta, order, layers


def pose(folder_or_loaded, angles, size=None):
    """RGBA image of the layers posed by `angles` ({bone: degrees})."""
    meta, order, layers = (load_layers(folder_or_loaded) if isinstance(folder_or_loaded, str)
                           else folder_or_loaded)
    mats = world_matrices(angles, meta["pivots"])
    h, w = layers[order[0]].shape[:2]
    out = Image.new("RGBA", (w, h))
    for n in order:
        m = mats[BONE_OF[n]]
        warped = cv2.warpAffine(layers[n], m[:2], (w, h), flags=cv2.INTER_CUBIC, borderValue=(0, 0, 0, 0))
        out.alpha_composite(Image.fromarray(warped))
    return out


def sheet(loaded, cases, out_path, crop, k=0.75, cols=5, title=""):
    tiles = []
    for label, angles in cases:
        im = pose(loaded, angles)
        bg = Image.new("RGBA", im.size, BG + (255,))
        bg.alpha_composite(im)
        t = bg.convert("RGB").crop(crop)
        t = t.resize((int(t.width * k), int(t.height * k)), Image.LANCZOS)
        ImageDraw.Draw(t).text((6, 5), label, fill=(255, 220, 90))
        tiles.append(t)
    w, h = tiles[0].size
    rows = (len(tiles) + cols - 1) // cols
    s = Image.new("RGB", (w * cols, h * rows + (18 if title else 0)), (20, 20, 26))
    if title:
        ImageDraw.Draw(s).text((6, 3), title, fill=(255, 255, 255))
    for i, t in enumerate(tiles):
        s.paste(t, ((i % cols) * w, (i // cols) * h + (18 if title else 0)))
    s.save(out_path)


SHOULDER_CASES = [("shoulder_L %+d" % a, {"ShoulderL": a}) for a in (0, 25, 45, 60, 90, -25, -45, -60, -90)]
TORSO_CASES = [("spine %+d" % a, {"Spine": a}) for a in (0, 10, 15, 25, 35, -10, -15, -25, -35)]


def main():
    folder, out = sys.argv[1], sys.argv[2]
    tag = sys.argv[sys.argv.index("--tag") + 1] if "--tag" in sys.argv else "layers"
    os.makedirs(out, exist_ok=True)
    loaded = load_layers(folder)
    sheet(loaded, SHOULDER_CASES, os.path.join(out, "shoulder_%s.png" % tag), (0, 0, 620, 655), 0.55, 5,
          "rear (screen-left) shoulder rotation: " + tag)
    sheet(loaded, TORSO_CASES, os.path.join(out, "torso_%s.png" % tag), (0, 0, 620, 655), 0.55, 5,
          "spine (torso) rotation: " + tag)


if __name__ == "__main__":
    main()

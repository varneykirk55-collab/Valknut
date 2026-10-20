"""Builds the Berserker's full-body cutout rig (art set "fullrig") from the 17 layers.

    python3 tools/build_berserker_fullrig.py

Needs Pillow + numpy. Reads valknut/characters/berserker/layers/ (see
BERSERKER_LAYERS_REPORT.md) and writes

  valknut/characters/berserker/fullrig/<layer>.png        layers at 2x game scale, cropped
  valknut/characters/berserker/berserker_fullrig_rig.tscn Skeleton2D + Bone2D + sprites
  valknut/characters/berserker/berserker_fullrig_data.gd  rest geometry used by the IK

Nothing is redrawn: every layer is the existing PNG, scaled by the same factor as the v2
sprites (0.3176, so idle_01 is 208 px tall) and cropped to its bounds. The rig is shown
at scale 0.5, like the v2 art set, so one rig unit is one canvas px = 0.5 game px.

Structure. Bones carry no art. Each layer is a Sprite2D under "Layers", in the drawing's
own stacking order (so two fighters never interleave their body parts), and follows its
bone through a RemoteTransform2D that sits under that bone. Both axes are Sprite2Ds of the
SAME axe_master.png texture, same scale; the rear one is mirrored with flip_h and turned
to meet its grip (pivots.json -> axes).

    Skeleton
      Hips                     pelvis, loincloth
        ThighL > ShinL         leg_upper_L > leg_lower_L (+ FootL marker)
        ThighR > ShinR
        Cape                   cape (hangs from the hips, swings on a lag)
        Spine                  mantle_back, mantle_front
          Chest                torso (scaled in x to fake a twist)
          Neck                 head
          ShoulderL > ElbowL > AxeL        arm_upper_L > arm_fore_L, axe (grip pivot)
          ShoulderR > ElbowR > AxeR        arm_upper_R > arm_fore_R, axe (grip pivot)
"""
import json
import math
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from build_berserker_rig import idle_01, feet_mid  # noqa: E402

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
CHAR = os.path.join(ROOT, "valknut/characters/berserker")
LAYERS = os.path.join(CHAR, "layers")
OUT = os.path.join(CHAR, "fullrig")
SCENE = os.path.join(CHAR, "berserker_fullrig_rig.tscn")
DATA = os.path.join(CHAR, "berserker_fullrig_data.gd")
DISPLAY = 0.5
HEIGHT = 208

# bone: (parent, pivot name in pivots.json or a source-px point)
BONES = [
    ("Hips", None, (321, 404)),
    ("ThighL", "Hips", "hip_L"), ("ShinL", "ThighL", "knee_L"),
    ("ThighR", "Hips", "hip_R"), ("ShinR", "ThighR", "knee_R"),
    ("Spine", "Hips", "spine_root"),
    ("Cape", "Hips", (330, 200)),
    ("Chest", "Spine", "spine_root"),
    ("Neck", "Spine", "neck"),
    ("ShoulderL", "Spine", "shoulder_L"), ("ElbowL", "ShoulderL", "elbow_L"), ("AxeL", "ElbowL", "grip_L"),
    ("ShoulderR", "Spine", "shoulder_R"), ("ElbowR", "ShoulderR", "elbow_R"), ("AxeR", "ElbowR", "grip_R"),
]
BONE_OF = {
    "cape": "Cape", "mantle_back": "Spine", "leg_lower_L": "ShinL", "leg_lower_R": "ShinR",
    "leg_upper_L": "ThighL", "leg_upper_R": "ThighR", "pelvis": "Hips", "loincloth": "Hips",
    "torso": "Chest", "arm_upper_L": "ShoulderL", "arm_upper_R": "ShoulderR", "mantle_front": "Spine",
    "head": "Neck", "axe_L": "AxeL", "axe_R": "AxeR", "arm_fore_L": "ElbowL", "arm_fore_R": "ElbowR",
}


def main():
    meta = json.load(open(os.path.join(LAYERS, "pivots.json")))
    src = idle_01()
    src_full = np.array(src)
    H = src.height
    s = HEIGHT / H
    feet = np.array([feet_mid(src) * s, H * s])               # rig origin, canvas px
    piv = {k: np.array(v, float) for k, v in meta["pivots"].items()}

    def rig(p):                                                # source px -> rig space
        return np.array(p, float) * s - feet

    glob = {}
    for name, parent, pv in BONES:
        glob[name] = rig(piv[pv] if isinstance(pv, str) else pv)
    local = {n: glob[n] - (glob[p] if p else 0) for n, p, _ in BONES}
    parent_of = {n: p for n, p, _ in BONES}

    os.makedirs(OUT, exist_ok=True)
    order = meta["draw_order"]
    tex, place = {}, {}
    dropped = {}
    for n in order:
        if n.startswith("axe_"):
            continue
        im = Image.open(os.path.join(LAYERS, n + ".png"))
        im, dropped[n] = drop_islands(im, n)
        im = bleed_edges(im, src_full)
        bb = im.getbbox()
        im = im.crop(bb)
        im = im.resize((max(1, round(im.width * s)), max(1, round(im.height * s))), Image.LANCZOS)
        im.save(os.path.join(OUT, n + ".png"))
        tex[n] = n
        place[n] = (rig((bb[0], bb[1])), 0.0, False)           # sprite origin (top-left), rotation, flip
    master = Image.open(os.path.join(LAYERS, "axe_master.png"))
    mw = master.width
    master.resize((round(master.width * s), round(master.height * s)), Image.LANCZOS).save(
        os.path.join(OUT, "axe_master.png"))
    origin = json.load(open(os.path.join(LAYERS, "reference", "axe_master_origin.json")))
    bx, by = origin["bbox_in_idle01"][:2]
    gR = np.array(piv["grip_R"]) - (bx, by)                      # master px
    place["axe_R"] = (rig((bx, by)), 0.0, False)
    # Rear hand: the same texture, mirrored, turned so grip -> head matches the drawn rear axe.
    hR = np.array((572.0, 415.0)) - (bx, by)
    gm = np.array((mw - gR[0], gR[1]))
    v = np.array((mw - hR[0], hR[1])) - gm
    w = np.array((45.0, 430.0)) - np.array((112.0, 362.0))     # drawn rear axe: grip -> head block
    ang = math.atan2(w[1], w[0]) - math.atan2(v[1], v[0])
    c, sn = math.cos(ang), math.sin(ang)
    t = rig(piv["grip_L"]) - np.array([[c, -sn], [sn, c]]) @ (gm * s)
    place["axe_L"] = (t, ang, True)
    tex["axe_R"] = tex["axe_L"] = "axe_master"

    # ---- scene ----
    ext, nodes = [], []
    tid = {}
    for tname in sorted(set(tex.values())):
        tid[tname] = "%d_%s" % (len(tid) + 1, tname)
        ext.append('[ext_resource type="Texture2D" path="res://valknut/characters/berserker/fullrig/%s.png" id="%s"]'
                   % (tname, tid[tname]))
    v2 = lambda p: "Vector2(%.3f, %.3f)" % (p[0], p[1])
    out = ["[gd_scene load_steps=%d format=3]" % (len(tid) + 1), ""] + ext + [""]
    out += ['[node name="BerserkerFullRig" type="Node2D"]', "texture_filter = 4",
            "scale = Vector2(%g, %g)" % (DISPLAY, DISPLAY),
            'metadata/animates = PackedStringArray("idle", "jab1")', "",
            '[node name="Layers" type="Node2D" parent="."]', ""]
    for n in order:
        o, r, flip = place[n]
        out += ['[node name="%s" type="Sprite2D" parent="Layers"]' % n,
                'texture = ExtResource("%s")' % tid[tex[n]], "centered = false",
                "position = %s" % v2(o)]
        if r:
            out.append("rotation = %.6f" % r)
        if flip:
            out.append("flip_h = true")
        out.append("")
    out += ['[node name="Skeleton" type="Skeleton2D" parent="."]', ""]

    def bone_path(name):
        chain = []
        while name:
            chain.append(name)
            name = parent_of[name]
        return "/".join(["Skeleton"] + chain[::-1])

    for name, parent, _ in BONES:
        out += ['[node name="%s" type="Bone2D" parent="%s"]' % (name, bone_path(parent) if parent else "Skeleton"),
                "position = %s" % v2(local[name]),
                "rest = Transform2D(1, 0, 0, 1, %.3f, %.3f)" % tuple(local[name]),
                "auto_calculate_length_and_angle = false", "length = 20.0", ""]
    for n in order:
        b = BONE_OF[n]
        o, r, _ = place[n]
        depth = len(bone_path(b).split("/")) + 1                  # RemoteTransform2D sits one level below the bone
        rel = "../" * depth + "Layers/" + n
        out += ['[node name="%s_rt" type="RemoteTransform2D" parent="%s"]' % (n, bone_path(b)),
                'remote_path = NodePath("%s")' % rel, "position = %s" % v2(o - glob[b])]
        if r:
            out.append("rotation = %.6f" % r)
        out.append("")
    for side in "LR":                                              # foot markers (planted-feet test)
        knee = glob["Shin" + side]
        foot = foot_point(side, s, feet, src)
        out += ['[node name="Foot%s" type="Marker2D" parent="%s"]' % (side, bone_path("Shin" + side)),
                "position = %s" % v2(foot - knee), ""]
    open(SCENE, "w").write("\n".join(out))

    # ---- rest geometry for the IK ----
    foot = {k: foot_point(k, s, feet, src) for k in "LR"}
    lines = ["# Generated by tools/build_berserker_fullrig.py: rest geometry of the fullrig, rig-space canvas px.",
             "# Do not edit; rerun the tool.", ""]
    g = lambda name, p: "const %s := Vector2(%.3f, %.3f)" % (name, p[0], p[1])
    lines.append(g("HIPS", glob["Hips"]))
    for k in "LR":
        lines += [g("THIGH_" + k, local["Thigh" + k]), g("KNEE_" + k, local["Shin" + k]),
                  g("FOOT_" + k, foot[k] - glob["Shin" + k])]
    for n in ("Spine", "Chest", "Neck", "ShoulderL", "ShoulderR", "ElbowL", "ElbowR", "AxeL", "AxeR", "Cape"):
        lines.append(g("POS_" + n.upper(), local[n]))
    lines.append(g("POS_HIPS", glob["Hips"]))
    lines.append("const SCALE_CANVAS_PER_SRC := %.6f" % s)
    open(DATA, "w").write("\n".join(lines) + "\n")
    for n, g in dropped.items():
        if g:
            print("dropped detached fragments from %s (x, y, px in source): %s" % (n, g))
    print("layers: %d, bones: %d, canvas scale %.4f, feet anchor at source x=%.1f" % (len(order), len(BONES), s, feet[0] / s))
    print("rear axe turned %.1f deg (same texture, same scale, mirrored)" % math.degrees(ang))


BLEED = 3   # source px


def bleed_edges(im, original):
    """Grows a layer's silhouette by BLEED px, filling the new pixels with the ORIGINAL
    drawing's pixels at those positions. At rest the result is identical (the same colours
    already sit there), but when each layer is later downscaled separately its soft edge no
    longer lets the background leak through the border it shares with a neighbour (the
    thin dark seams along fur, cuffs and boot tops)."""
    from scipy import ndimage
    a = np.array(im)
    have = a[:, :, 3] > 0
    grow = ndimage.binary_dilation(have, iterations=BLEED) & ~have & (original[:, :, 3] > 0)
    a[grow] = original[grow]
    return Image.fromarray(a)


# Detached fragments that float once the body moves (see BERSERKER_FULLRIG_DEFECTS.md).
# layer: predicate on (centre x, centre y, pixels) in source px.
DROP_ISLANDS = {"cape": lambda cx, cy, px: cx > 480 and px < 800}


def drop_islands(im, name):
    rule = DROP_ISLANDS.get(name)
    if rule is None:
        return im, []
    from scipy import ndimage
    a = np.array(im)
    lab, k = ndimage.label(a[:, :, 3] > 0)
    gone = []
    for i in range(1, k + 1):
        m = lab == i
        cy, cx = ndimage.center_of_mass(m)
        if rule(cx, cy, int(m.sum())):
            a[m] = 0
            gone.append((int(cx), int(cy), int(m.sum())))
    return Image.fromarray(a), gone


def foot_point(side, s, feet, src):
    """Ground contact of a boot: centre of its lowest 8 source rows, in rig space."""
    im = np.array(Image.open(os.path.join(LAYERS, "leg_lower_%s.png" % side)))[:, :, 3] > 0
    ys = np.nonzero(im.any(1))[0]
    bottom = ys.max()
    xs = np.nonzero(im[bottom - 7:bottom + 1].any(0))[0]
    return np.array(((xs.min() + xs.max()) / 2.0, bottom + 1.0)) * s - feet


if __name__ == "__main__":
    main()

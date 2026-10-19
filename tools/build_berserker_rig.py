"""Builds the Berserker's cutout rig (art set "rig") from the approved idle_01 drawing.

    python3 tools/build_berserker_rig.py

Nothing is drawn or invented: every pixel comes from idle_01 (pose 1 of
art/source/berserker_v2_idle_v2/berserker_v2_idle_strip.png), scaled by the same
factor as the v2 frames. Two parts:

  body.png          the whole drawing minus the front forearm, which leaves a hole that
                    the forearm covers at rest. The upper arm stays on the body because
                    no drawn outline separates it from the chest (a shoulder joint would
                    cut a fake seam through the torso). The elbow's fur cuff also stays
                    on the body as a static copy so the joint never opens up.
  forearm_axe.png   fur cuff, bracer, hand and axe as ONE rigid piece, so the hand can
                    never slip off the handle and the axe is the approved drawing.

Writes valknut/characters/berserker/rig/{body,forearm_axe}.png and
valknut/characters/berserker/berserker_rig_rig.tscn (Skeleton2D > Bone2D "Elbow").
Needs Pillow + numpy.
"""
import os
import numpy as np
from PIL import Image, ImageDraw
from import_strip import segments, feet_mid

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
STRIP = os.path.join(ROOT, "valknut/art/source/berserker_v2_idle_v2/berserker_v2_idle_strip.png")
OUT = os.path.join(ROOT, "valknut/characters/berserker/rig")
SCENE = os.path.join(ROOT, "valknut/characters/berserker/berserker_rig_rig.tscn")
HEIGHT = 208          # same as import_strip for the idle set: idle_01 is 208 canvas px tall
DISPLAY = 0.5         # canvas px -> game px (same as the v2 SpriteFrames)

# Source-pixel geometry, measured on idle_01 (the pose cropped to its bounds).
ELBOW = (462, 284)    # centre of the elbow's fur cuff
FOREARM = [(452, 330), (418, 306), (434, 297), (448, 289), (460, 278), (468, 265), (474, 254),
           (488, 251), (506, 262), (540, 296), (546, 350), (598, 376), (626, 410), (626, 580),
           (498, 580), (500, 430), (478, 410), (462, 380), (452, 340)]
CUFF = [(414, 308), (474, 252), (510, 260), (504, 280), (462, 304), (432, 324)]


def idle_01() -> Image.Image:
    strip = Image.open(STRIP).convert("RGBA")
    ap = strip.getchannel("A").point(lambda v: 255 if v > 128 else 0).load()
    x0, x1 = next(c for c in segments(lambda x: any(ap[x, y] for y in range(strip.height)), strip.width)
                  if c[1] - c[0] > 40)
    pose = strip.crop((x0, 0, x1, strip.height))
    return pose.crop(pose.getchannel("A").point(lambda v: 255 if v > 128 else 0).getbbox())


def main():
    src = idle_01()
    w, h = src.size
    a = np.array(src)
    alpha = a[:, :, 3] > 0

    def poly(pts):
        m = Image.new("L", (w, h), 0)
        ImageDraw.Draw(m).polygon(pts, fill=255)
        return np.array(m) > 0

    fore = poly(FOREARM) & alpha
    body = alpha & ~(fore & ~poly(CUFF))
    s = HEIGHT / h
    size = (round(w * s), round(h * s))
    os.makedirs(OUT, exist_ok=True)
    for name, mask in (("body", body), ("forearm_axe", fore)):
        layer = a.copy()
        layer[:, :, 3] = np.where(mask, a[:, :, 3], 0)
        Image.fromarray(layer).resize(size, Image.LANCZOS).save(os.path.join(OUT, name + ".png"))
    mid = feet_mid(src)
    feet = (mid * s, h * s)                      # canvas px, feet anchor inside the parts
    elbow = (ELBOW[0] * s, ELBOW[1] * s)
    v = lambda p: "Vector2(%.2f, %.2f)" % p
    with open(SCENE, "w") as f:
        f.write("""[gd_scene load_steps=3 format=3]

[ext_resource type="Texture2D" path="res://valknut/characters/berserker/rig/body.png" id="1_body"]
[ext_resource type="Texture2D" path="res://valknut/characters/berserker/rig/forearm_axe.png" id="2_fore"]

[node name="BerserkerRig" type="Node2D"]
texture_filter = 4
scale = Vector2(%(d)s, %(d)s)
metadata/animates = PackedStringArray("idle", "jab1")

[node name="Body" type="Sprite2D" parent="."]
texture = ExtResource("1_body")
centered = false
position = %(body)s

[node name="Skeleton" type="Skeleton2D" parent="."]

[node name="Elbow" type="Bone2D" parent="Skeleton"]
position = %(elbow)s
rest = Transform2D(1, 0, 0, 1, %(ex).2f, %(ey).2f)
auto_calculate_length_and_angle = false
length = 60.0

[node name="ForearmAxe" type="Sprite2D" parent="Skeleton/Elbow"]
texture = ExtResource("2_fore")
centered = false
position = %(fore)s
""" % {"d": DISPLAY, "body": v((-feet[0], -feet[1])), "elbow": v((elbow[0] - feet[0], elbow[1] - feet[1])),
       "ex": elbow[0] - feet[0], "ey": elbow[1] - feet[1], "fore": v((-elbow[0], -elbow[1]))})
    print("parts %dx%d, scale %.4f, feet anchor (%.1f, %.1f), elbow at %s from the feet (canvas px)"
          % (size[0], size[1], s, feet[0], feet[1], v((elbow[0] - feet[0], elbow[1] - feet[1]))))


if __name__ == "__main__":
    main()

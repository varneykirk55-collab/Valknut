"""Writes valknut/characters/<legend>/<legend>_frames.tres from the frames folder.

  python3 tools/build_sprite_frames.py

Every base pose and every pose slot in pose_slots.py becomes a one-frame animation named
after it (the game's AnimationPlayer keys AnimatedSprite2D.animation by these names).
Slots without their own <legend>_<slot>.png use the slot's fallback frame and are listed
in the resource's `placeholders` metadata; the game shows them in the F1 debug view.
Also kept for editor use: "walk" (4 frames) and "attack" (startup/active/recovery).
"""
import os
from pose_slots import BASE, SLOTS, TRANSITIONS

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
CHARS = os.path.join(ROOT, "valknut", "characters")


def build(legend: str) -> list:
    frames_dir = os.path.join(CHARS, legend, "frames")
    poses = {p: p for p in BASE}
    for pose in TRANSITIONS.get(legend, []):
        if os.path.exists(os.path.join(frames_dir, "%s_%s.png" % (legend, pose))):
            poses[pose] = pose
    placeholders = []
    for slot, (fallback, _wide, _brief) in SLOTS[legend].items():
        if os.path.exists(os.path.join(frames_dir, "%s_%s.png" % (legend, slot))):
            poses[slot] = slot
        else:
            poses[slot] = fallback
            placeholders.append(slot)
    files = sorted(set(poses.values()))
    ids = {f: "%d_%s" % (i + 1, f) for i, f in enumerate(files)}
    out = ['[gd_resource type="SpriteFrames" load_steps=%d format=3]' % (len(files) + 1), ""]
    for f in files:
        out.append('[ext_resource type="Texture2D" path="res://valknut/characters/%s/frames/%s_%s.png" id="%s"]'
                   % (legend, legend, f, ids[f]))

    def anim(name, textures, speed=1.0, loop=False):
        fr = ", ".join('{\n"duration": 1.0,\n"texture": ExtResource("%s")\n}' % ids[t] for t in textures)
        return '{\n"frames": [%s],\n"loop": %s,\n"name": &"%s",\n"speed": %s\n}' % (
            fr, "true" if loop else "false", name, speed)

    anims = [anim(p, [poses[p]]) for p in poses]
    anims.append(anim("walk", ["walk_01", "walk_02", "walk_03", "walk_04"], 8.0, True))
    anims.append(anim("attack", ["attack_startup", "attack_active", "attack_recovery"], 10.0))
    out += ["", "[resource]",
            "metadata/placeholders = PackedStringArray(%s)" % ", ".join('"%s"' % p for p in placeholders),
            "animations = [%s]" % ", ".join(anims), ""]
    with open(os.path.join(CHARS, legend, "%s_frames.tres" % legend), "w") as fh:
        fh.write("\n".join(out))
    return placeholders


if __name__ == "__main__":
    for legend in SLOTS:
        ph = build(legend)
        drawn = len(SLOTS[legend]) - len(ph)
        print("%-10s %d/%d combo+heavy slots drawn, %d placeholder(s)" % (legend, drawn, len(SLOTS[legend]), len(ph)))

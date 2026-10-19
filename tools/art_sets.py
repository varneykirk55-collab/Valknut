"""Art sets: a legend's alternative drawings, swapped in at runtime without touching
timing, moves or hitboxes (Game.art_sets picks one per legend).

    python3 tools/art_sets.py

Writes valknut/characters/<legend>/<legend>_<set>_frames.tres from frames_<set>/. Every
pose name the legend's animations use (pose_slots.BASE + SLOTS, plus the set's own
poses) gets an animation. A pose with its own <legend>_<pose>.png is used as drawn;
otherwise its alias (if drawn), otherwise the set's stand-in — and it is listed in the
`placeholders` metadata, which the game labels on screen whenever the set is active.
The shipped pixel frames are never used as a fallback.

Frame convention (all drawings in a set): `canvas` px, transparent, facing right, feet
at `feet`, drawn at 2x display size (the sprite is shown at `scale`), clean 2D lines —
the game samples it with linear filtering.
"""
import os
from pose_slots import BASE, SLOTS

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
CHARS = os.path.join(ROOT, "valknut", "characters")

SETS = {
    "berserker": {
        "v2": {
            "canvas": (512, 256),
            "feet": (256, 248),
            "scale": 0.5,
            # Shown for every undrawn pose (flagged). Cut from the approved reference
            # sheet's side view — axes hidden, so it is never final idle art.
            "stand_in": "ref_side",
            "aliases": {"idle": "idle_01"},
            # Milestone 1 poses: pose -> (used by, brief). Timing comes from the
            # existing animations (berserker_anims.gd), frame numbers in brackets.
            "poses": {
                "idle_01": ("idle [0]", "Combat stance, 3/4 side-on facing right: knees bent, weight centred, "
                            "front axe forward at waist height, rear axe low and back, both axe heads fully "
                            "visible; mantle resting on the shoulders. Breath out."),
                "idle_02": ("idle [15, 45]", "Same stance mid-breath: chest and shoulders up ~3 px (2x canvas), "
                            "mantle lifted slightly, axes unchanged."),
                "idle_03": ("idle [30]", "Same stance, full breath in and weight eased onto the rear foot: "
                            "shoulders ~5 px up, front axe tipped 5-10 degrees back."),
                "light_anticipation": ("jab1 [0-2]", "Compact: front (right) axe cocked back beside the "
                            "head, elbow high, torso turned slightly away, rear axe tucked; feet don't move."),
                "light_smear": ("jab1 [3]", "Front axe halfway through a short diagonal chop, head and haft "
                            "drawn as a smear (stretched arc, 2-3 trailing ghost edges)."),
                "light_contact": ("jab1 [4-7]", "Front axe at the end of the chop, arm extended in front at "
                            "chest-to-waist height (matches the hitbox 42 px ahead, 52 px up at 1x), "
                            "shoulders square, front knee bent."),
                "light_recovery": ("jab1 [8-14]", "Axe carried slightly past contact and low, body still "
                            "forward; rear axe already coming back to guard."),
                "light_settle": ("jab1 [15-17]", "Halfway back to idle_01: axe rising to guard, weight "
                            "shifting back. Must silhouette-match idle_01 closely."),
                "heavy_windup": ("fsmash [0-7]", "Big wind-up: both axes swung far back past the rear hip, "
                            "torso twisted ~90 degrees away, deep wide stance, mantle swinging back."),
                "heavy_charge": ("fsmash [8-17], held while charging", "Same as windup but wound tighter: "
                            "lower crouch, more twist, red warpaint and eyes glowing."),
                "heavy_smear": ("fsmash [18-19]", "Explosive horizontal double-axe sweep crossing the body, "
                            "large curved smear arc in front, mantle flying back."),
                "heavy_contact": ("fsmash [20-29]", "Sweep finished in front: both arms extended at full "
                            "reach, whole body rotated through, front foot stamped, mantle flared. Must not "
                            "read as a bigger light_contact."),
                "heavy_recovery": ("fsmash [30-53]", "Overcommitted: body twisted past the target, axes low "
                            "near the floor, heavy breathing; held long (the move's endlag)."),
            },
        },
    },
}


def build(legend: str, name: str, spec: dict) -> list:
    frames_dir = os.path.join(CHARS, legend, "frames_%s" % name)

    def drawn(pose):
        return os.path.exists(os.path.join(frames_dir, "%s_%s.png" % (legend, pose)))

    names = list(dict.fromkeys(BASE + list(SLOTS[legend]) + list(spec["poses"])))
    poses, placeholders = {}, []
    for pose in names:
        alias = spec["aliases"].get(pose)
        if drawn(pose):
            poses[pose] = pose
        elif alias and drawn(alias):
            poses[pose] = alias
        else:
            poses[pose] = spec["stand_in"]
            placeholders.append(pose)
    files = sorted(set(poses.values()))
    ids = {f: "%d_%s" % (i + 1, f) for i, f in enumerate(files)}
    out = ['[gd_resource type="SpriteFrames" load_steps=%d format=3]' % (len(files) + 1), ""]
    for f in files:
        out.append('[ext_resource type="Texture2D" path="res://valknut/characters/%s/frames_%s/%s_%s.png" id="%s"]'
                   % (legend, name, legend, f, ids[f]))
    anims = []
    for pose in names:
        anims.append('{\n"frames": [{\n"duration": 1.0,\n"texture": ExtResource("%s")\n}],\n"loop": false,\n'
                     '"name": &"%s",\n"speed": 1.0\n}' % (ids[poses[pose]], pose))
    cw, ch = spec["canvas"]
    fx, fy = spec["feet"]
    s = spec["scale"]
    out += ["", "[resource]",
            "metadata/placeholders = PackedStringArray(%s)" % ", ".join('"%s"' % p for p in placeholders),
            "metadata/sprite_scale = Vector2(%s, %s)" % (s, s),
            # Centred sprite: put the feet anchor on the fighter's origin.
            "metadata/sprite_offset = Vector2(%d, %d)" % (cw // 2 - fx, ch // 2 - fy),
            "animations = [%s]" % ", ".join(anims), ""]
    with open(os.path.join(CHARS, legend, "%s_%s_frames.tres" % (legend, name)), "w") as fh:
        fh.write("\n".join(out))
    return placeholders


if __name__ == "__main__":
    for legend, sets in SETS.items():
        for name, spec in sets.items():
            ph = build(legend, name, spec)
            todo = [p for p in spec["poses"] if p in ph]
            print("%s/%s: %d/%d milestone poses drawn; %d pose(s) on the stand-in"
                  % (legend, name, len(spec["poses"]) - len(todo), len(spec["poses"]), len(ph)))

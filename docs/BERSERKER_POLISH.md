# Berserker light attack: polish pass

**Branch:** `claude/berserker-polish`, from `claude/berserker-fullrig` at `87b76f8`. Not merged.

Only the `jab1` motion curves of the `fullrig` art set changed. The 17 layers, the 15-bone
skeleton, both master axes, the leg IK, combat data and the other art sets are untouched. The
previous attack is kept as `_full_jab1_basic()` (set `BerserkerAnims.fullrig_basic_jab = true`),
which is how the before/after material was made.

## Timing (unchanged)

20 frames, hit on frames 4–5, hit-freeze holds frame 4, cancel window and combo timing are
move data and were not touched. The budget was redistributed, not stretched:

| Frames | Phase | What happens |
|---|---|---|
| 0–2 | **Anticipation** | The centre of gravity drops 9 px (was 5), the hips slide back over the rear leg, and both knees bend because the IK keeps the boots planted. The hips tip forward 4° while the torso coils back −13°: opposing twist. The axe arm rises beside the head with the axe tipped back (shoulder −148°, wrist −55°). |
| 2–4 | **Acceleration** | The hips go first, then the torso, shoulder and wrist. By frame 3 the hips have done 61% of their move, the torso 48%, the shoulder 37% and the wrist 25%. The arm covers 26° in the first frame and 44° in the second, so it is fastest just before impact. The wrist snaps through (−55° to +38°) so the axe whips. |
| 4 | **Impact** | Hips 11 px forward and 10 px down (weight sunk onto the front leg), hip tilt +7°, torso +14°, shoulders committed forward, arm extended, axe flat in front. Held through the hit-freeze. |
| 5–12 | **Follow-through** | The torso overshoots slightly (+15° at frame 6) and then settles; the arm and axe carry on along the arc past the hip; the wrist keeps rolling (+46°) and relaxes; the cape swings on a lag behind the hips. |
| 12–19 | **Recovery** | Every bone eases out to the idle pose (no per-frame step over 9.5°). |

## Before and after (curve values)

| | Before | After |
|---|---|---|
| Hips drop at load | 5 px | 9 px |
| Hips drop at impact | 7 px | 10 px |
| Hip travel, load to impact | 16.5 px | 18 px |
| Torso arc, load to impact | 23° | 27° |
| Hip / torso opposition at load | same direction | opposite (+4° / −13°) |
| Order of motion into impact | all together | hips → torso → shoulder → wrist |
| Peak arm speed | 35° per frame | 44° per frame |
| Wrist whip | 60° | 93° |
| Torso overshoot after impact | none | +1° |

## Artwork limits respected

Spine within ±15°, chest scale within ±5% (0.955–1.03), rear shoulder within 25°: past those
the known gaps behind the rear shoulder and torso (D1–D4) and the squashed belt medallion (D7)
become visible. These are enforced by `art_set_test`. At gameplay scale nothing from D1–D4 is
visible at any frame of the attack.

The wind-up could not go further: at a shoulder angle past about −150° the forearm crosses his
face (tested; see the candidate poses in the commit message). A deeper backswing needs a drawn
three-quarter arm.

## Verification

- **Combat unchanged.** Damage, knockback and positions are frame-identical with the shipped
  art, v2, the elbow rig and the full rig for `jab1`, `fsmash`, `ftilt` and the three-hit string;
  the state and damage timelines of the before and after recordings are identical; the light
  attack still deals 4%.
- **Feet planted:** max drift through the attack 0.00 px.
- **Repeated attacks:** three consecutive `jab1`s each end back on the idle pose (worst
  offset 0.06).
- **Tests:** 228 checks (215 before, 13 added: load depth and weight shift, hip/shoulder
  opposition, hips-first chain, arm acceleration, impact sink, the three artwork limits, no
  snaps in follow-through, ending on the idle pose, repeated attacks, the old attack still
  available) on Godot 4.3 and 4.7.2.

## Remaining limitations

1. **Fur has no secondary motion.** The cape swings on a lag behind the hips, but the fur mantle
   is attached rigidly to the spine: moving it separately would need another bone, and the
   brief keeps the 15-bone skeleton.
2. **Torso rotation is still faked** by a ≤5% chest narrowing. A real twist needs a drawn
   three-quarter torso.
3. **The anticipation is two frames** because the hit is on frame 4. At 60 fps it reads as
   a snap-load, not a slow wind-up; the extra depth comes from the lowered stance and the
   opposing twist.
4. **Only the light attack is animated** with this rig; all other moves hold the rest pose.
5. **D1–D8 in `BERSERKER_FULLRIG.md` still apply,** in particular the flat fills behind
   the rear shoulder, which cap how far the rear arm and torso can move.
6. **The effect arc is still the generic slash effect,** slightly larger (radius 44, width 9).

## Files

Modified: `valknut/characters/berserker/berserker_anims.gd` (`_full_jab1` rewritten;
`_full_jab1_basic` and the `fullrig_basic_jab` switch added) and `valknut/tests/art_set_test.gd`
(+13 checks). New: `docs/BERSERKER_POLISH.md` and `docs/previews/berserker_polish/`.

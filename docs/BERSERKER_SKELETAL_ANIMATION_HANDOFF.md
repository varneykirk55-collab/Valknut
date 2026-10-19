# Berserker skeletal (cutout) animation: handoff

**Branch:** `claude/berserker-skeletal-poc`, based on `claude/berserker-v2-animation` at `ff34477`.
Not merged anywhere.

## Status

**Proof of concept: the consistency goal is met, the motion goal is only partly met.**

- **One complete light attack (`jab1`) and the idle** run on a Godot cutout rig
  (Skeleton2D > Bone2D) built only from the approved idle_01 drawing.
- **Consistent design:** the Berserker is pixel-for-pixel the approved character in every
  frame. No redrawn frames, no AI-regenerated poses, and both axes are the original
  drawing.
- **Combat unchanged:** the rig is presentation-only. Damage, knockback, positions and
  states are frame-identical to the shipped art and the v2 sprites (`art_set_test`).
  The light attack still deals 4%.
- **Limits of the motion:**
  - Only the **forearm + axe** moves, rotating at the elbow. It reads as a compact
    hatchet chop, not the full torso-rotating, shoulder-driving diagonal swing in the
    brief. See "Limitations".
  - Every other move holds the rig's rest pose. The rig covers `idle` and `jab1` only.
- The sprite v2 art set (`Game.art_sets = {"berserker": "v2"}`) and the shipped pixel
  art are untouched and still the fallback. The default is still the shipped art.

## How to run

- **Demo:** open `valknut/tests/berserker_rig_demo.tscn` in Godot 4.3+ (or 4.7.2) and
  press F6. J is the light attack, which is the rigged move.
- **Turn it on anywhere:** `Game.art_sets = {"berserker": "rig"}` before the match
  scene is created.
- **Regression suites (headless):**
  ```
  for t in sim_test round_flow_test berserker_test combo_test art_set_test; do
    godot --headless --path . --fixed-fps 60 res://valknut/tests/$t.tscn; done
  ```
  Expected: 37 + 8 + 28 + 110 + 21 = **204** checks, all `ok`. The 5 new rig checks are
  in `art_set_test`.
- **Rebuild the rig parts and scene** (Pillow + numpy):
  `cd tools && python3 build_berserker_rig.py`

## Files

**Created:**
- `tools/build_berserker_rig.py`: cuts the parts from idle_01 and writes the PNGs and
  the rig scene. All geometry constants (elbow pivot, cut polygons) are at the top.
- `valknut/characters/berserker/rig/body.png` and `forearm_axe.png`: the generated parts
  (canvas scale 0.3176, same as the v2 frames).
- `valknut/characters/berserker/berserker_rig_rig.tscn`: the generated rig scene.
- `valknut/tests/berserker_rig_demo.gd` / `.tscn`: the demo.
- `docs/previews/berserker_rig/`: videos at normal speed and 4× slow, the comparison
  with the reference, the parts diagram, a joint close-up, and the rejected shoulder
  pivot attempt.

**Modified:**
- `valknut/core/fighter/fighter.gd`:
  - `_apply_art_set()` instances `<legend>_<set>_rig.tscn` when it exists. The rig is
    named `ArtRig`, sits where the sprite was, and the sprite is hidden.
  - `_read_placeholders()` skips a hidden sprite.
- `valknut/characters/berserker/berserker_anims.gd`:
  - `ELBOW` / `RIG_ELBOW` constants.
  - `build(art)` adds the elbow track when `art == "rig"`.
  - New helpers `_rig_idle()`, `_rig_jab1()` and `_eased()`. `_eased()` writes
    per-frame smoothstep keys, because AnimBuilder interpolates linearly.
- `valknut/tests/art_set_test.gd`: rig section, and three-way combat traces (shipped,
  v2, rig).

## Rig hierarchy

```
Fighter/Visual/Rig/Body/
  Sprite (AnimatedSprite2D)        hidden while the rig art set is active
  ArtRig (BerserkerRig, Node2D)    scale 0.5, linear + mipmaps; origin = feet
    Body (Sprite2D)                whole drawing minus the front forearm
    Skeleton (Skeleton2D)
      Elbow (Bone2D)               pivot at the centre of the elbow's fur cuff
        ForearmAxe (Sprite2D)      cuff + bracer + hand + axe, one rigid piece
```

The fighter's own AnimationPlayer (`Visual/AnimationPlayer`) keys
`Rig/Body/ArtRig/Skeleton/Elbow:rotation`. Timing is therefore the existing move data:
hitlag freezes the rig like any other animation, and nothing in combat reads the rig.

**`jab1`, 20 frames; the hit is on frames 4–5. Elbow angles in degrees, eased:**

| Phase | Frame | Elbow angle |
|---|---|---|
| rest | 0 | 0 |
| anticipation (axe cocked beside the head) | 2 | −140 |
| swing (+ SlashFX arc around the elbow, frames 3–5) | 3 | −100 |
| contact (held through hitlag) | 4–7 | −55 to −50 |
| recovery (past the hip) | 11 | +18 |
| settle | 15 | +6 |
| idle | 19 | 0 |

`Rig:scale` adds a squash into the wind-up and a stretch through the chop. It scales
from the feet, so they never slide.

## Limitations (why the motion is limited)

1. **No shoulder joint is possible.** In idle_01 the front upper arm is foreshortened
   against the chest, and no drawn outline separates them. A shoulder pivot either cuts
   a straight seam through the torso or needs chest and armpit anatomy painted in,
   which the brief forbids. That attempt is in `rejected_shoulder_pivot.png`.
2. **No overhead wind-up.** The drawing is front-facing, so any arm rotated flat in the
   picture plane covers his face. A real overhead wind-up needs the arm foreshortened
   back in depth, which means drawing it.
3. **No torso rotation or real weight shift.** Body, legs and rear arm are one flattened
   layer. Twisting the torso needs the torso and legs as separate drawings with hidden
   areas filled in.
4. **The elbow cuff is duplicated:** a static copy stays on the upper arm so the joint
   never opens. At extreme angles it can read as a second fur band, which is barely
   visible at game scale.
5. **The wind-up is only 2 frames.** That's fixed by gameplay timing: the hit lands on
   frame 4. It reads as a whip, which suits a light attack.
6. **Only `idle` and `jab1` animate.** Every other move holds the rest pose (a warning
   is logged).

## Recommended next steps

- **To reach the full brief** (torso rotation, shoulder drive, a convincing overhead
  arc), the rig needs **layered source art**, not a flattened image. Ask the artist for
  the idle_01 design split into separate transparent layers with the hidden areas
  painted in:
  - head + hair + beard;
  - torso + belt (with the shoulder and armpit under each arm drawn);
  - fur mantle (separate, so it can sit over the shoulders);
  - front upper arm, front forearm + hand;
  - rear upper arm, rear forearm + hand;
  - pelvis/skirt;
  - each thigh, each shin + boot;
  - cape (separate, behind);
  - **one** axe drawing, used for both hands.

  Same pixel size and position as `berserker_v2_idle_strip.png` pose 1, so the existing
  scale and anchor carry over.
- With those layers, extend `berserker_rig_rig.tscn` to a full bone chain (hip > spine >
  shoulder > elbow; hip > knee > foot), and add `_rig_*` animations for the other moves
  the same way as `_rig_jab1()`.
- Keep the v2 sprite set as the fallback until the rig covers every move.

## Assets still needed

- The layered idle_01 described above. This is the single biggest unlock.
- Optionally, a forearm drawn foreshortened (pointing at the camera) to swap in for a
  true overhead wind-up.

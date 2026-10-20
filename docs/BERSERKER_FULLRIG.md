# Berserker full-body rig prototype

**Branch:** `claude/berserker-fullrig`, from `claude/berserker-layers` at `ce5f378`. Not merged.

**Status: working prototype.** It uses the 17 existing layers and `axe_master.png` for both
hands, and the layers are unchanged. The light attack (`jab1`) moves the shoulders, torso,
hips and legs, with a planted-foot IK. The approved idle is preserved. The prototype is
good enough to judge; the defects below are mostly in the filled-in hidden anatomy and
need an artist.

## What was built

- **Rig:** 15 bones (Hips, Spine, Chest, Neck, both Thigh/Shin, both Shoulder/Elbow/Axe,
  Cape) with the 17 layers attached through `RemoteTransform2D`, so the layers keep the
  drawing's stacking order. Both axes are `Sprite2D`s of the SAME `axe_master.png` at the
  same scale; the rear one is mirrored and turned to meet its hand.
- **Art-set toggle:** `Game.art_sets = {"berserker": "fullrig"}`. Other values: `"v2"`
  (sprites), `"rig"` (elbow-only proof of concept), none (shipped pixel art). In the demo
  scene, T cycles fullrig → v2 → shipped.
- **Animations:** `idle` (breathing with chest, shoulders and head) and `jab1`. Every other
  move holds the rest pose and logs a warning.

## `jab1`: what moves (20 frames, hit on 4–5, unchanged)

| Frame | Phase | Body |
|---|---|---|
| 0 | start | slight crouch, axe arm starting up |
| 1–2 | anticipation | weight rocks back (hips −7.5 px, down 5); spine coils −11°, chest narrows 7% (a fake twist), head turns away; front shoulder drives the axe to −150° (overhead); rear arm swings out +22° for balance |
| 3 | swing | the shoulder whips the axe down through a smear arc |
| 4–8 | contact, held through hitlag | hips drive forward (+9 px) and drop (7 px), hip rotation +5°, spine +12°, shoulder −80°, wrist snaps +35° |
| 8–12 | follow-through | the axe carries on and low; the body starts to unwind |
| 12–19 | settle | everything eases back to the idle pose |

The legs are solved by two-bone IK, so each boot stays on its rest position whatever the
hips do (max drift through `jab1`: 0.003 game px). The cape swings on a lag behind the
hips. Motion is eased per frame.

## What was verified

- **Combat is unchanged.** Damage, knockback and positions are frame-identical with the
  shipped art, v2 sprites, the elbow rig and the full rig, for `jab1`, `fsmash`, `ftilt`
  and the three-hit string. The rig's `jab1` still deals 4%. `jab1` keeps its 20-frame
  length. `art_set_test` checks all of this.
- **Rest pose matches the original** (`compare_idle.png`). The only difference is the rear
  axe, which is the master axe.
- **Joint stress test** (`stress.png`): each joint posed alone at large angles (shoulder up
  to −150°, elbow ±60–80°, spine ±25°, hips ±20°, thigh ±35°, knee ±50°, neck ±25°).
  Limbs stay connected with no gaps at the joints. The defects are below.

## Fixes made during testing

1. **Feet lifted** by 0.77 px at the deepest coil because the hips moved out of the leg's
   reach. Tuned the coil (hips −7.5 / down 5); drift is now 0.003 px.
2. **Detached cape fragments** floated beside the right leg once the body moved. 38 isolated
   fragments (under 800 px, x > 480 in the source) are dropped from `cape.png` at build time.
   `cape.png` itself is untouched.
3. **Hairline dark seams** along layer borders (fur mantle, forearm cuffs, knee fur, boot
   tops) appeared because each layer was downscaled separately. Each layer now extends 3 source
   px under its neighbours using the original drawing's own pixels, so nothing changes at rest.
4. **Cape attached to the spine** swung with the torso and tore away from the hips; it now hangs
   from the hips.

## Remaining visible defects (artwork needing repair)

| # | Layer | Where (source px, 620×655) | Seen when | Correction |
|---|---|---|---|---|
| D1 | `arm_upper_L` | shoulder cap, about (150–245, 150–200) | rear shoulder rotates more than ~40° | The shoulder top is a flat-fill ellipse with a ragged outline where the fur mantle used to cover it. Paint a clean rounded deltoid with the drawn outline. |
| D2 | `torso` (left flank and back) | about (240–300, 190–300) | rear arm raised or swung out, or spine tilted more than ~15° | Nothing is drawn behind the rear arm, so a dark gap opens between `torso`, `cape` and `mantle_back` (`defects_closeup.png`). Paint the torso's left side and back, down to the belt. |
| D3 | `mantle_back` | whole layer, about (100–300, 83–299) | rear shoulder moves | The back mantle is only scattered fragments (16 islands), because most was hidden. Paint it as one continuous piece. |
| D4 | `cape` | behind the pelvis, about (190–300, 290–470) | spine or hips tilt more than ~15° | Missing behind the waist and hips; only a 30 px band was filled. Paint the cape continuous behind the body. |
| D5 | `pelvis`, `leg_upper_L/R` | hip joints, about (160–280, 380–460) and (360–490, 380–460) | hips rotated more than ~10° with no IK | The legs swing as one block. The animation uses IK, so jab1 is unaffected, but any move rotating the hips must use `_leg_ik()`. The hip tops are flat fills (`leg_upper_*` ellipses), hidden by the skirt up to about ±35° thigh angle. |
| D6 | `axe_master` | whole | always | The rear hand now has the master axe, not the drawn rear axe, which was ~21% larger with a longer blade. The handle is extended by tiling, and ends in a plain cap. |
| D7 | `torso` | whole | chest twist | The twist is faked by narrowing the chest by up to 7% horizontally. Beyond ~10% the belt medallion looks squashed. A real turn needs a drawn three-quarter torso. |
| D8 | `mantle_front`, `mantle_back`, `cape` | whole | any movement | They move rigidly with their bones. Only the cape swings, on a lag. There is no fur flutter. |

Not visible in testing: gaps at the elbows (±80°), knees (±50°), thighs (±35°) or neck
(±25°), and no disconnected limbs or stretched textures. Hands stay on the axe handles
through the whole attack, since the hand and axe are one rigid piece.

**Does the existing art support a convincing attack?** Yes, for this move. The
prototype reads as a full-body attack. What limits it is in the artwork: no
three-quarter or turned views, so no real torso rotation, and the flat fills described
above. A final-quality attack still needs the repaint of D1–D4, and a drawn alternative
for D7 if the twist needs to be larger.

## Build and run

```
# 1. regenerate the layers (only if the source drawing changed)
python3 tools/build_berserker_layers.py
# 2. build the rig scene, textures and rest geometry (Pillow, numpy, scipy)
python3 tools/build_berserker_fullrig.py
# 3. watch it: open valknut/tests/berserker_fullrig_demo.tscn in Godot 4.3+ and press F6
#    J = light attack, T = switch between fullrig / v2 / shipped art
# 4. regression suites
for t in sim_test round_flow_test berserker_test combo_test art_set_test; do
  godot --headless --path . --fixed-fps 60 res://valknut/tests/$t.tscn; done
```

Expected: 37 + 8 + 28 + 110 + 32 = **215** checks, all `ok`.

## Files

**New:** `tools/build_berserker_fullrig.py`; `valknut/characters/berserker/fullrig/` (layer
PNGs and `axe_master.png`); `berserker_fullrig_rig.tscn`; `berserker_fullrig_data.gd`
(generated rest geometry); `valknut/tests/berserker_fullrig_demo.gd` / `.tscn`;
`docs/previews/berserker_fullrig/`.

**Modified:** `valknut/characters/berserker/berserker_anims.gd` (bone tracks, IK, `idle` and
`jab1` for the `fullrig` set; existing sets untouched) and `valknut/tests/art_set_test.gd`
(+11 checks). `fighter.gd` is unchanged: the loader added for the elbow rig already
picks up `<legend>_<set>_rig.tscn`.

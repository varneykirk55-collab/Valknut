# Berserker right-axe animation test

Status: integrated, exercised in rendered gameplay, mechanically passing; **provisional artwork, not an exact-match visual acceptance**. No merge.

Base: `claude/ground-combat-overhaul`, commit `cabce8d4306f5fa0f1c9b76f0432c473a14d5b80`.

## Delivered

Four original transparent PNG poses in `valknut/characters/berserker/frames/`:

| File | Canvas | Repository pose span |
|---|---|---|
| berserker_right_anticipation.png | 128x128 | 0–2 |
| berserker_right_smear.png | 256x128 | 3 |
| berserker_right_contact.png | 256x128 | 4–7 |
| berserker_right_follow.png | 128x128 | 8–14 |

All grounded pixels end at y=124. Feet centered approximately on x=64 / 128. Existing recovery and idle remain in use. The builder now reports 4/17 Berserker slots drawn, 13 placeholders; all four right_* slots reference their own textures and are absent from placeholder metadata.

`poses.png`: existing idle followed by the four poses, native pixel scale with centered canvases.
`gameplay.mp4`: 60fps captured match frames, with actual hitlag; approximately 0.43 seconds.
`gameplay_slow.gif`: the same gameplay frames slowed to 80ms/frame for inspection, not real-time playback.
`gameplay_filmstrip.png`: selected actual gameplay captures with labels.
`capture_labels.txt`: every captured frame's runtime move/pose labels. Runtime move counter and animation sample labels have an existing one-tick offset; the contact-sync regression passes. No timing changes were made.

## Generation and visual review

Used built-in image generation with the repository's idle and attack-active PNGs as references. The actual artwork is shaded pixel art, not flat-color cartoon art. Preserved blonde hair/beard, pale skin, cream fur, brown/red leather clothing and dual steel axes.

Prompt briefs: right axe raised high/back with rear weight; diagonal accelerating smear with rotating shoulders; forward-weighted low/front contact; crossed low right axe with raised rear left axe for the next hit. Each requested exact source scale, palette, outlines, transparency, right-facing orientation and specified canvas/anchor. One follow-through correction explicitly moved the low axe from screen-right to the rear thigh across the body.

The generator returned oversized artwork rather than exact pixel canvases. Integration cropped the opaque foreground, removed low-alpha fringe, used nearest-neighbor reduction, and positioned the results on the specified canvases. No body rotation, synthetic limb rig, or gameplay animation timing changes were used.

The attack now has genuinely different body and weapon poses and a readable high-to-low action, confirmed in rendered gameplay. Limitations: the generated costume, facial details, axe shape and pixel clusters are not exact copies of the source design. The new poses have a different silhouette from the old recovery/idle, causing a visible transition. The smear is close to the contact stance, with most acceleration communicated by its drawn axe arc. Manual pixel cleanup and transition review are advisable before treating this as final production art. This is a successful pipeline experiment, not an unconditional claim that the strict visual consistency criterion is met.

Scaling: the slot/builder pipeline works, but unattended generation of the remaining 29 poses is not justified. Each pose needs identity, weapon-hand continuity, pixel-scale and in-game review; an artist cleanup pass would improve consistency.

## Validation

Godot 4.3 stable, software OpenGL compatibility renderer:

| Suite | Checks | Result |
|---|---:|---|
| combo_test | 110 | PASS, 0 failures |
| sim_test | 37 | PASS, 0 failures |
| round_flow_test | 8 | PASS, 0 failures |
| berserker_test | 28 | PASS, 0 failures |

The round-flow and Berserker suites emitted ObjectDB leak-at-exit warnings; passing tests do not erase these warnings. Runtime reports the remaining unrelated placeholder poses. Damage, hitboxes, knockback and combo mechanics were not edited.

Capture tooling gained `--first-hit`: captures only jab1, samples every simulation tick, waits for the match tick before the next screenshot freeze, and expands the crop to include raised axes. This fixes idle-only output when sampling every frame; default combo capture is preserved.

Reproduce from repository root:

```sh
python3 tools/build_sprite_frames.py
godot --headless --editor --path . --import
godot --headless --path . --fixed-fps 60 res://valknut/tests/combo_test.tscn
godot --path . --fixed-fps 60 res://valknut/tests/screenshot.tscn -- /tmp/right-axe --combo-film --first-hit --legend=berserker
```

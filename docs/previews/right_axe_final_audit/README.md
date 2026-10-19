# Berserker final consistency audit and rendering corrections

**Status: rendering/transition corrections verified; full original-design consistency is NOT complete.** No claim of six newly corrected PNG drawings is made. The six completed sprites are preserved byte-for-byte from `3c02465b6c3da0bc09b3467f694ffa82ef9d6c3b`.

## Verified facts

- `berserker_sheet.jpg` is a 1168x784 RGB JPEG with a baked-in checkerboard, not a transparent PNG atlas.
- `tools/cut_frames.py` isolates the sprites, keys out the checkerboard and downsizes with **Lanczos**. Thus the original idle already contains resampling softness.
- Idle is a 128x128 RGBA canvas; nonzero-alpha bounds are (32,57)–(100,125), and alpha>127 bounds are (35,58)–(97,125). Its visible body is about 67 pixels high, not 128 pixels high.
- Godot Sprite scale is 1.3897, offset (0,-60), local position (0,46). These are unchanged. Transform pixel snapping is enabled.
- The Sprite node had `texture_filter = 2`. Godot 4.3 itself reports `TEXTURE_FILTER_NEAREST=1`, `TEXTURE_FILTER_LINEAR=2`. The node therefore used **linear** filtering despite the project default. This pass sets the node to 1, nearest-neighbor, as requested.

| Preserved PNG | Canvas | Nonzero-alpha bounds, exclusive maximum |
|---|---|---|
| right_anticipation | 128x128 | (20,38)–(94,125) |
| right_smear | 256x128 | (92,60)–(197,125) |
| right_contact | 256x128 | (87,60)–(189,125) |
| right_follow | 128x128 | (34,25)–(95,125) |
| right_return_01 | 128x128 | (35,44)–(92,125) |
| right_return_02 | 128x128 | (34,60)–(97,125) |

All six have their lowest opaque row at 124. Idle is also grounded at row 124. The old shared attack_recovery has opaque bounds (35,54)–(100,125), plus faint alpha fringe down to row 126; it is taller than the new settling drawing.

## Transition correction

The first strike previously inserted the taller shared `attack_recovery` for **one frame at frame 17**, then switched to idle at frame 18. This created a brief silhouette-height pop. The attack-local `right_return_02` now stays on screen through frame 17, then goes directly to the unchanged idle at frame 18.

The attack still lasts 20 frames. Anticipation starts at 0, smear at 3, contact at 4, follow at 8, lowering at 12, settling at 15, idle at 18. Only the redundant visual frame-17 key was removed. No damage, hitbox/hurtbox dimensions or timing, knockback, combo windows, movement physics, input, collision, balance, or combat-state transitions changed. No sprite rotation or decorative root movement was added.

## Why exact character-design matching remains unfinished

The newly supplied original illustration is not merely a high-resolution copy of the game's idle. Its prominent gold mantle clasps, belt medallion, decorated axe blades, braids, dark shoulder-fur layers and layered leg armor differ from or are absent in the source sheet itself. At native game scale some detail must be simplified, but the differences also involve silhouette, equipment and rendering style.

The six generated attack/recovery sprites further differ from idle in the cloak, outfit and facial/pixel details. Correcting filtering and removing one bad transition cannot restore absent artwork. Adding the illustration's full design only to these six drawings would still cause a costume change when returning to the unchanged idle. These conflicting visual baselines need a coordinated art decision/cleanup, rather than another unverified regeneration pass.

`design_comparison.png` shows the attached illustration, original idle and all six preserved poses. Sprite panels are enlarged by nearest-neighbor for inspection. `gameplay_filmstrip.png` shows actual rendered frames after the fixes. The last panel holds the settling pose rather than briefly displaying the taller original recovery.

## Validation and recordings

Godot 4.3 stable. All four existing suites pass: combo 110, simulation 37, round-flow 8, Berserker 28; **183 checks, zero failures**. Logs include ObjectDB leak-at-exit warnings. Runtime still reports the 29 other attack placeholders (13 Berserker, 16 Valkyrie), outside this task.

The rendered recording contains 106 simulation frames and exactly three standalone jab1 starts. Every required attack/recovery pose appears. `attack_recovery` no longer appears in this first-strike capture. All six PNG hashes match the previous commit. The side-by-side comparison and filmstrip were visually inspected; they demonstrate the remaining design mismatch rather than hiding it.

- `gameplay_normal.mp4`: 60 fps, normal simulation speed.
- `gameplay_slow_4x.mp4`: identical frames at 15 fps, exactly 4x slower.
- `capture_labels.txt`: actual runtime move and pose labels.
- `original_design.png`: supplied design reference.

## Play and reproduce

The complete project archive requires Godot 4.3 or newer. Import `project/project.godot`, open `valknut/tests/right_axe_demo.tscn`, press F6, then press J without holding a direction. Wait for recovery between presses to isolate jab1. WASD moves; Esc pauses. F5 runs the full game. No engine binary is included.

```sh
godot --path . --fixed-fps 60 res://valknut/tests/screenshot.tscn -- /tmp/right-axe-review --combo-film --first-hit --repeat-first --legend=berserker
```

No merge is authorized or performed. Git publication status is reported with the delivery.

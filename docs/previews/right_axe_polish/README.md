# Berserker first-strike polish

## Status

Integrated and exercised in a rendered Godot match, including three consecutive standalone first strikes. The four attack drawings are retained as pose designs and edited for more subdued color/costume consistency. Two new attack-local recovery drawings reduce the large overhead-to-low-stance jump. The generated poses still have sharper pixel clusters and some costume/face differences versus the softer original idle/recovery artwork. **Strict visual consistency and completely seamless recovery are not fully met; this is an improved review build, not an unconditional production-art acceptance.**

Recovered local parent: `7f6442d7f17c0a7e373b15bb63f6ad52fa9e6b09`.
Upstream source verified: `claude/ground-combat-overhaul` at `cabce8d4306f5fa0f1c9b76f0432c473a14d5b80`.

## Changes

- Preserved the wind-up, diagonal smear, low-front contact and crossed follow-through poses; targeted image edits subdued the red/brown clothing and gold/cream highlights. Original attack-slot names remain unchanged.
- Added `right_return_01` (axe lowering) and `right_return_02` (settling into ready stance). Corrected the settling frame's initially exposed torso to a brown leather tunic.
- Kept all six canvases transparent, hard-edged and grounded on y=124. Anticipation/follow/recovery canvases are 128x128; smear/contact are 256x128. Oversized generated edits were cropped and nearest-neighbor normalized to the existing sprite envelopes; no blurred scaling was used.
- Jab1 now holds a fixed visual BODY position instead of sliding the visual root from x=-3 to x=5. Weight transfer is expressed by drawings. This does not alter Fighter movement or collision.
- Updated the existing SpriteFrames builder with optional, Berserker-only recovery poses. Shared recovery/idle and all other attacks are untouched.
- Capture tooling can record three separately triggered jab1 attacks with `--first-hit --repeat-first`.

| Pose | Animation frames |
|---|---|
| right_anticipation | 0–2 |
| right_smear | 3 |
| right_contact | 4–7 |
| right_follow | 8–11 |
| right_return_01 | 12–14 |
| right_return_02 | 15–16 |
| original attack_recovery | 17 |
| original idle | 18–19 |

Total remains 20 frames; active hitboxes remain frames 4–5. The existing combo window and input buffering are unchanged. Chaining leaves jab1 through the same existing state transitions; later combo attacks still use their previous placeholder art.

## Validation

Godot 4.3 stable, OpenGL compatibility / Mesa software rendering. All existing suites passed:

| Suite | Checks | Failures |
|---|---:|---:|
| combo_test | 110 | 0 |
| sim_test | 37 | 0 |
| round_flow_test | 8 | 0 |
| berserker_test | 28 | 0 |

Logs are included. They emit ObjectDB leak-at-exit warnings; these are not hidden by the passing test result. Runtime correctly reports only the other 13 Berserker and 16 Valkyrie attack placeholders. All four right-axe attack slots resolve to their own PNG files, plus both recovery poses. No changes were found against the source commit in core combat/state/input code, Berserker move data/stats, match code, autoloads or Valkyrie code.

The frame capture shows three jab1 executions, all six new poses in sequence, real contact/hitlag, recovery and intervening idle. All six PNGs have binary alpha and lowest opaque row 124. Capture labels use the existing runtime move counter, which is one tick behind the sampled animation keys; contact-sync tests pass.

## Watch and play

- `gameplay_normal.mp4`: 60 fps, real simulation speed, three separate attacks.
- `gameplay_slow_4x.mp4`: same frames at 15 fps, exactly four times slower.
- `gameplay_inspection.gif`: same frames at 80 ms each, approximately 4.8 times slower.
- `pose_sheet.png`: source idle, four attack poses, two recovery drawings, original recovery.
- `gameplay_filmstrip.png`: selected rendered match frames.

The delivery ZIP includes the **complete runnable Godot project**, not just an image animation. Requires Godot 4.3 or newer; no standalone binary is bundled. Import `project/project.godot`, open `valknut/tests/right_axe_demo.tscn`, and press F6. Press J without movement for the first strike; allow recovery before pressing again. WASD moves; Esc pauses. Repeated early presses intentionally chain into the unchanged later combo attacks. F5 launches the normal game menu.

CLI:

```sh
godot --headless --editor --path project --import
godot --path project res://valknut/tests/right_axe_demo.tscn
```

## Generation and limits

Built-in imagegen was used for targeted edits, not a new character design. The attack edit prompt preserved each existing silhouette, anatomy, weapon position and transparency while matching the source's muted brown/red clothing, cream fur and blonde hair. Recovery prompts requested a lowered rear elbow/axe followed by both arms low near the original ready stance. One corrective edit covered the settling torso with brown leather and muted its red cloth.

The tools improve pose variety but do not guarantee exact pixel-level identity. Further automated regeneration risks new drift; a manual pixel-art cleanup of the generated set against the original idle/recovery is the remaining quality step. Do not expand to other attacks on the assumption that this visual acceptance gate has passed.

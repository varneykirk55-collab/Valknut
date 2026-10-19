# Berserker v2: animation system and art pipeline

Status: **system ready, art missing.** The v2 art set loads, swaps in at runtime and
leaves combat identical. Not one v2 animation drawing exists yet. Every pose currently
shows a stand-in cut from the approved reference sheet, labelled `PLACEHOLDER` in-game.

## 1. Audit of the current system

- **Scene:** `Fighter` (CharacterBody2D) → `Visual/Rig/Body/Sprite` (AnimatedSprite2D),
  plus `Visual/AnimationPlayer`.
- **Visuals vs gameplay are already separate:**
  - Gameplay lives in `*_moves.gd` (MoveData/HitboxData: frames, damage, angles,
    knockback), the 20-state machine (`core/fighter/states`), `CombatResolver`, and
    `Fighter` physics.
  - Visuals live in `*_anims.gd`. AnimBuilder keys `Sprite:animation` (a pose name) plus
    body offset, rotation, squash and tint per frame.
  - The animation never drives hitboxes, so art can change without touching combat.
- **Pose names → drawings:** `<legend>_frames.tres` has one SpriteFrames animation per
  pose. Undrawn slots fall back to an existing frame and are listed in the
  `placeholders` metadata.

### Animations that reuse the same drawing (shipped Berserker)

| Drawing | Used by |
|---|---|
| `attack_startup` | crouch, jump_squat, land, dtilt, dsmash, fair, dair, nspecial, sspecial, dspecial, spot_dodge, tech, getup, getup_attack, ledge_climb, ledge_attack, and as fallback for right/left/heavy wind-ups |
| `attack_active` | ftilt, dtilt, dsmash, nair, fair, dair, sspecial, dspecial, getup_attack, ledge_attack, and as fallback for every combo/heavy smear and contact |
| `attack_recovery` | the end of jab1–3, ftilt, dtilt, dsmash, fair, dair, sspecial, dspecial, getup_attack, ledge_attack |
| `jump` (= `fall`) | jump, air_jump, fall, helpless, nair, nspecial, roll, air_dodge, ledge_hang, ledge_climb, dsmash, and the overhead wind-up fallback |
| `hurt` | hurt, tumble, knockdown, getup |
| `idle` | idle, and ftilt's startup |

- Only 11 distinct drawings serve about 30 animations.
- The light combo (jab1–3) and heavy (fsmash) have their own pose slots, but all 17
  slots are fallbacks.
- On `astra/berserker-right-axe-art`, the 4 right-axe slots plus 2 return poses are
  drawn in the old pixel style. That style is superseded and is not used here.

## 2. Pipeline recommendation: hybrid, frame-by-frame key poses + procedural motion

| | Frame-by-frame | Skeletal / cutout (Skeleton2D, Polygon2D) | Hybrid (chosen) |
|---|---|---|---|
| Visual consistency with the sheet | Highest; every pose is drawn | Hard: the fur mantle, braids and twisting torso deform badly; 3/4 turns are impossible | High |
| Animation quality | Best for smears and big silhouette changes | Smooth, but "puppety" | Drawn key poses plus engine tweening |
| Godot fit | Already in use (SpriteFrames + AnimationPlayer) | Needs rig, weights and new tooling | Already in use |
| Performance | Trivial | Fine | Trivial |
| New fighters | More drawings per fighter | Rig per fighter, plus art cut into parts | About 25–40 drawings per fighter |
| Smash-style readability | Excellent (strong key poses, smears) | Weaker | Excellent |

**How the hybrid works:**
- Draw the key poses: anticipation, smear, contact, recovery and settle for each attack.
- The existing AnimationPlayer adds body bob, squash/stretch, rotation and SlashFX trails
  on top. That's exactly what `berserker_anims.gd` already does, so nothing new is
  needed in the engine.
- Breathing in idle uses three drawings plus the procedural bob.
- Cutout rigging isn't worth it for these designs: the heavy fur mantle and the
  silhouette-changing axe swings need to be drawn.

## 3. What's implemented (this branch)

- **`Game.art_sets`** (`{"berserker": "v2"}`): a per-legend art set.
  - `Fighter._apply_art_set()` swaps the SpriteFrames, scale and offset, and switches to
    linear (smooth) filtering with mipmaps.
  - Gameplay code is untouched. Valkyrie never changes.
- **`tools/art_sets.py`** builds `berserker_v2_frames.tres` from `frames_v2/`.
  - Every pose name gets a drawing, and an undrawn one shows the stand-in.
  - Undrawn poses are listed as placeholders, warned at startup and labelled on screen
    while the set is active.
  - It never falls back to the pixel frames.
- **`tools/cut_reference.py`** isolates a figure from the flat-grey reference sheet. It
  doesn't recolour or redraw anything.
  - `frames_v2/berserker_ref_side.png` is the sheet's side view, mirrored to face right
    and placed on the v2 canvas.
  - It is a **stand-in only**: it's a turnaround pose with the axes hidden, not idle
    art.
- **`berserker_anims.gd`** is unchanged unless the set is v2, in which case:
  - idle keys `idle_01/02/03/02` at frames 0/15/30/45;
  - jab1 (light) keys `light_anticipation/smear/contact/recovery/settle` at
    0/3/4/8/15 → idle at 18;
  - fsmash (heavy) keeps `heavy_windup/charge/smear/contact/recovery` at
    0/8/18/20/30 → idle at 54.

  Every frame number is the existing one. Light and heavy share no pose.
- **`valknut/tests/berserker_v2_demo.tscn`** (F6 to run) is a training match with v2
  enabled.
- **`valknut/tests/art_set_test.tscn`** has 16 checks:
  - the shipped art is the default;
  - v2 loads with no pixel fallback;
  - every keyed pose exists in the set;
  - undrawn poses are flagged;
  - light and heavy use distinct poses;
  - every move ends cleanly;
  - jab1, fsmash, ftilt and the jab string give **frame-identical** damage, knockback and
    positions with and without v2.

## 4. Art needed for milestone 1 (13 drawings)

**Format for every frame:**
- 512×256 PNG, transparent background, facing right.
- Feet planted at (256, 248), with the body centred on x = 256.
- Standing height of about 208 px (shown at 0.5× = 104 px in-game; the hurtbox is 92 px).
- Clean lines with dark outlines, flat colours and two-tone shading, matching
  `valknut/art/source/berserker_v2_reference.png`.
- Same proportions as the reference sheet.

Drop each file into `valknut/characters/berserker/frames_v2/` as
`berserker_<pose>.png`, run `python3 tools/art_sets.py`, and the placeholder flag clears
by itself.

| Pose | Frames | Brief |
|---|---|---|
| idle_01 | idle 0 | 3/4 combat stance, knees bent, front axe forward at waist height, rear axe low; both axe heads visible |
| idle_02 | idle 15, 45 | mid-breath: chest and shoulders up about 3 px, mantle lifted slightly |
| idle_03 | idle 30 | full breath in, weight eased back, front axe tipped back 5–10° |
| light_anticipation | jab1 0–2 | compact: front axe cocked beside the head, torso turned slightly away |
| light_smear | jab1 3 | short diagonal chop, axe drawn as a smear |
| light_contact | jab1 4–7 | arm extended at chest-to-waist height (matching the hitbox 42 px ahead, 52 px up at 1×) |
| light_recovery | jab1 8–14 | axe slightly past contact, rear axe returning to guard |
| light_settle | jab1 15–17 | halfway back; must match idle_01's silhouette |
| heavy_windup | fsmash 0–7 | both axes far back past the rear hip, torso twisted about 90°, wide stance |
| heavy_charge | fsmash 8–17 (held while charging) | wound tighter, lower; warpaint and eyes glowing |
| heavy_smear | fsmash 18–19 | full-body double-axe sweep, large smear arc, mantle flying |
| heavy_contact | fsmash 20–29 | both arms at full reach, body rotated through; must not read as a bigger light hit |
| heavy_recovery | fsmash 30–53 | overcommitted, axes low; held through the long endlag |

The full briefs are in `tools/art_sets.py`.

### After milestone 1 (not required now)

These keep the current pose names, so no code changes are needed:
- walk_01–04, jump, fall and hurt;
- jab2/jab3 (left_*, overhead_*);
- attack_startup/active/recovery: split them per move to remove the reuse in the table
  above.

## 5. Open issue: the Valkyrie's in-game art

The Valkyrie's **in-game sprite is chibi pixel art**: 128 px frames, with a head about a
third of her height. Only her **reference sheet** has the clean 2D style and adult
proportions the new Berserker matches. See `docs/previews/berserker_v2/style_comparison.png`.

Next to each other in a match, a v2 Berserker and the current Valkyrie won't look like the
same game. Making them match means redrawing the Valkyrie's game frames from her
existing reference design (not a redesign), through the same art-set system, as
`frames_v2` for `valkyrie`.

## 6. Idle frames review (idle_01–03 supplied)

The originals are kept unchanged in `valknut/art/source/berserker_v2_supplied/`.
Previews are in `docs/previews/berserker_v2/idle/`.

- **Format:** all three frames are 512×256 RGBA with a transparent background, facing
  right, the bottom at y = 248, and 208 px tall. They pass.
- **Design:** all three match the reference sheet: face, braids, beard, warpaint, fur
  mantle, gold-studded leather, crimson cloth, both axes and fur-trimmed boots.
- **Alignment:** idle_01 and idle_02 share the same foot pixels. idle_03 was drawn
  **14 px right** of the anchor (its feet midpoint is at x = 270.5).
  - It has been shifted on its canvas only, using `tools/align_frame.py idle_03 -14 0`.
    The art itself is untouched.
  - idle_03's stance is also 9 px wider, so its feet still move about 3–6 canvas px
    (about 2–4 screen px) relative to the other frames. That's in the drawing, so it
    isn't corrected.
- **Does it read as breathing? No.**
  - idle_01 and idle_02 are almost identical: small changes to the hair and axe angle,
    with the shoulders and chest at the same height.
  - idle_03 is a different pose: wider stance, cape flared, axes lower, hair blown.
  - All three are exactly 208 px tall with the head top at y = 40, so there's no chest
    or shoulder rise in the art.
  - In motion it reads as a snap to another pose every 15 frames, softened only by the
    existing 2 px procedural bob.
- **Needed to finish the idle:**
  - redraw idle_02 and idle_03 as the *same* pose as idle_01, with only the
    chest/shoulders/mantle rising about 3 px and 5 px (and head and arms riding along);
  - feet on exactly the same pixels;
  - same stance width and same cape shape.

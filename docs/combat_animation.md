# Ground combat & animation overhaul — status

Branch: `claude/ground-combat-overhaul`. Scope: Valkyrie and Berserker three-hit neutral
combos, distinct heavy attacks, classification behaviour. No new fighters or stages.

> **Status: mechanics complete, animation blocked on new artwork.** The combo system, hit
> shapes, feedback, classification behaviour and tests are done. The convincing swings the
> brief asks for need **33 new sprite poses** (16 Valkyrie, 17 Berserker) that don't exist
> in the current art. They are specified pose-by-pose in [`art_requests/`](art_requests/),
> wired into the game as named slots, and currently shown as *flagged placeholders*.
> Definition-of-done items 1–5 (visible spear/shield technique, convincing axe trajectories,
> distinct poses per hit, fluid transitions, heavies that don't look like basics) **cannot
> be met until those drawings exist.** They were deliberately not faked.

## 1. Audit — why attacks look linear and repetitive

| Finding | Evidence |
|---|---|
| **Only three attack drawings per legend.** Each sheet has `attack_startup`, `attack_active`, `attack_recovery`, and nothing else for combat. | `characters/<legend>/frames/` — 11 frames each, 8 of them movement/hurt. |
| **Those three drawings are reused across almost every attack.** | Valkyrie: `attack_startup` in 14 of 15 attacks, `attack_active` in 11. Berserker: startup and active each in 13 of 15. |
| **Swings were faked by rotating the whole sprite.** A thrust frame rotated 1.3 rad becomes the "down air"; the one horizontal axe sweep rotated becomes the "overhead chop". | 9 of 15 attacks per legend key `Rig/Body:rotation`. |
| **Heavy attacks = basic attacks + timing.** The forward smash used the same active frame as jab, forward tilt and ledge attack; only a longer wind-up and a body offset differed. | Old `fsmash` keyed the same `ACTIVE` pose as `jab1`. |
| **No acceleration or follow-through drawings.** Each hit went startup → active → recovery as hard cuts; effects (arcs, speed lines) stood in for the missing motion. | Old anims layered `SlashFX` arcs on almost every attack. |
| **The jab string was three copies of one move.** jab1/2/3 differed only in hitbox numbers. | Same three frames, same hitbox shape. |
| **Combo input could drop presses.** A press counted only once the chain window opened, and the 7-frame buffer could expire first (a press on frame ≤2 of the Berserker's first swing, whose window opens at frame 9). | `AttackState` consumed attack only when `move_frame >= chain_from`. |

Root cause: the art inventory, not the animation code. Timing and effects can't create a
shoulder rotation or an axe arc that isn't drawn.

## 2. Approach

**Pose slots.** Every combo hit and heavy attack now plays named pose slots: anticipation →
smear (the acceleration frame) → contact → follow-through. Each follow-through leads into
the next hit's anticipation, so the string never passes through idle.
`tools/pose_slots.py` is the single list of slots, briefs and fallbacks.

* `tools/build_sprite_frames.py` writes `<legend>_frames.tres` with one SpriteFrames animation per
  pose. The game's AnimationPlayer keys `AnimatedSprite2D.animation` by pose name.
* A slot without its PNG uses a fallback frame and is listed in the resource's
  `placeholders` metadata. Godot prints a warning listing them on load, and the F1 debug view
  labels the current pose `PLACEHOLDER: <slot>` in orange.
* Delivering art: drop `frames/<legend>_<slot>.png` in and run `build_sprite_frames.py`. No
  code changes are needed; tests check every keyed pose exists.

**Motion rules for these attacks.** No whole-body rotation or squash/stretch fakes a swing
any more. Movement is limited to real weight transfer (small translations, the shield
bash's step, the overhead's hop). Effects are kept only as impact feedback (shield burst,
overhead ground shockwave), never as a stand-in for the weapon path.

Directional tilts, aerials and specials are unchanged. They still use the old
rotation-based placeholders and are out of scope ("future passes"); they need the same
treatment and art later.

## 3. Combos (one button, no direction)

| | Hit 1 | Hit 2 | Hit 3 |
|---|---|---|---|
| **Valkyrie** | Spear Slash — 3%, hit f3–4, 18f | Shield Bash — 3%, f4–5, 20f, steps forward, 1.3× hitlag | Spear Finisher — 6%, f7–9, 34f |
| **Berserker** | Right Axe — 4%, f4–5, 20f | Left Axe — 4%, f5–6, 22f, carries forward | Double-Axe Overhead — 8%, f8–10, **46f** |

* **Input:** each attack press made during a hit is remembered (one press, never more) and
  continues the string when the window opens. Early presses aren't dropped; mashing
  advances exactly one hit at a time. No press → the hit finishes and returns to neutral.
  Pressing after that starts again at hit 1.
* **Interrupts:** getting hit leaves the attack state and discards the queued press; the
  next press is hit 1.
* **No loops:** hit 3 ends the string (no `chain_to`). Its knockback is 2–2.5× the openers'
  and pushes the victim 150+ px away. Existing combo decay still applies.
* **Feedback:** distinct impact sounds per hit (spear slash, shield clang, finisher,
  light/heavy axe), heavier swing whoosh on finishers/heavies, a 4-frame white flash on the
  victim, and the existing hitlag and sparks.

## 4. Balance / frame-data changes (reported separately, as requested)

Damage, angles and knockback values of all combo hits and heavies are **unchanged**.
Changed:

1. **Hitbox shapes** of the six combo hits follow the new techniques. A slash or an
   overhead covers height, a thrust covers reach. Valkyrie slash `46×18 → 52×38`, finisher
   `64×20 → 76×44`; Berserker diagonals `48×26 → 50×40`, overhead `62×54 → 62×84`.
2. **Valkyrie Shield Bash** gains a forward step (velocity key, frame 2) and 1.3× hitlag.
3. **Berserker overhead finisher** total `40 → 46` frames (6 more recovery), as the brief asks.
4. Berserker hit 2 gains a small forward carry (frame 2).

**Proposed, not implemented** (needs your call): a 2–3 frame frontal block on the Shield
Bash's active frames, to give the "shield-based utility" a mechanical edge.

## 5. Classifications

`FighterStats.archetype` (`Vanguard`, `Heavy`, `Tank`) is a real field, and
`tests/combo_test.gd` holds each legend's stats and moves to it:

* **Vanguard (Valkyrie):** lighter (92), faster on the ground, more and better air jumps,
  best recovery, longest reach (spear), shield in the combo and Shield Charge.
* **Heavy (Berserker):** heavier (118), slower, more damage and knockback on combo and heavy,
  longer recovery on powerful attacks, weak recovery, close-range pressure.
* **Tank (Dwarf):** reserved in the roster ("Durable, resists launches, slow"). Not
  implemented. Heavy trades durability for power; Tank will trade power for durability.

No global rebalance was made.

## 6. Tests

`tests/combo_test.gd` — 110 checks, all passing. Run for all four matchups
(V–B, B–V, V–V, B–B):

* three presses give jab1 → jab2 → jab3, and all hits land (12% / 16%);
* stopping after hit 1 and after hit 2 returns to neutral;
* a press on frame 2 (before the window) still chains; a late press restarts at hit 1;
* mashing advances one hit at a time; 4 s of mashing never exceeds a 3-hit true combo, and
  the finisher pushes the victim out of range;
* getting hit mid-combo drops the queued press, and the next press is hit 1;
* each hit shows its *contact* pose on its first hitbox frame (animation/hitbox sync);
* finisher knockback is more than 1.5× the openers';
* heavy: longer anticipation and recovery than the finisher, more damage, its own `heavy_*`
  poses (no reuse of combo poses);
* every pose keyed by any animation exists in the SpriteFrames;
* specials, aerials, tilts and smashes still run; classification invariants hold.

The existing suites (`sim_test`, `round_flow_test`, `berserker_test`) still pass on
Godot 4.3 and 4.7.2.

## 7. Visual review

* `previews/<legend>_combo_filmstrip.jpg` — the full three-hit string, the transitions, the
  return to idle, then the heavy, captured every 2 frames in a real match. Each tile is
  labelled move, frame and pose; orange = placeholder.
  Regenerate: `godot --path . res://valknut/tests/screenshot.tscn -- <dir> --combo-film --legend=<id>`
  then `python3 tools/combo_filmstrip.py <dir> out.png "<title>"`.
* What the filmstrips show today: correct timing, chaining and recovery, but every hit
  still displays the same placeholder drawing. That is the art gap, shown rather than
  hidden.

## 8. Remaining limitations

* 33 poses of new art are required (see `art_requests/`). Until then the combos and heavies
  are mechanically complete but visually placeholder.
* Tilts, aerials and specials still use the old rotation-based animation (out of scope).
* Impact sounds are synthesized placeholders.

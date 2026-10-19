# Valkyrie — combo & heavy pose art request

Template: `valkyrie_template.png` (cells are the exact canvas sizes; magenta line = floor, yellow cross = feet anchor, ghost = current idle for scale).

Deliver each pose as `valknut/characters/valkyrie/frames/valkyrie_<slot>.png`, then run `python3 tools/build_sprite_frames.py`. No code changes are needed.

Style: match the existing frames exactly — same pixel density, outline weight, palette, proportions and lighting; facing right; transparent background.

## Combo hit 1 — Spear Slash (18 frames at 60 fps)

| Slot | Canvas | On screen | What it must show |
|---|---|---|---|
| `slash_anticipation` | 128×128 | frames 0–1 | Spear drawn back across the body to her LEFT (rear) hip, spearhead low behind her; shoulders turned away from the target, shield tucked to the chest, knees bent, weight on the back foot. |
| `slash_smear` | 256×128 | frames 2–2 | Mid-swing: torso and shoulders rotating toward the target, spear sweeping horizontally at chest height. Spearhead drawn as a smear (stretched arc), front foot planting. |
| `slash_contact` | 256×128 | frames 3–5 | Swing completed IN FRONT at chest height: the shaft lies horizontally ACROSS her body with the spearhead out in front (swung across, not pushed straight out like a thrust); arms crossed slightly in front, shoulders square to the target. |
| `slash_follow` | 128×128 | frames 6–12 | Follow-through: spear continues past the body to the front-right/down, torso over-rotated, shield arm swinging back for balance — this flows straight into the bash anticipation. |
| `attack_recovery` (existing) | — | frames 13–15 | Return to stance (already drawn). |
| `idle` (existing) | — | frames 16–17 | Return to stance (already drawn). |

## Combo hit 2 — Shield Bash (20 frames at 60 fps)

| Slot | Canvas | On screen | What it must show |
|---|---|---|---|
| `bash_anticipation` | 128×128 | frames 0–3 | Shield pulled back and slightly up, elbow cocked, spear held back along the body; torso leaning back, weight shifting to the rear foot. |
| `bash_contact` | 128×128 | frames 4–8 | Shield punched FORWARD at full arm extension, face of the shield toward the target, torso and front knee driving forward, rear leg extended (clear weight transfer). Spear trails behind. |
| `bash_follow` | 128×128 | frames 9–14 | Shield still forward but relaxing, small recoil; spear brought back to both hands for the finisher. |
| `attack_recovery` (existing) | — | frames 15–17 | Return to stance (already drawn). |
| `idle` (existing) | — | frames 18–19 | Return to stance (already drawn). |

## Combo hit 3 (finisher) — Spear Finisher (34 frames at 60 fps)

| Slot | Canvas | On screen | What it must show |
|---|---|---|---|
| `finisher_windup` | 128×128 | frames 0–5 | Two-handed grip, spear raised high over the REAR shoulder, torso coiled away from the target, deep stance. Clearly bigger wind-up than the slash. |
| `finisher_smear` | 256×128 | frames 6–6 | Fast two-handed horizontal sweep from rear-high to front, spear as a smear arc, body uncoiling, front foot stamping forward. |
| `finisher_contact` | 256×128 | frames 7–11 | Sweep at full extension in front, both hands on the shaft, spear horizontal at hip-to-chest height, body fully rotated, cape flaring. |
| `finisher_follow` | 128×128 | frames 12–21 | Spear carried through to the far side and low, torso over-rotated; sets up the return to idle. |
| `attack_recovery` (existing) | — | frames 22–29 | Return to stance (already drawn). |
| `idle` (existing) | — | frames 30–33 | Return to stance (already drawn). |

## Heavy attack — Heavy Spear (52 frames at 60 fps)

| Slot | Canvas | On screen | What it must show |
|---|---|---|---|
| `heavy_windup` | 128×128 | frames 0–5 | Distinct heavy stance: low wide crouch, spear pulled far back with both hands at the rear hip, spearhead behind her, shield braced, wings slightly raised. |
| `heavy_charge` | 128×128 | frames 6–11 | Same stance coiled tighter (shown while the button is held). A subtle difference from windup (deeper knee bend, spear further back) so charging reads. |
| `heavy_smear` | 256×128 | frames 12–13 | Explosive lunge: whole body launching forward, spear driven straight ahead as a long smear, rear leg fully extended. |
| `heavy_contact` | 256×128 | frames 14–23 | Full forward extension: deepest lunge of the kit, spear at maximum reach, front knee far forward, wings swept back. Must not reuse the basic thrust drawing. |
| `heavy_recovery` | 128×128 | frames 24–43 | Overextended recovery: weight still forward, spear tip dipping, starting to pull back to stance. |
| `idle` (existing) | — | frames 44–51 | Return to stance (already drawn). |

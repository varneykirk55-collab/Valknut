# Berserker — combo & heavy pose art request

Template: `berserker_template.png` (cells are the exact canvas sizes; magenta line = floor, yellow cross = feet anchor, ghost = current idle for scale).

Deliver each pose as `valknut/characters/berserker/frames/berserker_<slot>.png`, then run `python3 tools/build_sprite_frames.py`. No code changes are needed.

Style: match the existing frames exactly — same pixel density, outline weight, palette, proportions and lighting; facing right; transparent background.

## Combo hit 1 — Right Axe Swing (20 frames at 60 fps)

| Slot | Canvas | On screen | What it must show |
|---|---|---|---|
| `right_anticipation` | 128×128 | frames 0–2 | RIGHT (front) axe raised high above and behind the right shoulder, torso twisted away, left axe low and back, knees bent. |
| `right_smear` | 256×128 | frames 3–3 | Right axe mid-swing on a DIAGONAL path from high-back to low-front, drawn as a curved smear; shoulders twisting toward the target. |
| `right_contact` | 256×128 | frames 4–7 | Right axe at the bottom-front of the diagonal (around the opponent's waist), arm extended, body twisted toward the target, weight on the front foot. |
| `right_follow` | 128×128 | frames 8–14 | Right axe carried through low and across the body; the LEFT axe is already cocking up behind the head (the momentum hand-off into hit 2). Not an idle-like pose. |
| `attack_recovery` (existing) | — | frames 15–17 | Return to stance (already drawn). |
| `idle` (existing) | — | frames 18–19 | Return to stance (already drawn). |

## Combo hit 2 — Left Axe Swing (22 frames at 60 fps)

| Slot | Canvas | On screen | What it must show |
|---|---|---|---|
| `left_anticipation` | 128×128 | frames 0–3 | LEFT (rear) axe fully cocked behind the head, torso twisted the other way from hit 1, right axe down and back for counter-balance. |
| `left_smear` | 256×128 | frames 4–4 | Left axe swinging on the OPPOSITE diagonal (high-rear to front, crossing in front of the chest), curved smear, hips turning. |
| `left_contact` | 256×128 | frames 5–8 | Left axe at the end of its arc in front of the chest, body square to the target, step forward. |
| `left_follow` | 128×128 | frames 9–16 | Left axe carried across and down; both arms already starting to rise for the overhead. |
| `attack_recovery` (existing) | — | frames 17–19 | Return to stance (already drawn). |
| `idle` (existing) | — | frames 20–21 | Return to stance (already drawn). |

## Combo hit 3 (finisher) — Double-Axe Overhead (46 frames at 60 fps)

| Slot | Canvas | On screen | What it must show |
|---|---|---|---|
| `overhead_windup` | 128×128 | frames 0–6 | BOTH axes raised high above the head, arms fully extended up and slightly back, back arched, rising onto the toes / small hop — exaggerated anticipation. |
| `overhead_smear` | 256×128 | frames 7–7 | Both axes chopping down in front on a vertical arc, smear trails from overhead to the ground. |
| `overhead_contact` | 256×128 | frames 8–11 | Both axe heads buried at ground level in front of him, deep crouch, shoulders over the knees, debris / impact at the axe heads. |
| `overhead_impact` | 128×128 | frames 12–33 | Recoil: axes bouncing up off the ground, body shaken back slightly, heavy breath. Held through the long recovery before returning to idle. |
| `attack_recovery` (existing) | — | frames 34–41 | Return to stance (already drawn). |
| `idle` (existing) | — | frames 42–45 | Return to stance (already drawn). |

## Heavy attack — Heavy Axe (64 frames at 60 fps)

| Slot | Canvas | On screen | What it must show |
|---|---|---|---|
| `heavy_windup` | 128×128 | frames 0–7 | Deep wind-up unique to the heavy: both axes drawn far back to the side at hip height, body twisted almost 90 degrees away, back foot planted, mantle swinging. |
| `heavy_charge` | 128×128 | frames 8–17 | Same wind-up wound tighter (shown while charging): more twist, lower crouch, veins / war-paint glow. |
| `heavy_smear` | 256×128 | frames 18–19 | Full-body double-axe horizontal sweep, huge curved smear in front, mantle flying. |
| `heavy_contact` | 256×128 | frames 20–29 | Sweep completed in front, both arms extended, entire body rotated through, front foot stamped. Not an enlarged light swing. |
| `heavy_recovery` | 128×128 | frames 30–53 | Overcommitted: body still twisted past the target, axes low, staggering back to stance. |
| `idle` (existing) | — | frames 54–63 | Return to stance (already drawn). |

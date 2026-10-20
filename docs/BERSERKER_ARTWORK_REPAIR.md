# Berserker artwork repair package (for visual approval)

**Branch:** `claude/berserker-artwork-repair`, from `claude/berserker-polish` at `a852cd3`. Not merged.
**Status: partial repair, reviewable, NOT integrated.** The repaired layers live in
`valknut/characters/berserker/layers_repaired/`. The rig, the original layers
(`layers/`), the rig textures, the animation curves and all game code are unchanged.

## Honest summary

I have no illustration tool, only code that draws and composites pixels. So:

- **Done and credible:** the hidden areas that used to show as black voids or flat colour behind the
  arms (cape, back fur, ribcage flanks, the waist band and hip panel) are filled with texture and
  shapes taken from the drawing's own pixels, and the old flat-colour fills are gone. At gameplay
  scale the black holes in the shoulder and torso stress tests are gone.
- **Not achieved:** a genuinely drawn deltoid, torso side and three-quarter torso. What I
  produce is procedural cel-style filling (flat skin, one shade tone, outline) and texture quilting,
  not illustration. It reads at game size, but at enlarged views it is visibly synthetic.
- **Three-quarter torso:** *not achievable with these tools.* I provide a clearly labelled
  feasibility draft, not a variant. It needs a human illustrator.

Details below; every remaining defect is listed.

## Method and guarantees

`tools/repair_berserker_layers.py` (re-runnable, ~6 s) starts from the 17 approved layers, drops the
previous flat-colour fills, and then:

1. **Re-files** 308 pixels that sat in the wrong layer (a strap and fur outline filed under the rear
   arm): 279 to `torso`, 29 to `mantle_front`. The pixels and colours are unchanged; they only change layer.
2. **Draws** hidden anatomy only where the idle drawing already shows a layer *above*, so idle
   is unchanged: restacking the repaired layers gives back the approved idle (max difference 5/255,
   same as the unrepaired layers; the source art is ~99% opaque). `idle_identity.png` shows it.
3. **Texture quilting** (Efros–Freeman) for fur, cape and leather: blocks are copied from the *same
   material's own visible pixels* and joined along minimum-error seams. No blur, no stretching.
4. **Cel drawing** for skin: flat base colour, one shade crescent on the lower right (the drawing's
   light direction), a 3 px outline in the drawing's outline colour.

**Approved pixels untouched:** 100% of the approved visible pixels of `torso`, `mantle_back`, `cape`,
`pelvis`, `mantle_front` and `arm_upper_R` are unchanged; `arm_upper_L` is 94.4% (the 308 re-filed ones).
`masks/<layer>_new.png` marks every new pixel (cape 55,227; mantle_back 24,295; torso 6,976; arm_upper_L
4,201; arm_upper_R 3,135; pelvis 2,919). Other layers are unchanged.

## What each phase delivered

| Phase | Result |
|---|---|
| 2 Rear shoulder (`arm_upper_L`) | A cel-drawn deltoid/upper arm (shoulder cap + elbow end) replaces the ragged flat patch; stays connected at 0/25/45/60/90° and the negative angles. **Defects remain** (below). |
| 3 Torso (`torso`) | Left and right ribcage flanks (cel-drawn), the right waist band (quilted from the belt), and 279 re-filed pixels. The **upper back and the lower back are not reconstructed**. |
| 4 Three-quarter torso | **Not delivered as a variant.** `variants/torso_3q_draft_{25,40}.png` is a cylinder-wrap *feasibility test* (rigid belt medallion and buckle kept round); 8,410 / 11,681 px of the turned body were never drawn and stay empty (masks included). |
| 5 Cape and fur | `cape` is now continuous behind the whole rear side (quilted cloth); `mantle_back` fills behind both shoulders with a fur-tuft lower edge; `mantle_front` is unchanged (it had no gaps to repair). |
| 6 Inspection | `docs/previews/berserker_repair/` (list below). |

## Inspection images (`docs/previews/berserker_repair/`)

`idle_identity.png` (original, restacked, difference ×40) · `shoulder_compare.png` and `torso_compare.png`
(before/after, new pixels tinted magenta) · `layers_repaired.png` (cape, back fur, front fur before/after) ·
`stress_shoulder_{before,after}.png` and `stress_torso_{before,after}.png` (rear shoulder at 0, ±25, ±45,
±60, ±90°; spine at 0, ±10, ±15, ±25, ±35°) · `gameplay_scale.png` (98×104 px, shown 3×) ·
`torso_3q_feasibility.png`.

## Remaining visible defects (honest list)

Judged against the acceptance criteria (no gaps, no flat unfinished anatomy, consistent outline and shading):

1. **Rear shoulder still shows scraps of the old fur outline** (`arm_upper_L`/`mantle_front`) around
   (170–250, 170–200) at +45° to +90°: a few white and dark slivers lie across the new deltoid. They are
   approved pixels that were never part of the arm, so I did not delete them. Needs a manual clean-up.
2. **The new deltoid is a smooth ellipse hull.** It has the right colours and outline but none of the
   drawing's muscle definition (no striations, no highlight). Visible when enlarged.
3. **Torso flanks are flat skin with a shade crescent**, with no ribs, no skin texture and no light
   falloff; they meet the drawn torso along a hard line at around x ≈ 250 and x ≈ 400 (`torso_compare.png`).
   They show when the arms leave the body.
4. **The right waist band is quilted from the belt** and repeats the studs; the **right hip panel**
   (`pelvis`) is quilted leather with an irregular outline: it is patchy at enlarged scale (`stress_shoulder_after.png`,
   right-arm cases) and not a believable continuation of the skirt.
5. **Upper back, spine and lower back are not drawn.** At spine ±25–35° the layer behind the torso
   is the cape or back fur; no gap shows, but a bare back never appears either, which an illustrator may want.
6. **Cape and back fur are texture, not drawn forms.** The cape has no folds and the back fur no
   tuft structure; seams between quilted blocks are visible at 3× as slight tone steps. A few small stray
   cape fragments remain near the right leg (`spine +25`).
7. **`mantle_front` shoulder-to-torso link:** unchanged; when the rear shoulder rises past 60° the fur
   mantle stays on the spine while the arm moves out of it, so the fur no longer covers the shoulder.
8. **Three-quarter torso:** see above. The sides that turn into view are undrawn.

## Needs manual illustration

- Deltoid and upper-arm modelling (rear and front) with the drawing's muscle shading.
- Ribcage/lat flank, upper back, spine and lower back, in the drawing's skin style.
- The three-quarter torso (a full redraw with foreshortened belt, medallion and straps; the draft marks
  where features should land).
- Back fur tufts and cape folds as drawn forms; the right hip panel.

## Regression

Nothing under `valknut/` except the new `layers_repaired/` assets changed, and Godot ignores that folder
(`.gdignore`). See the test summary in the delivery message.

## Files

New: `tools/repair_berserker_layers.py`, `tools/berserker_layer_stress.py`,
`tools/berserker_repair_preview.py`, `tools/berserker_torso_3q_draft.py`;
`valknut/characters/berserker/layers_repaired/` (17 layers, `masks/*_new.png`, `report.json`,
`variants/`); `docs/previews/berserker_repair/`; this document.
Modified: none.

## Reproduce

```
python3 tools/repair_berserker_layers.py       # needs Pillow, numpy, scipy, opencv-python
python3 tools/berserker_torso_3q_draft.py
python3 tools/berserker_repair_preview.py
```

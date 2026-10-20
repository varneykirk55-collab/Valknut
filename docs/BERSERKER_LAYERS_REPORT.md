# Berserker rig layers: inspection report

**Branch:** `claude/berserker-layers`, from `claude/berserker-skeletal-poc` at `0cbff50`.
Not merged. No animation work has been done with these layers yet; they're waiting for
review.

## What this is

The approved idle_01 drawing is split into 17 independent transparent layers. The
source is pose 1 of `valknut/art/source/berserker_v2_idle_v2/berserker_v2_idle_strip.png`,
at its full resolution of 620×655.

- **Visible pixels:** every visible pixel of the drawing belongs to exactly one layer,
  copied unchanged. The visible artwork is preserved, not redrawn.
- **Hidden anatomy:** only areas concealed by other parts are reconstructed (shoulders,
  hips, knees, the torso under the arms, and so on).

**Rebuild:** `python3 tools/build_berserker_layers.py`, then
`python3 tools/berserker_layers_preview.py` for the inspection images. Needs Pillow,
numpy, scipy and opencv-python.

## Files

Everything below is in `valknut/characters/berserker/layers/`. The folder has a
`.gdignore`, so Godot doesn't import it yet.

**Layers** (each 620×655, positioned as in the drawing; screen-left/right as seen,
facing right). Draw order, bottom to top:

| # | Layer | Contents |
|---|---|---|
| 0 | `cape.png` | cape behind the body |
| 1 | `mantle_back.png` | dark fur of the mantle that hangs behind the arms |
| 2 | `leg_lower_L.png` | shin and boot L |
| 3 | `leg_lower_R.png` | shin and boot R |
| 4 | `leg_upper_L.png` | thigh, knee guard and knee fur L |
| 5 | `leg_upper_R.png` | thigh, knee guard and knee fur R |
| 6 | `pelvis.png` | hips, leather skirt panels, fur trim, hanging rings and medallion |
| 7 | `loincloth.png` | the hanging red cloth |
| 8 | `torso.png` | chest, abs, straps, belt and buckle |
| 9 | `arm_upper_L.png` | upper arm L |
| 10 | `arm_upper_R.png` | upper arm R |
| 11 | `mantle_front.png` | white fur over both shoulders, with the gold clasps |
| 12 | `head.png` | head, hair, beard, neck, both braids |
| 13 | `axe_L.png` | the drawn rear axe; see the axe notes |
| 14 | `axe_R.png` | the drawn front axe |
| 15 | `arm_fore_L.png` | elbow fur, bracer and hand L |
| 16 | `arm_fore_R.png` | elbow fur, bracer and hand R |

**Other files:**
- `axe_master.png`: the single master axe for both hands.
- `masks/<layer>_reconstructed.png`: exactly which pixels of each layer were
  reconstructed. White = reconstructed.
- `pivots.json`: draw order, joint pivots (neck, spine root, shoulders, elbows, wrists,
  hips, knees, grips) and where the master axe goes in each hand.
- `layer_report.json`: visible vs reconstructed pixel counts per layer.
- `reference/owner_map.png`: the layer index of every pixel.
- `reference/axe_rear_original.png`: the drawn rear axe, kept for comparison.

**Previews** (`docs/previews/berserker_layers/`):

| File | What it shows |
|---|---|
| `component_sheet.png` | labelled sheet of every layer; magenta = reconstructed |
| `reassembled.png` | original, then layers restacked, then the master axe in both hands |
| `comparison.png` | the same three at gameplay size (98×104 px), plus difference maps |
| `exploded.png` | layers pulled apart, so the reconstructed (magenta) areas show |
| `partition.png` | which layer owns each pixel, plus the joint pivots |

## Results

- **Restacked layers vs the original: identical.**
  - The maximum difference is 2/255, and 5/255 with every reconstructed pixel in
    place. That's because the source drawing's interior is 98–99% opaque (alpha 250–253),
    so whatever sits underneath tints it by about 1%.
  - Silhouette, proportions, armour, clothing, face, colours and both drawn axes are
    unchanged. There are no seams or gaps at gameplay scale.
- **Both build checks pass:**
  - every visible pixel is in exactly one layer;
  - no reconstructed pixel shows in the idle pose.

## Reconstructed anatomy (all generated, not drawn)

| Layer | Reconstructed px | Where |
|---|---|---|
| torso | 8,058 | ribcage sides under both upper arms; chest under the beard and both braids |
| arm_upper_L / R | 3,236 / 1,983 | rounded shoulder caps under the mantle; elbow ends under the elbow fur |
| leg_upper_L / R | 1,561 / 3,131 | rounded hip tops under the skirt |
| leg_lower_L / R | 2,648 / 2,690 | knee tops under the thigh fur |
| pelvis | 11,664 | crotch behind the hanging cloth |
| mantle_front | 1,827 | fur under the hair on the left shoulder |
| mantle_back, cape | 9,220 / 34,946 | about 18–30 px of material behind the body's edges |
| axe_master | handle only | handle through and beyond the fist; pommel cap |

**Method.** The part's own neighbouring colours are extended into the hidden area,
smoothed, and snapped to a 4-colour palette sampled from that part. That gives flat,
cel-style fills. A 2 px outline is added on the new outer edge. Each region is limited to
where another layer covers it in the idle pose.

## Visual compromises (please review)

1. **The reconstructed areas are colour fills, not drawn anatomy.** They have no muscle
   lines, no strap or fur detail, and no shading structure. They're hidden in the idle
   pose and will only show when a joint rotates.
   - Small rotations (roughly ±15–20° at shoulders and hips, less at knees and elbows)
     expose mostly the flat fill and outline. That should read acceptably at game size.
   - Large rotations will show plain colour patches. A proper paint-over of the magenta
     areas (see `exploded.png`) by an artist is the fix.
2. **Some boundaries are straight cuts, not drawn outlines:**
   - torso/pelvis at the belt line;
   - pelvis/thighs above the knee guards;
   - shins at the top of the boots.

   These are hidden at rest, but will show as straight seams if those joints bend a lot.
3. **No outline separates the arms from the chest in the drawing.** The upper arms are
   cut along the drawn bicep and armpit shading. When an arm swings far out, the torso's
   side shows the reconstructed fill.
4. **Strands crossing layers stay with the layer behind.** A few strands of brown
   mantle fur lie over the top of the left upper arm; they're assigned to `mantle_back`,
   so they'll stay behind if that arm moves.
5. **The master axe doesn't match the drawn rear axe.**
   - The two axes in the drawing aren't one design: the rear axe is drawn about 21%
     larger, with a longer blade.
   - Placing the master axe (the front axe, mirrored) in the rear hand by grip and head
     position overlaps the drawn rear axe by 49% (IoU). Its blade is shorter and points
     differently. See `reassembled.png`, right panel.
   - To meet "one identical master design", the rig should use `axe_master.png` in both
     hands, and the rear hand will then look slightly different from the original
     drawing.
6. **The master axe's handle is extended about 70 px past the visible part**, by
   repeating its wrap pattern, and ends in a plain dark cap. The pommel isn't the drawn
   one.
7. **The cape and mantle_back are fragmented,** because only scattered pieces are visible
   between the arms, legs and axes. They work as backing layers, not as independently
   animated cloth.

## Recommended next steps

1. Review the layers, especially `exploded.png` and `component_sheet.png`. If possible,
   have an artist paint over the magenta areas in place; the masks show exactly where.
2. Decide on the rear axe: accept the master axe in both hands (the consistent design),
   or keep the drawn rear axe for the idle pose only.
3. Then extend `berserker_rig_rig.tscn` to the full bone chain using `pivots.json`
   (spine_root > neck; spine_root > shoulders > elbows > wrists > grips; spine_root >
   hips > knees), with these layers as Sprite2D children.

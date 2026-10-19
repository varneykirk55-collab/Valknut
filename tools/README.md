# Sprite & animation tools (Python 3 + Pillow)

| Script | What it does |
|---|---|
| `cut_frames.py` | Cuts the labelled sheets in `valknut/art/source/` into `characters/<legend>/frames/<legend>_<pose>.png` (transparent, 128×128, feet at (64,124); `attack_active` 256×128). |
| `pose_slots.py` | The list of combo/heavy pose slots per legend: art brief, canvas size and placeholder fallback for each. |
| `build_sprite_frames.py` | Writes `<legend>_frames.tres`: one SpriteFrames animation per pose (the game keys them by name). Slots without a PNG use their fallback and are recorded as placeholders. |
| `make_art_requests.py` | Writes `docs/art_requests/<legend>.md` + `<legend>_template.png` (per-slot brief, on-screen timing parsed from the anims, sized template cells). |
| `combo_filmstrip.py` | Lays out `screenshot.tscn --combo-film` captures as a labelled filmstrip. |

Adding new combo/heavy art: save `valknut/characters/<legend>/frames/<legend>_<slot>.png`
(see `docs/art_requests/`), then run `python3 tools/build_sprite_frames.py`. Re-run
`make_art_requests.py` after changing animation timing.

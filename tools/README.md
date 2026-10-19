# Sprite pipeline

`cut_frames.py` turns the labelled sheets in `valknut/art/source/` (`valkyrie_sheet.jpg`,
`berserker_sheet.jpg`) into the game's frames:

```
python3 tools/cut_frames.py        # needs Python 3 + Pillow
```

Output: `valknut/characters/<legend>/frames/<legend>_<pose>.png` for
idle, walk_01–04, jump, fall, hurt, attack_startup, attack_active, attack_recovery.
Frames are 128×128 (attack_active 256×128) with a transparent background and the feet
at (64, 124). The Berserker sheet has one drawing for jump and fall; it's saved as both.

Each legend's `<legend>_frames.tres` (SpriteFrames) references these files: named
animations (`idle`, `walk`, `jump`, …, `attack`) for editor use, plus a `frames` strip
with every pose in a fixed order that the game's AnimationPlayer keys by index
(see the frame constants at the top of `<legend>_anims.gd`).

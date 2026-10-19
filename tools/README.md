# Sprite pipeline

Turns the source sheets in `valknut/art/source/` into the in-game sprite sheets.

```
cd /tmp/sprites                                       # any scratch folder
python3 <repo>/tools/extract_sprites.py               # → raw_<frame>.png (background keyed out)
python3 <repo>/tools/sprite_anchors.py                # → anchors_auto.json (feet anchor per frame)
# optional: anchors_fix.json with {"frame_name": [x, y]} overrides
python3 <repo>/tools/build_sprite_sheets.py           # → <legend>_sheet.png + sheets.json + preview_*.png
cp valkyrie_sheet.png <repo>/valknut/characters/valkyrie/
cp berserker_sheet.png <repo>/valknut/characters/berserker/
```

Every frame is placed in an equal-size cell with the feet anchor at the same point, so
the Sprite2D only changes `frame`. If a sheet's cell size or anchor changes
(see `sheets.json`), update `offset` and `hframes` on the Sprite node in the legend's
`.tscn`. Frame order (and the constants in `<legend>_anims.gd`) follows `ORDER` in
`build_sprite_sheets.py`. Needs Python 3 + Pillow.

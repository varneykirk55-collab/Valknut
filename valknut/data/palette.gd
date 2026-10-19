class_name Palette
extends RefCounted
## Flat Norse palette. Every placeholder shape pulls from here so art can be re-tinted in one spot.

const OUTLINE := Color("141018")
const DEEP_RED := Color("8e2a2a")
const BLOOD_RED := Color("b23a32")
const BONE := Color("e8dfc8")
const BONE_SHADE := Color("bfb59a")
const FOREST := Color("2f5233")
const MOSS := Color("4f7a46")
const DARK_BLUE := Color("1f2f4a")
const FJORD_BLUE := Color("35507a")
const IRON := Color("5a6068")
const IRON_LIGHT := Color("8a919a")
const GOLD := Color("c9a24a")
const WOOD := Color("6b4a2f")
const SKIN := Color("d9a982")
const NIGHT := Color("0f1420")

## Per-player tints for ShapeParts tagged with a palette slot. Mirror matches stay readable.
const PLAYER_COLORS := {
	1: {"primary": DARK_BLUE, "secondary": DEEP_RED, "accent": GOLD, "tag": Color("e05a4a")},
	2: {"primary": FOREST, "secondary": BONE_SHADE, "accent": IRON_LIGHT, "tag": Color("5aa0e0")},
}

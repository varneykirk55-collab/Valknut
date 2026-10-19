class_name Roster
extends RefCounted
## Every legend and stage in the game. `available` flips to true as each one is built.

const LEGENDS := [
	{
		"id": "valkyrie", "name": "Valkyrie", "available": true,
		"scene": "res://valknut/characters/valkyrie/valkyrie.tscn",
		"class": "Aerial · Midweight",
		"blurb": "Spear and shield. Strong air game, hover recovery, Spear Dive.",
	},
	{
		"id": "berserker", "name": "Berserker", "available": true,
		"scene": "res://valknut/characters/berserker/berserker.tscn",
		"class": "Heavy · Grounded",
		"blurb": "Twin hand axes. Slow, hits like a landslide, poor recovery. Rage Spin.",
	},
	{
		"id": "dwarf", "name": "Dwarf", "available": false,
		"scene": "res://valknut/characters/dwarf/dwarf.tscn",
		"class": "Tank", "blurb": "Warhammer and tower shield. Grounded fortress.",
	},
	{
		"id": "trickster", "name": "Trickster", "available": false,
		"scene": "res://valknut/characters/trickster/trickster.tscn",
		"class": "Glass cannon", "blurb": "Dual daggers. Fast, short teleport, dies early.",
	},
	{
		"id": "seidr_witch", "name": "Seidr Witch", "available": false,
		"scene": "res://valknut/characters/seidr_witch/seidr_witch.tscn",
		"class": "Zoner", "blurb": "Staff. Projectiles and slow, heavy smashes.",
	},
	{
		"id": "draugr", "name": "Draugr", "available": false,
		"scene": "res://valknut/characters/draugr/draugr.tscn",
		"class": "Floaty", "blurb": "Undead. Hovers instead of walking. Odd recovery.",
	},
]

const STAGES := [
	{
		"id": "midgard_arena", "name": "Midgard Arena", "available": true,
		"scene": "res://valknut/stages/midgard_arena/midgard_arena.tscn",
	},
	{
		"id": "jotunheim", "name": "Jotunheim", "available": false,
		"scene": "res://valknut/stages/jotunheim/jotunheim.tscn",
	},
]


static var _portraits := {}


static func legend(id: String) -> Dictionary:
	for l in LEGENDS:
		if l.id == id:
			return l
	return LEGENDS[0]


static func stage(id: String) -> Dictionary:
	for s in STAGES:
		if s.id == id:
			return s
	return STAGES[0]


static func available(list: Array) -> Array:
	return list.filter(func(e): return e.available)


## Portrait art for a legend, or null if none exists yet.
## kind: "select" (300 px tall, setup screen), "bust" (HUD), "thumb" (roster strip),
## "full" (original reference art).
## Cached so textures drawn from _draw() stay alive after the draw call returns.
static func portrait(id: String, kind: String) -> Texture2D:
	var path := "res://valknut/art/portraits/%s_%s.png" % [id, kind]
	if not _portraits.has(path):
		_portraits[path] = load(path) if ResourceLoader.exists(path) else null
	return _portraits[path]

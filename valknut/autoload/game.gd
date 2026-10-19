extends Node
## Global game state: match settings, screen routing and debug toggles.

signal screen_requested(path: String)
signal debug_toggled(enabled: bool)

const TITLE_SCREEN := "res://valknut/ui/title_screen.tscn"
const VERSUS_SETUP := "res://valknut/ui/versus_setup.tscn"
const CONTROLS_SCREEN := "res://valknut/ui/controls_screen.tscn"
const MATCH_SCENE := "res://valknut/match/match.tscn"

enum Mode { VERSUS, TRAINING }

var mode: Mode = Mode.VERSUS
var legends := {1: "valkyrie", 2: "valkyrie"}
var stage_id := "midgard_arena"
var stocks := 2
var time_minutes := 3        ## 0 = no timer
var rounds_to_win := 2       ## best of 3
var tap_jump := false

## Art set per legend id ("" or absent = the shipped art), e.g. {"berserker": "v2"}.
## Purely visual: swaps the SpriteFrames, never moves or timing. Built by tools/art_sets.py.
var art_sets := {}

## F1 draws hitboxes (red), hurtboxes (yellow/blue) and blast zones.
var debug_draw := false


func goto(path: String) -> void:
	screen_requested.emit(path)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_F1:
				debug_draw = not debug_draw
				debug_toggled.emit(debug_draw)
			KEY_F11:
				var fs := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
				DisplayServer.window_set_mode(
					DisplayServer.WINDOW_MODE_WINDOWED if fs else DisplayServer.WINDOW_MODE_FULLSCREEN)

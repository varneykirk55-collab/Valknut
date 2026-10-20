extends Node
## Full-body cutout rig prototype: training match, Berserker vs the Valkyrie.
## Open this scene and press F6.  J = light attack (the rigged move).
## T cycles the Berserker's art: full-body rig -> v2 sprites -> shipped pixel art, so the
## same attack can be compared. Switching restarts the match (art is chosen at spawn).
## Moves other than the light attack hold the rig's rest pose.

const SETS := ["fullrig", "v2", ""]
var _index := 0
var _match: Node
var _label := Label.new()


func _ready() -> void:
	Game.mode = Game.Mode.TRAINING
	Game.legends = {1: "berserker", 2: "valkyrie"}
	_label.position = Vector2(12, 12)
	var layer := CanvasLayer.new()
	layer.layer = 50
	layer.add_child(_label)
	add_child(layer)
	_spawn()


func _spawn() -> void:
	if _match:
		_match.queue_free()
	Game.art_sets = {"berserker": SETS[_index]} if SETS[_index] != "" else {}
	_match = load(Game.MATCH_SCENE).instantiate()
	add_child(_match)
	_label.text = "Berserker art: %s    [T] switch" % ("shipped pixel art" if SETS[_index] == "" else SETS[_index])


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_T:
		_index = (_index + 1) % SETS.size()
		_spawn()

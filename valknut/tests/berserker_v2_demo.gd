extends Node
## Preview of the Berserker's v2 art set in a normal training match against the
## Valkyrie. Open this scene and press F6. J = light attack (jab), L = heavy (forward smash).
## Undrawn poses show the reference stand-in with a PLACEHOLDER label.

func _ready() -> void:
	Game.mode = Game.Mode.TRAINING
	Game.legends = {1: "berserker", 2: "valkyrie"}
	Game.art_sets = {"berserker": "v2"}
	add_child(load(Game.MATCH_SCENE).instantiate())

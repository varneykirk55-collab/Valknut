extends Node
## Cutout-rig proof of concept: training match, Berserker on the "rig" art set vs the
## Valkyrie. Open this scene and press F6. J = light attack (the rigged move).
## Other moves hold the rig's rest pose.

func _ready() -> void:
	Game.mode = Game.Mode.TRAINING
	Game.legends = {1: "berserker", 2: "valkyrie"}
	Game.art_sets = {"berserker": "rig"}
	add_child(load(Game.MATCH_SCENE).instantiate())

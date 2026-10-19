extends Node
## Interactive review scene: normal training match, Berserker vs. a dummy.
## Press J without a direction for the first strike; wait before pressing again.

func _ready() -> void:
	Game.mode = Game.Mode.TRAINING
	Game.legends[1] = "berserker"
	Game.legends[2] = "valkyrie"
	var match_scene: Node = load(Game.MATCH_SCENE).instantiate()
	add_child(match_scene)
	for tick in 20:
		await get_tree().physics_frame
	match_scene.fighters[0].reset_for_round(Vector2(-160, -2), 1)
	match_scene.fighters[1].reset_for_round(Vector2(-108, -2), -1)

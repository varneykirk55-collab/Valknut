extends Node
## Dev tool: renders a short scripted match and saves PNGs.
##   godot --path . --fixed-fps 60 res://valknut/tests/screenshot.tscn -- <out_dir>

var out_dir := "user://shots"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	Game.mode = Game.Mode.TRAINING
	Game.debug_draw = "--hitboxes" in args
	var m: Node = load(Game.MATCH_SCENE).instantiate()
	add_child(m)
	var p1: Fighter = m.fighters[0]
	var p2: Fighter = m.fighters[1]
	await frames(10)
	if "--poses" in args:
		await _poses(m, p1, p2)
		get_tree().quit()
		return
	await shot("01_idle")
	p2.global_position = p1.global_position + Vector2(90, 0)
	Input.action_press("p1_strong")
	await frames(30)
	await shot("02_fsmash_charge")
	Input.action_release("p1_strong")
	await frames(14)
	await shot("03_fsmash_hit")
	await frames(14)
	await shot("04_launch")
	await frames(60)
	p1.reset_for_round(Vector2(-100, -2), 1)
	Input.action_press("p1_jump")
	await frames(14)
	Input.action_release("p1_jump")
	Input.action_press("p1_attack")
	await frames(9)
	Input.action_release("p1_attack")
	await shot("05_nair")
	await frames(40)
	p1.reset_for_round(Vector2(-560, -80), 1)
	p1.sm.change(&"air")
	await frames(30)
	await shot("06_ledge")
	p1.reset_for_round(Vector2(-200, -200), 1)
	p1.sm.change(&"air")
	await frames(2)
	Input.action_press("p1_special")
	await frames(30)
	await shot("07_hover")
	Input.action_release("p1_special")
	await frames(60)
	Input.action_press("p1_down")
	await frames(2)
	await shot("08_crouch")
	Input.action_press("p1_attack")
	await frames(8)
	await shot("09_dtilt")
	Input.action_release("p1_attack")
	Input.action_release("p1_down")
	get_tree().quit()


## Freezes Valkyrie on the first active frame of every move, hitboxes drawn.
func _poses(m: Node, p1: Fighter, p2: Fighter) -> void:
	Game.debug_draw = true
	p2.global_position = Vector2(400, -2)
	for id in ["jab1", "jab2", "jab3", "ftilt", "dtilt", "fsmash", "dsmash", "nair", "fair", "dair",
			"nspecial", "sspecial", "dspecial", "getup_attack", "ledge_attack"]:
		var move: MoveData = p1.moves[id]
		var aerial: bool = id in ["nair", "fair", "dair", "nspecial", "dspecial"]
		p1.reset_for_round(Vector2(-100, -160 if aerial else -2), 1)
		if aerial:
			p1.sm.change(&"air")
		await frames(2)
		p1.start_move(id)
		var start: int = move.hitboxes[0].start
		await frames(start)
		m.set_physics_process(false)
		await shot("pose_" + id)
		m.set_physics_process(true)
		await frames(move.total_frames)


func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))


func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame

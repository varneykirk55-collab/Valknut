extends Node
## Dev tool: renders a short scripted match and saves PNGs.
##   godot --path . --fixed-fps 60 res://valknut/tests/screenshot.tscn -- <out_dir> [options]
## Options: --legend=<id> --p2=<id> --hitboxes, and one of --setup (setup screen),
## --poses (every move's first active frame, hitboxes on), --film (attack filmstrips).

var out_dir := "user://shots"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	Game.mode = Game.Mode.TRAINING
	Game.debug_draw = "--hitboxes" in args
	for a in args:
		if a.begins_with("--legend="):
			Game.legends[1] = a.trim_prefix("--legend=")
		if a.begins_with("--p2="):
			Game.legends[2] = a.trim_prefix("--p2=")
	if "--setup" in args:
		var setup: Node = load(Game.VERSUS_SETUP).instantiate()
		add_child(setup)
		await frames(10)
		await shot("setup")
		get_tree().quit()
		return
	var m: Node = load(Game.MATCH_SCENE).instantiate()
	add_child(m)
	var p1: Fighter = m.fighters[0]
	var p2: Fighter = m.fighters[1]
	await frames(10)
	if "--combo-film" in args:
		await _combo_film(m, p1, p2)
		get_tree().quit()
		return
	if "--film" in args:
		await _film(m, p1, p2)
		get_tree().quit()
		return
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
		var aerial: bool = id in ["nair", "fair", "dair", "nspecial"] \
			or (id == "dspecial" and Game.legends[1] == "valkyrie")
		p1.reset_for_round(Vector2(-100, -160 if aerial else -2), 1)
		if aerial:
			p1.sm.change(&"air")
		await frames(2)
		p1.start_move(id)
		var start: int = move.hitboxes[0].start
		if id == "dspecial" and Game.legends[1] == "berserker":
			start = 20  # mid-spin
		await frames(start)
		m.set_physics_process(false)
		await shot("pose_" + id)
		m.set_physics_process(true)
		await frames(move.total_frames)


## Filmstrip per attack: crops around P1 every few frames (filmstrip_<move>_<frame>.png).
func _film(m: Node, p1: Fighter, p2: Fighter) -> void:
	p2.global_position = Vector2(500, -2)
	var aerials := ["nair", "fair", "dair", "nspecial", "dspecial"]
	for id in ["jab1", "jab2", "jab3", "ftilt", "dtilt", "fsmash", "dsmash", "nair", "fair", "dair",
			"nspecial", "sspecial", "dspecial"]:
		var move: MoveData = p1.moves[id]
		var aerial: bool = id in aerials and not (id == "dspecial" and Game.legends[1] == "berserker")
		p1.reset_for_round(Vector2(-60, -200 if aerial else -2), 1)
		if aerial:
			p1.sm.change(&"air")
		await frames(2)
		p1.start_move(id)
		var step := maxi(2, move.total_frames / 10)
		for f in range(0, mini(move.total_frames, step * 10), step):
			# Sample by the move's own frame counter (pausing to capture costs ticks).
			while p1.move_frame < f and p1.sm.current_name == &"attack":
				await frames(1)
			m.set_physics_process(false)
			await RenderingServer.frame_post_draw
			var img := get_viewport().get_texture().get_image()
			var at := p1.get_global_transform_with_canvas().origin
			var r := Rect2i(int(at.x) - 140, int(at.y) - 170, 300, 220)
			r = r.intersection(Rect2i(Vector2i.ZERO, img.get_size()))
			img.get_region(r).save_png(out_dir.path_join("film_%s_%02d.png" % [id, f]))
			m.set_physics_process(true)
		await frames(40)


## Plays the full neutral combo, then the heavy, against a dummy and captures every
## 2 frames around P1. Writes combo_NNN.png plus combo_labels.txt
## (index, move, move frame, pose, PLACEHOLDER flag) for the filmstrip tool.
func _combo_film(m: Node, p1: Fighter, p2: Fighter) -> void:
	var labels: Array[String] = []
	var n := 0
	var first_only := "--first-hit" in OS.get_cmdline_user_args()
	var sample_step := 1 if first_only else 2
	var max_presses := 1 if first_only else 3
	for take in (["combo"] if first_only else ["combo", "heavy"]):
		p1.reset_for_round(Vector2(-160, -2), 1)
		p2.reset_for_round(Vector2(-160 + 52, -2), -1)
		await frames(20)
		var presses := 0
		var hold := 0
		var t := 0
		while t < 110:
			if take == "combo":
				# Press for the next hit as soon as the current one has connected; hold
				# each press a few ticks (captures pause the match between ticks).
				var mv: MoveData = p1.current_move
				var want := presses == 0 or (mv != null and presses < max_presses and mv.id == "jab%d" % presses \
					and p1.move_frame >= mv.hitboxes[0].end)
				if hold > 0:
					hold -= 1
					if hold == 0:
						Input.action_release("p1_attack")
				elif want:
					Input.action_press("p1_attack")
					presses += 1
					hold = 3
			elif t == 0:
				Input.action_press("p1_strong")
			elif t == 3:
				Input.action_release("p1_strong")
			if t % sample_step == 0:
				m.set_physics_process(false)
				await RenderingServer.frame_post_draw
				var img := get_viewport().get_texture().get_image()
				var at := p1.get_global_transform_with_canvas().origin
				var r := (Rect2i(int(at.x) - 130, int(at.y) - 220, 320, 245) if first_only else
					Rect2i(int(at.x) - 110, int(at.y) - 150, 260, 175)).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
				img.get_region(r).save_png(out_dir.path_join("combo_%03d.png" % n))
				var mv2: MoveData = p1.current_move
				var pose := p1.current_pose()
				labels.append("%d|%s|%s|%d|%s|%s" % [n, take, mv2.id if mv2 else String(p1.sm.current_name),
					p1.move_frame if mv2 else 0, pose, "PLACEHOLDER" if pose in p1.placeholder_poses else ""])
				n += 1
				m.set_physics_process(true)
			await frames(1)
			if first_only:
				# physics_frame fires before the match tick; let that tick finish
				# before freezing for the next every-frame screenshot.
				await get_tree().process_frame
			t += 1
			if take == "combo" and presses >= max_presses and p1.sm.current_name == &"idle" and t > 20:
				break
			if take == "heavy" and t > 10 and p1.sm.current_name == &"idle":
				break
		Input.action_release("p1_attack")
	var f := FileAccess.open(out_dir.path_join("combo_labels.txt"), FileAccess.WRITE)
	f.store_string("\n".join(labels))


func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))


func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame

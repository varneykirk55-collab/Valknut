extends Node
## Berserker checks, measured against the Valkyrie in real matches.
##   godot --headless --path . --fixed-fps 60 res://valknut/tests/berserker_test.tscn

var m: Node
var p1: Fighter
var p2: Fighter
var failures := 0


func _ready() -> void:
	Game.mode = Game.Mode.TRAINING

	print("-- every move runs and ends cleanly")
	await spawn("berserker", "valkyrie")
	for id in p1.moves:
		await reset()
		if id in ["nair", "fair", "dair"]:
			p1.global_position = Vector2(-240, -260)
			p1.sm.change(&"air")
			await frames(2)
		p1.start_move(id)
		var ok := await wait_until(func(): return p1.sm.current_name != &"attack", 200)
		check(ok, "%s finishes (→ %s)" % [id, p1.sm.current_name])

	print("-- heavier and slower than the Valkyrie")
	var b_walk := await walk_distance("berserker")
	var v_walk := await walk_distance("valkyrie")
	check(b_walk < v_walk * 0.8, "walks slower (%.0f px vs %.0f px in 40 frames)" % [b_walk, v_walk])
	var b_jump := await jump_height("berserker")
	var v_jump := await jump_height("valkyrie")
	check(b_jump < v_jump, "jumps lower (%.0f px vs %.0f px)" % [b_jump, v_jump])

	var valk_on_valk := await kill_percent("valkyrie", "valkyrie")
	var valk_on_bers := await kill_percent("valkyrie", "berserker")
	var bers_on_valk := await kill_percent("berserker", "valkyrie")
	print("   fsmash KO%%: Valkyrie→Valkyrie %d · Valkyrie→Berserker %d · Berserker→Valkyrie %d" % [valk_on_valk, valk_on_bers, bers_on_valk])
	check(valk_on_bers > valk_on_valk, "survives the same hit longer (weight)")
	check(bers_on_valk <= valk_on_valk - 10, "launches much harder")

	print("-- jab string")
	await spawn("berserker", "valkyrie")
	await reset_close(70.0)
	var max_combo := 0
	for i in 3:
		tap("p1_attack")
		for k in 10:
			await frames(1)
			max_combo = maxi(max_combo, p2.combo_count)
	await frames(50)
	check(is_equal_approx(p2.percent, 16.0), "4 + 4 + 8 = 16%% (got %.1f)" % p2.percent)
	check(max_combo <= 3, "jab string is a true 2-3 hit string (max combo %d)" % max_combo)

	print("-- rage spin")
	await reset_close(40.0)
	var hits := [0]
	var count_hit := func(_f, _d): hits[0] += 1
	p2.damaged.connect(count_hit)
	p1.start_move("dspecial")
	await wait_until(func(): return p1.move_frame >= 60, 200)
	p2.damaged.disconnect(count_hit)
	check(hits[0] >= 5, "multi-hits connect (%d hits, %.0f%%)" % [hits[0], p2.percent])
	check(p2.is_in_hitstun() or p2.sm.current_name in [&"tumble", &"hurt"], "finisher launches")
	check(p1.sm.current_name == &"attack" and p1.can_be_hit(), "endlag is long and punishable (frame %d)" % p1.move_frame)

	print("-- spikes (off-stage, airborne target)")
	for id in ["dair", "fair"]:
		await reset()
		var launch := [Vector2.ZERO]
		var on_launch := func(f: Fighter, _kb): launch[0] = f.kb_velocity
		p2.launched.connect(on_launch)
		p2.percent = 60.0
		p2.global_position = Vector2(-640, -300)
		p2.sm.change(&"air")
		var offset := Vector2(-4, -40) if id == "dair" else Vector2(-50, -62)
		p1.global_position = p2.global_position + offset
		p1.facing = 1
		p1.sm.change(&"air")
		await frames(1)
		p1.global_position = p2.global_position + offset
		p2.vel = Vector2.ZERO
		p1.vel = Vector2.ZERO
		p1.start_move(id)
		await wait_until(func(): return launch[0] != Vector2.ZERO, 40)
		p2.launched.disconnect(on_launch)
		check(launch[0].y > 300.0, "%s spikes (launch vy=%.0f)" % [id, launch[0].y])

	print("-- recovery is weak")
	var b_far := await recovers("berserker", Vector2(-640, 260))
	var v_far := await recovers("valkyrie", Vector2(-640, 260))
	var b_near := await recovers("berserker", Vector2(-600, 150))
	check(v_far and not b_far, "Valkyrie recovers from far below, Berserker doesn't (valk %s, bers %s)" % [v_far, b_far])
	check(b_near, "Berserker still recovers from close to the ledge")

	print("\n%s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	get_tree().quit(1 if failures > 0 else 0)


# --- measurements ---------------------------------------------------------------------

func walk_distance(legend: String) -> float:
	await spawn(legend, "valkyrie")
	await reset()
	var x0 := p1.global_position.x
	press("p1_right")
	await frames(40)
	release("p1_right")
	return p1.global_position.x - x0


func jump_height(legend: String) -> float:
	await spawn(legend, "valkyrie")
	await reset()
	var y0 := p1.global_position.y
	var best := [y0]
	press("p1_jump")
	for i in 50:
		await frames(1)
		best[0] = minf(best[0], p1.global_position.y)
	release("p1_jump")
	return y0 - best[0]


func kill_percent(attacker: String, victim: String) -> int:
	await spawn(attacker, victim)
	for pct in range(30, 220, 5):
		await reset_close(90.0)
		p2.percent = pct
		tap("p1_strong")
		var died := await wait_until(func(): return not p2.alive, 160)
		if died:
			return pct
	return 999


func recovers(legend: String, from: Vector2) -> bool:
	await spawn(legend, "valkyrie")
	await reset()
	p1.global_position = from
	p1.sm.change(&"air")
	press("p1_right")
	tap("p1_jump")
	await frames(16)
	tap("p1_jump")
	await frames(16)
	press("p1_special")
	var died := [false]
	var ok := await wait_until(func():
		died[0] = died[0] or not p1.alive
		return died[0] or p1.sm.current_name in [&"ledge_hang", &"idle", &"land"], 240)
	release("p1_special")
	release("p1_right")
	return ok and not died[0]


# --- helpers ------------------------------------------------------------------------

func spawn(l1: String, l2: String) -> void:
	if m:
		m.queue_free()
		await frames(2)
	Game.legends = {1: l1, 2: l2}
	m = load(Game.MATCH_SCENE).instantiate()
	add_child(m)
	p1 = m.fighters[0]
	p2 = m.fighters[1]
	await frames(3)


func reset() -> void:
	for a in InputMap.get_actions():
		if String(a).begins_with("p1_"):
			Input.action_release(a)
	for i in 2:
		m.fighters[i].reset_for_round(m.stage.spawn_point(i), 1 if i == 0 else -1)
	m._respawn_timers.clear()
	await frames(3)


func reset_close(gap: float) -> void:
	await reset()
	p2.global_position = p1.global_position + Vector2(gap, 0)
	p2.percent = 0.0
	await frames(3)


func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func press(a: String) -> void:
	Input.action_press(a)


func release(a: String) -> void:
	Input.action_release(a)


func tap(a: String) -> void:
	Input.action_press(a)
	await frames(2)
	Input.action_release(a)


func wait_until(cond: Callable, max_frames: int) -> bool:
	for i in max_frames:
		if cond.call():
			return true
		await get_tree().physics_frame
	return cond.call()


func check(ok: bool, what: String) -> void:
	print("   %s %s" % ["ok  " if ok else "FAIL", what])
	if not ok:
		failures += 1

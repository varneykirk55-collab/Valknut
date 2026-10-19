extends Node
## Headless gameplay checks. Spins up a real training match and drives P1 through
## scripted inputs, asserting on state changes, hits and KOs.
##
##   godot --headless --path . --fixed-fps 60 res://valknut/tests/sim_test.tscn
##
## Exit code 0 = all checks passed.

var match_node: Node
var p1: Fighter
var p2: Fighter
var failures := 0


func _ready() -> void:
	Game.mode = Game.Mode.TRAINING
	Game.legends = {1: "valkyrie", 2: "valkyrie"}
	match_node = load(Game.MATCH_SCENE).instantiate()
	add_child(match_node)
	p1 = match_node.fighters[0]
	p2 = match_node.fighters[1]
	await _run()
	print("\n%s (%d failure%s)" % ["PASS" if failures == 0 else "FAIL", failures, "" if failures == 1 else "s"])
	get_tree().quit(1 if failures > 0 else 0)


func _run() -> void:
	await frames(5)

	print("-- movement")
	await reset()
	press("p1_right")
	await frames(20)
	check(p1.sm.current_name == &"walk", "holding right walks (got %s)" % p1.sm.current_name)
	check(p1.global_position.x > -240.0 + 40.0, "walk moved right")
	release("p1_right")
	await frames(10)
	check(p1.sm.current_name == &"idle", "releasing returns to idle")

	print("-- jumps")
	await reset()
	press("p1_jump")
	await frames(6)
	check(p1.sm.current_name == &"air", "jump leaves the ground")
	await frames(12)
	var full_hop_y := p1.global_position.y
	release("p1_jump")
	await land(p1)
	await reset()
	tap("p1_jump")
	await frames(17)
	check(p1.global_position.y > full_hop_y + 30.0, "short hop is lower than full hop (%.0f vs %.0f)" % [p1.global_position.y, full_hop_y])
	await land(p1)
	await reset()
	tap("p1_jump")
	await frames(10)
	tap("p1_jump")
	await frames(2)
	check(p1.air_jumps_left == 1, "air jump consumed (left: %d)" % p1.air_jumps_left)
	await land(p1)

	print("-- jab combo")
	await reset_close(60.0)
	for i in 3:
		tap("p1_attack")
		await frames(9)
	await frames(40)
	check(is_equal_approx(p2.percent, 12.0), "jab1+2+3 deals 3+3+6 = 12%% (got %.1f)" % p2.percent)

	print("-- forward tilt / flick smash")
	await reset_close(80.0)
	press("p1_right")
	await frames(8)
	tap("p1_attack")
	await frames(30)
	release("p1_right")
	check(p2.percent >= 8.0 and p2.percent <= 10.0, "held right + attack = ftilt (%.1f%%)" % p2.percent)
	await frames(30)
	await reset_close(80.0)
	press("p1_right")
	tap("p1_attack")
	await frames(30)
	release("p1_right")
	check(p2.percent >= 14.0, "flick right + attack = fsmash (%.1f%%)" % p2.percent)

	print("-- smash charge")
	await reset_close(80.0)
	press("p1_strong")
	await frames(70)
	release("p1_strong")
	await frames(20)
	check(p2.percent > 19.0, "charged fsmash deals more than uncharged (%.1f%%)" % p2.percent)

	print("-- kill percents (fsmash, no DI, from P1 spawn)")
	var kill_at := -1
	for pct in range(40, 200, 10):
		await reset_close(80.0)
		p2.percent = pct
		tap("p1_strong")
		await frames(150)
		if not p2.alive or p2.sm.current_name == &"dead" or match_node._respawn_timers.has(p2):
			kill_at = pct
			break
	print("   uncharged fsmash KOs at ~%d%% (near center-left, launched right)" % kill_at)
	check(kill_at >= 80 and kill_at <= 150, "fsmash kill percent is in a sane range")
	await frames(120)

	print("-- hitstun, tumble, tech")
	await reset_close(80.0)
	p2.percent = 60.0
	tap("p1_strong")
	await frames(16)
	check(p2.is_in_hitstun(), "victim is in hitstun after the hit")
	await wait_until(func(): return p2.hitlag == 0, 30)
	await frames(1)
	check(p2.sm.current_name == &"tumble", "strong hit causes tumble (got %s)" % p2.sm.current_name)
	var landed_state := await wait_until(func(): return p2.sm.current_name in [&"knockdown", &"tech", &"idle"], 240)
	check(landed_state, "tumbling dummy lands in knockdown (got %s)" % p2.sm.current_name)

	print("-- ground tech (P1 as victim of a scripted launch)")
	await reset()
	p1.global_position = Vector2(0, -200)
	p1.sm.change(&"air")
	await frames(2)
	p1.receive_hit(p2, HitboxData.make(1, 1, Vector2.ZERO, Vector2.ONE, 10, 270, 90, 0), 1.0)
	await wait_until(func(): return p1.global_position.y > -60.0 and p1.sm.current_name == &"tumble", 120)
	tap("p1_dodge")
	await wait_until(func(): return p1.sm.current_name != &"tumble", 60)
	check(p1.sm.current_name == &"tech", "dodge just before landing techs (got %s)" % p1.sm.current_name)

	print("-- platform drop")
	await reset()
	p1.global_position = Vector2(-230, -170)
	await frames(10)
	check(p1.is_on_floor() and p1.on_platform, "stands on soft platform")
	tap("p1_down")
	await frames(20)
	check(p1.global_position.y > -140.0, "tapping down drops through (y=%.0f)" % p1.global_position.y)

	print("-- ledge grab + options")
	await reset()
	p1.global_position = Vector2(-500, -60)
	p1.sm.change(&"air")
	await wait_until(func(): return p1.sm.current_name == &"ledge_hang", 60)
	check(p1.sm.current_name == &"ledge_hang", "falling next to the ledge grabs it")
	check(not p1.can_be_hit(), "ledge grab is briefly invulnerable")
	await frames(8)
	press("p1_right")
	await wait_until(func(): return p1.sm.current_name == &"idle", 60)
	release("p1_right")
	check(p1.sm.current_name == &"idle" and p1.global_position.x > -450.0, "climbing up lands on stage")

	print("-- recovery: hover from below the stage edge")
	await reset()
	p1.global_position = Vector2(-640, 120)
	p1.sm.change(&"air")
	p1.facing = 1
	press("p1_right")
	tap("p1_jump")
	await frames(14)
	tap("p1_jump")
	await frames(14)
	press("p1_special")
	var recovered := await wait_until(func(): return p1.sm.current_name in [&"ledge_hang", &"idle", &"land"], 160)
	release("p1_special")
	release("p1_right")
	check(recovered, "double jumps + hover reach the stage from far below (%s)" % p1.sm.current_name)

	print("-- spear dive hits and bounces")
	await reset()
	p2.global_position = Vector2(-140, -2)
	p1.global_position = Vector2(-240, -100)
	p1.facing = 1
	p1.sm.change(&"air")
	await frames(2)
	p1.global_position = Vector2(-240, -100)
	press("p1_down")
	tap("p1_special")
	await frames(2)
	release("p1_down")
	var trace: Array[String] = []
	var dived := await wait_until(func():
		trace.append("%s@%.0f,%.0f" % [p1.sm.current_name, p1.global_position.x, p1.global_position.y])
		return p2.percent > 0.0, 60)
	if not dived:
		print("   trace: ", ", ".join(trace.slice(0, 30)))
	check(dived, "spear dive connects")
	await frames(3)
	check(p1.sm.current_name == &"air", "valkyrie bounces back into air state on hit (got %s)" % p1.sm.current_name)

	print("-- combo decay: no infinite jab")
	await reset_close(55.0)
	var max_combo := 0
	for i in 30:
		tap("p1_attack")
		await frames(4)
		max_combo = maxi(max_combo, p2.combo_count)
	check(max_combo <= 3, "jab string is at most 3 true hits (max combo %d)" % max_combo)

	print("-- dtilt can't loop")
	await reset_close(55.0)
	press("p1_down")
	max_combo = 0
	for i in 30:
		tap("p1_attack")
		await frames(5)
		max_combo = maxi(max_combo, p2.combo_count)
	release("p1_down")
	check(max_combo <= 4, "repeated down tilt drops within a few hits (max combo %d)" % max_combo)

	print("-- dash, run, air dodge, waveland")
	await reset()
	tap("p1_right")
	await frames(3)
	press("p1_right")
	await frames(4)
	check(p1.sm.current_name == &"dash", "double-tap dashes (got %s)" % p1.sm.current_name)
	await frames(14)
	check(p1.sm.current_name == &"run", "holding after a dash runs (got %s)" % p1.sm.current_name)
	release("p1_right")
	await frames(20)
	tap("p1_jump")
	await frames(14)
	press("p1_right")
	tap("p1_dodge")
	await frames(6)
	check(p1.sm.current_name == &"air_dodge" and not p1.can_be_hit(), "air dodge is intangible (%s)" % p1.sm.current_name)
	release("p1_right")
	await land(p1)
	check(not p1.air_dodge_available or p1.is_on_floor(), "air dodge used until landing")

	print("-- shield charge")
	await reset_close(150.0)
	press("p1_right")
	tap("p1_special")
	await frames(30)
	release("p1_right")
	check(p2.percent >= 8.0, "shield charge travels and hits (%.1f%%)" % p2.percent)

	print("-- ledge options")
	for opt in ["p1_dodge", "p1_attack", "p1_jump", "p1_down"]:
		await reset()
		p1.global_position = Vector2(-500, -60)
		p1.sm.change(&"air")
		await wait_until(func(): return p1.sm.current_name == &"ledge_hang", 60)
		await frames(8)
		tap(opt)
		var expect: StringName = {"p1_dodge": &"ledge_action", "p1_attack": &"ledge_action",
			"p1_jump": &"air", "p1_down": &"air"}[opt]
		await frames(4)
		check(p1.sm.current_name == expect, "ledge %s → %s (got %s)" % [opt, expect, p1.sm.current_name])
		await wait_until(func(): return p1.sm.current_name in [&"idle", &"land"], 120)

	print("-- knockdown getup attack")
	await reset()
	p1.sm.change(&"knockdown")
	await frames(22)
	tap("p1_attack")
	await frames(4)
	check(p1.sm.current_name == &"attack" and p1.current_move.id == "getup_attack", "attack from knockdown = getup attack")
	await frames(40)

	print("-- blast zone + respawn")
	await reset()
	p1.global_position = Vector2(0, 1000)
	await frames(2)
	check(not p1.alive, "below the bottom blast zone = KO")
	await wait_until(func(): return p1.alive, 120)
	check(p1.sm.current_name == &"respawn" and p1.invuln_frames > 0, "respawns invulnerable on the rune")


# --- helpers -------------------------------------------------------------------------

func reset() -> void:
	for a in InputMap.get_actions():
		if String(a).begins_with("p1_"):
			Input.action_release(a)
	for i in 2:
		match_node.fighters[i].reset_for_round(match_node.stage.spawn_point(i), 1 if i == 0 else -1)
	match_node._respawn_timers.clear()
	await frames(3)


## Puts P2 `gap` px in front of P1 at the left spawn.
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


func land(f: Fighter) -> void:
	await wait_until(func(): return f.is_on_floor() and f.sm.current_name == &"idle", 180)


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

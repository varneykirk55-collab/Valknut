extends Node
## Three-hit neutral combo, heavy attack and classification regression tests.
##   godot --headless --path . --fixed-fps 60 res://valknut/tests/combo_test.tscn

const COMBO := ["jab1", "jab2", "jab3"]
## Pose slot shown on each combo hit's first hitbox frame (contact must sync with the hit).
const CONTACT := {
	"valkyrie": {"jab1": &"slash_contact", "jab2": &"bash_contact", "jab3": &"finisher_contact", "fsmash": &"heavy_contact"},
	"berserker": {"jab1": &"right_contact", "jab2": &"left_contact", "jab3": &"overhead_contact", "fsmash": &"heavy_contact"},
}
const COMBO_DAMAGE := {"valkyrie": 12.0, "berserker": 16.0}

var m: Node
var p1: Fighter
var p2: Fighter
var failures := 0


func _ready() -> void:
	Game.mode = Game.Mode.TRAINING
	for pair in [["valkyrie", "berserker"], ["berserker", "valkyrie"], ["valkyrie", "valkyrie"], ["berserker", "berserker"]]:
		print("-- %s vs %s" % pair)
		await spawn(pair[0], pair[1])
		await combo_suite(pair[0])
	for legend in ["valkyrie", "berserker"]:
		print("-- %s: data checks" % legend)
		await spawn(legend, "valkyrie")
		data_checks(legend)
		await specials_still_work()
	print("-- classification")
	await classification()
	print("\n%s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	get_tree().quit(1 if failures > 0 else 0)


func combo_suite(legend: String) -> void:
	# Full string with one press per hit, pressed as soon as each hit connects.
	await reset_close(52.0)
	var seq: Array[String] = []
	var kbs: Array[float] = []
	var on_launch := func(_f, kb): kbs.append(kb)
	p2.launched.connect(on_launch)
	var poses_at_contact := {}
	for i in 3:
		tap("p1_attack")
		await record_until(seq, poses_at_contact, func(): return p1.sm.current_name == &"attack" \
			and p1.current_move != null and p1.current_move.id == COMBO[i] and p1._hit_registry.size() > 0, 60)
	await record_until(seq, poses_at_contact, func(): return p1.sm.current_name == &"idle", 120)
	p2.launched.disconnect(on_launch)
	check(seq == ["jab1", "jab2", "jab3"], "three presses play jab1 → jab2 → jab3 (%s)" % [seq])
	check(is_equal_approx(p2.percent, COMBO_DAMAGE[legend]), "all three hits land: %.0f%% (expected %.0f)" % [p2.percent, COMBO_DAMAGE[legend]])
	check(kbs.size() == 3 and kbs[2] > kbs[0] * 1.5 and kbs[2] > kbs[1] * 1.5,
		"finisher launches much harder than hits 1-2 (kb %s)" % [kbs.map(func(k): return int(k))])
	for id in COMBO:
		check(poses_at_contact.get(id, &"") == CONTACT[legend][id],
			"%s shows %s on its first hitbox frame (got %s)" % [id, CONTACT[legend][id], poses_at_contact.get(id, &"-")])
	check(p1.current_pose() == &"idle", "string returns to the idle pose")

	# Stop after any hit: no further press → the hit plays out and returns to neutral.
	for stop_after in [1, 2]:
		await reset_close(52.0)
		var s2: Array[String] = []
		for i in stop_after:
			await tap("p1_attack")
			await record_until(s2, {}, func(): return p1.current_move != null and p1.current_move.id == COMBO[i], 40)
			await frames(1)  # let the release register before the next press
		await record_until(s2, {}, func(): return p1.sm.current_name == &"idle", 80)
		check(s2 == COMBO.slice(0, stop_after), "stopping after hit %d: %s then idle" % [stop_after, s2])

	# Early press (before the chain window opens) is queued, not dropped. With the
	# 7-frame buffer alone, a press on frame 2 would expire before the Berserker's
	# chain_from (9).
	await reset_close(52.0)
	await tap("p1_attack")
	await wait_until(func(): return p1.current_move != null and p1.current_move.id == "jab1" and p1.move_frame >= 2, 20)
	var pressed_at := p1.move_frame
	await tap("p1_attack")  # well before jab1.chain_from
	var chained := await wait_until(func(): return p1.current_move != null and p1.current_move.id == "jab2", 60)
	check(chained, "a press on jab1 frame %d (chain opens at %d) is remembered and chains into jab2" % [pressed_at, p1.moves.jab1.chain_from])

	# Timeout: pressing after the string has returned to neutral starts over at hit 1.
	await reset_close(52.0)
	await tap("p1_attack")
	await wait_until(func(): return p1.sm.current_name == &"idle" and p1.current_move == null, 60)
	await tap("p1_attack")
	await frames(4)
	check(p1.current_move != null and p1.current_move.id == "jab1", "a late press restarts the combo at hit 1")

	# One queued press only: three quick presses during jab1 still give one hit at a time.
	await reset_close(52.0)
	await tap("p1_attack")
	await frames(1)
	await tap("p1_attack")
	await frames(1)
	await tap("p1_attack")
	var s3: Array[String] = []
	await record_until(s3, {}, func(): return p1.sm.current_name == &"idle", 140)
	check(s3.size() >= 2 and s3[0] == "jab1" and s3[1] == "jab2", "mashing advances one hit at a time (%s)" % [s3])

	# Interrupted: getting hit during hit 1 drops the combo; next press is hit 1 again.
	await reset_close(52.0)
	await tap("p1_attack")
	await wait_until(func(): return p1.current_move != null and p1.current_move.id == "jab1" and p1.move_frame >= 2, 20)
	await tap("p1_attack")  # queued press that must be dropped by the interrupt
	await frames(1)
	p1.receive_hit(p2, HitboxData.make(1, 1, Vector2.ZERO, Vector2.ONE, 5, 60, 30, 40), 1.0)
	var s4: Array[String] = []
	await record_until(s4, {}, func(): return p1.sm.current_name in [&"idle", &"air"] and not p1.is_in_hitstun(), 120)
	check(not ("jab2" in s4), "getting hit cancels the queued combo press (%s)" % [s4])
	await wait_until(func(): return p1.is_on_floor() and p1.sm.current_name == &"idle", 120)
	await tap("p1_attack")
	await frames(4)
	check(p1.current_move != null and p1.current_move.id == "jab1", "after an interrupt the combo restarts at hit 1")

	# No infinite: mashing for 4 seconds never produces more than a 3-hit true combo,
	# and the victim gets out.
	await reset_close(52.0)
	var max_combo := 0
	for i in 120:
		if i % 2 == 0:
			tap("p1_attack")
		await frames(2)
		max_combo = maxi(max_combo, p2.combo_count)
	check(max_combo <= 3, "mashing never exceeds a 3-hit true combo (max %d)" % max_combo)
	var dist := absf(p2.global_position.x - p1.global_position.x)
	check(dist > 60.0 or not p2.alive, "victim is pushed out of jab range by the finisher (%.0f px)" % dist)
	await frames(30)


func data_checks(legend: String) -> void:
	var mv: Dictionary = p1.moves
	# Hitbox timing: each hit's contact pose and hitbox start are the same frame (checked
	# live above); here: windows are ordered and bounded.
	for id in ["jab1", "jab2"]:
		var md: MoveData = mv[id]
		check(md.chain_from > md.hitboxes[0].end and md.chain_window_end() <= md.total_frames,
			"%s chain window opens after its hit and closes by its last frame" % id)
	check(mv.jab3.chain_to == "", "jab3 ends the string (no loop back into jab1)")
	var heavy: MoveData = mv.fsmash
	var fin: MoveData = mv.jab3
	check(heavy.total_frames - heavy.hitboxes[0].end > fin.total_frames - fin.hitboxes[0].end,
		"heavy has longer recovery than the combo finisher (%d vs %d frames)" % [
			heavy.total_frames - heavy.hitboxes[0].end, fin.total_frames - fin.hitboxes[0].end])
	check(heavy.hitboxes[0].start > fin.hitboxes[0].start, "heavy has longer anticipation than the finisher")
	check(heavy.hitboxes[0].damage > fin.hitboxes[0].damage, "heavy hits harder than the finisher")
	# Heavy must not reuse combo drawings: its pose slots are its own.
	var lib := p1.anim.get_animation_library(&"")
	var heavy_poses := _poses(lib.get_animation("fsmash"))
	var combo_poses := {}
	for id in COMBO:
		for pose in _poses(lib.get_animation(id)):
			combo_poses[pose] = true
	var shared := heavy_poses.filter(func(pz): return combo_poses.has(pz) and not String(pz) in ["idle"])
	check(shared.is_empty(), "heavy attack uses no combo pose slot (shared: %s)" % [shared])
	check(heavy_poses.all(func(pz): return pz == &"idle" or String(pz).begins_with("heavy_")),
		"heavy attack poses are dedicated heavy_* slots (%s)" % [heavy_poses])
	# Every pose an animation asks for exists in the SpriteFrames.
	var sprite := p1.rig.find_child("Sprite", true, false) as AnimatedSprite2D
	var missing := []
	for anim_name in lib.get_animation_list():
		for pose in _poses(lib.get_animation(anim_name)):
			if not sprite.sprite_frames.has_animation(pose):
				missing.append("%s:%s" % [anim_name, pose])
	check(missing.is_empty(), "every keyed pose exists in %s_frames.tres %s" % [legend, missing])


func specials_still_work() -> void:
	for id in ["nspecial", "sspecial", "dspecial", "nair", "fair", "dair", "ftilt", "dtilt", "dsmash", "fsmash"]:
		await reset()
		if id in ["nair", "fair", "dair"]:
			p1.global_position = Vector2(-240, -260)
			p1.sm.change(&"air")
			await frames(2)
		p1.start_move(id)
		var ok := await wait_until(func(): return p1.sm.current_name != &"attack", 220)
		check(ok, "%s still runs and ends (→ %s)" % [id, p1.sm.current_name])


func classification() -> void:
	await spawn("valkyrie", "berserker")
	var v: Fighter = p1
	var b: Fighter = p2
	check(v.stats.archetype == "Vanguard" and b.stats.archetype == "Heavy", "archetypes: Valkyrie Vanguard, Berserker Heavy")
	check(b.stats.weight > v.stats.weight, "Heavy is heavier (%.0f vs %.0f)" % [b.stats.weight, v.stats.weight])
	check(b.stats.walk_speed < v.stats.walk_speed and b.stats.run_speed < v.stats.run_speed, "Heavy is slower on the ground")
	check(v.stats.air_jumps > b.stats.air_jumps and v.stats.air_speed > b.stats.air_speed, "Vanguard has the better air mobility")
	var dmg := func(f: Fighter, ids: Array) -> float:
		var t := 0.0
		for id in ids:
			t += (f.moves[id] as MoveData).hitboxes[0].damage
		return t
	check(dmg.call(b, COMBO) > dmg.call(v, COMBO), "Heavy's combo deals more damage")
	check((b.moves.fsmash as MoveData).hitboxes[0].damage > (v.moves.fsmash as MoveData).hitboxes[0].damage, "Heavy's heavy attack hits harder")
	var reach := func(f: Fighter, id: String) -> float:
		var h: HitboxData = (f.moves[id] as MoveData).hitboxes[0]
		return h.offset.x + h.size.x * 0.5
	check(reach.call(v, "ftilt") > reach.call(b, "jab1"), "Vanguard keeps a spear reach advantage")
	var rec := func(f: Fighter, id: String) -> int:
		var md: MoveData = f.moves[id]
		return md.total_frames - md.hitboxes[0].end
	check(rec.call(b, "jab3") > rec.call(v, "jab3") and rec.call(b, "fsmash") > rec.call(v, "fsmash"),
		"Heavy has the longer recovery on powerful attacks")


# --- helpers -----------------------------------------------------------------------

## Records each new move id (and the pose on each move's first hitbox frame) until cond.
func record_until(seq: Array, contact_poses: Dictionary, cond: Callable, max_frames: int) -> bool:
	for i in max_frames:
		var mv: MoveData = p1.current_move
		if mv and p1.sm.current_name == &"attack":
			if seq.is_empty() or seq[-1] != mv.id:
				seq.append(mv.id)
			if not mv.hitboxes.is_empty() and p1.move_frame == mv.hitboxes[0].start and not contact_poses.has(mv.id):
				contact_poses[mv.id] = p1.current_pose()
		if cond.call():
			return true
		await get_tree().physics_frame
	return cond.call()


static func _poses(a: Animation) -> Array:
	var out := []
	for t in a.get_track_count():
		if String(a.track_get_path(t)).ends_with(":animation"):
			for k in a.track_get_key_count(t):
				var pz = a.track_get_key_value(t, k)
				if not out.has(pz):
					out.append(pz)
	return out


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

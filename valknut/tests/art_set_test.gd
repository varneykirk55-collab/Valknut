extends Node
## Art sets (Game.art_sets) swap visuals only. Checks the Berserker's "v2" set loads,
## never shows the shipped pixel frames, flags every undrawn pose, and leaves combat
## frame-for-frame identical.
##   godot --headless --path . --fixed-fps 60 res://valknut/tests/art_set_test.tscn

const V2_FRAMES := "res://valknut/characters/berserker/berserker_v2_frames.tres"
const MILESTONE := ["idle_01", "idle_02", "idle_03", "light_anticipation", "light_smear", "light_contact",
	"light_recovery", "light_settle", "heavy_windup", "heavy_charge", "heavy_smear", "heavy_contact",
	"heavy_recovery"]

var m: Node
var p1: Fighter
var p2: Fighter
var failures := 0


func _ready() -> void:
	Game.mode = Game.Mode.TRAINING

	print("-- shipped art is the default")
	Game.art_sets = {}
	await spawn("berserker", "valkyrie")
	check(p1.art_set == &"" and sprite(p1).sprite_frames.resource_path.ends_with("berserker_frames.tres"),
		"Berserker uses berserker_frames.tres")
	check(p2.art_set == &"" and sprite(p2).sprite_frames.resource_path.ends_with("valkyrie_frames.tres"),
		"Valkyrie uses valkyrie_frames.tres")

	print("-- v2 art set")
	Game.art_sets = {"berserker": "v2"}
	await spawn("berserker", "valkyrie")
	var frames: SpriteFrames = sprite(p1).sprite_frames
	check(p1.art_set == &"v2" and frames.resource_path == V2_FRAMES, "Berserker loads berserker_v2_frames.tres")
	check(p2.art_set == &"" and sprite(p2).sprite_frames.resource_path.ends_with("valkyrie_frames.tres"),
		"Valkyrie is untouched")
	check(sprite(p1).texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS, "smooth (linear) sampling")
	var pixel := []
	for a in frames.get_animation_names():
		var path := frames.get_frame_texture(a, 0).resource_path
		if not "/frames_v2/" in path:
			pixel.append(a)
	check(pixel.is_empty(), "no pose falls back to the shipped pixel frames %s" % [pixel])
	var missing := []
	for a in p1.anim.get_animation_list():
		var anim := p1.anim.get_animation(a)
		var t := anim.find_track(NodePath(BerserkerAnims.FRAME), Animation.TYPE_VALUE)
		if t == -1:
			continue
		for k in anim.track_get_key_count(t):
			var pose: StringName = anim.track_get_key_value(t, k)
			if not frames.has_animation(pose) and not pose in missing:
				missing.append(pose)
	check(missing.is_empty(), "every pose the animations key exists in the set %s" % [missing])
	var unflagged := []
	for pose in MILESTONE:
		var own := frames.get_frame_texture(pose, 0).resource_path.ends_with("berserker_%s.png" % pose)
		if not own and not pose in p1.placeholder_poses:
			unflagged.append(pose)
	check(unflagged.is_empty(), "undrawn milestone poses are flagged as placeholders %s" % [unflagged])
	var idle_keys := pose_keys(p1, "idle")
	var light_keys := pose_keys(p1, "jab1")
	var heavy_keys := pose_keys(p1, "fsmash")
	check(idle_keys == ["idle_01", "idle_02", "idle_03", "idle_02"], "idle keys its own breathing poses %s" % [idle_keys])
	check(light_keys.slice(0, 5) == ["light_anticipation", "light_smear", "light_contact", "light_recovery", "light_settle"],
		"light attack (jab1) keys its own poses %s" % [light_keys])
	var shared := []
	for pose in heavy_keys:
		if pose in light_keys and pose != "idle":
			shared.append(pose)
	check(shared.is_empty(), "light and heavy share no pose %s" % [shared])
	for id in p1.moves:
		await reset()
		if id in ["nair", "fair", "dair"]:
			p1.global_position = Vector2(-240, -260)
			p1.sm.change(&"air")
			await frames(2)
		p1.start_move(id)
		var ok := await wait_until(func(): return p1.sm.current_name != &"attack", 200)
		if not ok:
			check(false, "%s finishes with v2 art" % id)
	check(true, "every move runs and ends with v2 art")

	print("-- combat is identical with and without the art set")
	for take in [["jab1"], ["fsmash"], ["ftilt"], ["jab1", "jab2", "jab3"]]:
		Game.art_sets = {}
		var shipped := await trace(take)
		Game.art_sets = {"berserker": "v2"}
		var v2 := await trace(take)
		check(shipped == v2 and shipped.size() > 0, "%s: %d frames of damage, knockback and positions match"
			% [" > ".join(take), shipped.size()])

	Game.art_sets = {}
	print("PASS (0 failures)" if failures == 0 else "FAIL (%d failures)" % failures)
	get_tree().quit(1 if failures else 0)


## Per-frame state of both fighters while P1 performs `ids` back to back.
func trace(ids: Array) -> Array:
	await spawn("berserker", "valkyrie")
	await reset()
	p2.global_position = p1.global_position + Vector2(60, 0)
	await frames(3)
	var out := []
	for id in ids:
		p1.start_move(id)
		for f in 70:
			await frames(1)
			out.append([p1.sm.current_name, p1.move_frame, p1.global_position.round(), p2.percent,
				p2.sm.current_name, p2.global_position.round(), p2.vel.round()])
			if id != ids[-1] and p1.current_move and p1.current_move.id == id \
					and p1.move_frame >= p1.current_move.hitboxes[0].end + 1:
				break
	return out


func pose_keys(f: Fighter, anim_name: String) -> Array:
	var anim := f.anim.get_animation(anim_name)
	var t := anim.find_track(NodePath(BerserkerAnims.FRAME), Animation.TYPE_VALUE)
	var out := []
	for k in anim.track_get_key_count(t):
		out.append(String(anim.track_get_key_value(t, k)))
	return out


func sprite(f: Fighter) -> AnimatedSprite2D:
	return f.rig.find_child("Sprite", true, false)


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
	for i in 2:
		m.fighters[i].reset_for_round(m.stage.spawn_point(i), 1 if i == 0 else -1)
	m._respawn_timers.clear()
	await frames(3)


func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


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

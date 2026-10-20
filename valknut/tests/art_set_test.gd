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

	print("-- rig art set (cutout proof of concept)")
	Game.art_sets = {"berserker": "rig"}
	await spawn("berserker", "valkyrie")
	var art := p1.rig.find_child("ArtRig", true, false)
	check(p1.art_set == &"rig" and art != null and not sprite(p1).visible, "cutout rig replaces the sprite")
	check(p2.art_set == &"" and sprite(p2).visible, "Valkyrie is untouched")
	var jab := p1.anim.get_animation("jab1")
	check(jab.find_track(NodePath(BerserkerAnims.ELBOW), Animation.TYPE_VALUE) != -1, "jab1 keys the elbow bone")
	var stuck := []
	for id in p1.moves:
		await reset()
		if id in ["nair", "fair", "dair"]:
			p1.global_position = Vector2(-240, -260)
			p1.sm.change(&"air")
			await frames(2)
		p1.start_move(id)
		if not await wait_until(func(): return p1.sm.current_name != &"attack", 200):
			stuck.append(id)
	check(stuck.is_empty(), "every move runs and ends with the rig %s" % [stuck])

	print("-- full-body rig art set (fullrig)")
	Game.art_sets = {"berserker": "fullrig"}
	await spawn("berserker", "valkyrie")
	var full := p1.rig.find_child("ArtRig", true, false)
	check(p1.art_set == &"fullrig" and full != null and not sprite(p1).visible, "full-body rig replaces the sprite")
	check(p2.art_set == &"" and sprite(p2).visible, "Valkyrie is untouched")
	var layers := full.find_child("Layers", true, false).get_children()
	var textures := {}
	for l in layers:
		textures[(l as Sprite2D).texture.resource_path] = true
	check(layers.size() == 17 and not textures.is_empty(), "all 17 layers are present (%d)" % layers.size())
	var axe_l := full.find_child("axe_L", true, false) as Sprite2D
	var axe_r := full.find_child("axe_R", true, false) as Sprite2D
	check(axe_l.texture == axe_r.texture and axe_l.scale.is_equal_approx(axe_r.scale), "both axes are the same texture at the same scale")
	check(axe_l.texture.resource_path.ends_with("axe_master.png"), "both axes use axe_master.png")
	var bones := ["Hips", "ThighL", "ShinL", "ThighR", "ShinR", "Spine", "Chest", "Neck", "ShoulderL", "ElbowL",
		"ShoulderR", "ElbowR"]
	var no_bone := []
	for bone in bones:
		if full.find_child(bone, true, false) == null:
			no_bone.append(bone)
	check(no_bone.is_empty(), "skeleton has shoulder, elbow, chest, hip and knee bones %s" % [no_bone])
	var moved := []
	var jab1 := p1.anim.get_animation("jab1")
	for bone in ["Hips", "ThighL", "ShinL", "ThighR", "ShinR", "Spine", "Neck", "ShoulderL", "ElbowL", "ShoulderR", "ElbowR"]:
		var path := NodePath(BerserkerAnims.SK + _bone_path(bone) + ":rotation")
		var t := jab1.find_track(path, Animation.TYPE_VALUE)
		var lo := 1e9
		var hi := -1e9
		if t != -1:
			for k in jab1.track_get_key_count(t):
				var v: float = jab1.track_get_key_value(t, k)
				lo = minf(lo, v)
				hi = maxf(hi, v)
		if t == -1 or rad_to_deg(hi - lo) < 3.0:
			moved.append(bone)
	check(moved.is_empty(), "jab1 moves every bone by 3 degrees or more %s" % [moved])
	check(is_equal_approx(jab1.length, 20.0 / 60.0), "jab1 keeps its 20-frame length")
	var stuck_full := []
	for id in p1.moves:
		await reset()
		if id in ["nair", "fair", "dair"]:
			p1.global_position = Vector2(-240, -260)
			p1.sm.change(&"air")
			await frames(2)
		p1.start_move(id)
		if not await wait_until(func(): return p1.sm.current_name != &"attack", 200):
			stuck_full.append(id)
	check(stuck_full.is_empty(), "every move runs and ends with the full-body rig %s" % [stuck_full])
	await spawn("berserker", "valkyrie")
	await reset()
	var feet := [p1.global_position]
	var foot_l := full_foot(p1, "FootL")
	var foot_r := full_foot(p1, "FootR")
	var rest_l := foot_l.global_position
	var rest_r := foot_r.global_position
	p1.start_move("jab1")
	var drift := 0.0
	for f in 20:
		await frames(1)
		drift = maxf(drift, maxf(foot_l.global_position.distance_to(rest_l + (p1.global_position - feet[0])),
			foot_r.global_position.distance_to(rest_r + (p1.global_position - feet[0]))))
	check(drift < 1.0, "feet stay planted through jab1 (max drift %.2f px)" % drift)

	print("-- combat is identical with and without the art set")
	for take in [["jab1"], ["fsmash"], ["ftilt"], ["jab1", "jab2", "jab3"]]:
		Game.art_sets = {}
		var shipped := await trace(take)
		Game.art_sets = {"berserker": "v2"}
		var v2 := await trace(take)
		Game.art_sets = {"berserker": "rig"}
		var cutout := await trace(take)
		Game.art_sets = {"berserker": "fullrig"}
		var fullrig := await trace(take)
		check(shipped == v2 and shipped == cutout and shipped == fullrig and shipped.size() > 0,
			"%s: %d frames of damage, knockback and positions match (shipped, v2, rig, fullrig)" % [" > ".join(take), shipped.size()])
	for set_name in ["rig", "fullrig"]:
		Game.art_sets = {"berserker": set_name}
		await spawn("berserker", "valkyrie")
		await reset()
		p2.global_position = p1.global_position + Vector2(60, 0)
		await frames(3)
		p1.start_move("jab1")
		await frames(30)
		check(is_equal_approx(p2.percent, 4.0), "%s light attack still deals 4%% (got %.1f)" % [set_name, p2.percent])

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


## Path of a rig bone under the Skeleton node.
func _bone_path(bone: String) -> String:
	var chains := {"Hips": "Hips", "ThighL": "Hips/ThighL", "ShinL": "Hips/ThighL/ShinL", "ThighR": "Hips/ThighR",
		"ShinR": "Hips/ThighR/ShinR", "Spine": "Hips/Spine", "Neck": "Hips/Spine/Neck",
		"ShoulderL": "Hips/Spine/ShoulderL", "ElbowL": "Hips/Spine/ShoulderL/ElbowL",
		"ShoulderR": "Hips/Spine/ShoulderR", "ElbowR": "Hips/Spine/ShoulderR/ElbowR"}
	return chains[bone]


func full_foot(f: Fighter, marker: String) -> Node2D:
	return f.rig.find_child(marker, true, false)


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

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
	check_polish(jab1)
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
	print("-- repeated light attacks return to the idle pose")
	Game.art_sets = {"berserker": "fullrig"}
	await spawn("berserker", "valkyrie")
	await reset()
	var arm := p1.rig.find_child("ShoulderR", true, false) as Node2D
	var hip := p1.rig.find_child("Hips", true, false) as Node2D
	var rest_hip := hip.position
	var worst := 0.0
	var all_idle := true
	for n in 3:
		p1.start_move("jab1")
		var done := await wait_until(func(): return p1.sm.current_name != &"attack", 120)
		all_idle = all_idle and done
		await frames(3)
		worst = maxf(worst, maxf(absf(rad_to_deg(arm.rotation)), hip.position.distance_to(rest_hip)))
	check(all_idle and worst < 2.0, "3 consecutive jab1s each end back at the idle pose (worst offset %.2f)" % worst)

	print("-- the first full-rig attack is still available")
	BerserkerAnims.fullrig_basic_jab = true
	var basic := BerserkerAnims.build(&"fullrig").get_animation("jab1")
	BerserkerAnims.fullrig_basic_jab = false
	var polished := BerserkerAnims.build(&"fullrig").get_animation("jab1")
	check(is_equal_approx(basic.length, polished.length) and not is_equal_approx(
		_val(basic, BerserkerAnims.P_SH_R + ":rotation", 2), _val(polished, BerserkerAnims.P_SH_R + ":rotation", 2)),
		"basic and polished jab1 have the same length and different poses")

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


func _val(anim: Animation, path: String, frame: float) -> Variant:
	return anim.value_track_interpolate(anim.find_track(NodePath(path), Animation.TYPE_VALUE), frame / 60.0)


## The polished jab1 reads as: load (COG drops, hips and shoulders twist against each
## other) -> hips-first release -> impact -> follow-through, and stays inside the limits
## that keep the known artwork gaps hidden (BERSERKER_FULLRIG.md D1-D4, D7).
func check_polish(a: Animation) -> void:
	var sk := BerserkerAnims.SK
	var rot := func(path: String, f: float) -> float: return rad_to_deg(_val(a, path + ":rotation", f))
	var hips_y := func(f: float) -> float: return (_val(a, BerserkerAnims.P_HIPS + ":position", f) as Vector2).y
	var hips_x := func(f: float) -> float: return (_val(a, BerserkerAnims.P_HIPS + ":position", f) as Vector2).x
	var rest_y: float = BerserkerAnims.FR.POS_HIPS.y
	check(hips_y.call(2) - rest_y >= 6.0, "load: centre of gravity drops at least 6 px (%.1f)" % (hips_y.call(2) - rest_y))
	check(hips_x.call(2) < BerserkerAnims.FR.POS_HIPS.x - 4.0, "load: weight is shifted back over the rear leg")
	check(rot.call(BerserkerAnims.P_HIPS, 2) * rot.call(BerserkerAnims.P_SPINE, 2) < 0.0,
		"load: hips and shoulders twist in opposite directions (%.1f vs %.1f degrees)" % [
			rot.call(BerserkerAnims.P_HIPS, 2), rot.call(BerserkerAnims.P_SPINE, 2)])
	var share := func(get: Callable) -> float:
		return (get.call(3) - get.call(2)) / (get.call(4) - get.call(2))
	var hip_share: float = share.call(func(f): return hips_x.call(f))
	var spine_share: float = share.call(func(f): return rot.call(BerserkerAnims.P_SPINE, f))
	var sh_share: float = share.call(func(f): return rot.call(BerserkerAnims.P_SH_R, f))
	var wr_share: float = share.call(func(f): return rot.call(BerserkerAnims.P_AX_R, f))
	check(hip_share > spine_share and spine_share > sh_share and sh_share > wr_share,
		"release: hips lead, then torso, shoulder, wrist (share of the motion done by frame 3: %.2f > %.2f > %.2f > %.2f)"
		% [hip_share, spine_share, sh_share, wr_share])
	var v23: float = absf(rot.call(BerserkerAnims.P_SH_R, 3) - rot.call(BerserkerAnims.P_SH_R, 2))
	var v34: float = absf(rot.call(BerserkerAnims.P_SH_R, 4) - rot.call(BerserkerAnims.P_SH_R, 3))
	check(v34 > v23 * 1.4, "release: the arm is fastest just before impact (%.0f then %.0f degrees per frame)" % [v23, v34])
	check(hips_y.call(4) - rest_y >= 8.0, "impact: weight sinks onto the front leg (hips %.1f px down)" % (hips_y.call(4) - rest_y))
	var spine_peak := 0.0
	var chest_lo := 1.0
	var chest_hi := 1.0
	var rear_peak := 0.0
	var step_late := 0.0
	var bones := [BerserkerAnims.P_HIPS, BerserkerAnims.P_SPINE, BerserkerAnims.P_NECK, BerserkerAnims.P_SH_R,
		BerserkerAnims.P_EL_R, BerserkerAnims.P_AX_R, BerserkerAnims.P_SH_L, BerserkerAnims.P_EL_L]
	for f in range(0, 20):
		spine_peak = maxf(spine_peak, absf(rot.call(BerserkerAnims.P_SPINE, f)))
		var cx: float = (_val(a, BerserkerAnims.P_CHEST + ":scale", f) as Vector2).x
		chest_lo = minf(chest_lo, cx)
		chest_hi = maxf(chest_hi, cx)
		rear_peak = maxf(rear_peak, absf(rot.call(BerserkerAnims.P_SH_L, f)))
		if f >= 5:
			for b in bones:
				step_late = maxf(step_late, absf(rot.call(b, f + 1) - rot.call(b, f)))
	check(spine_peak <= 15.0, "limit: torso lean stays within 15 degrees (%.1f)" % spine_peak)
	check(chest_lo >= 0.95 and chest_hi <= 1.05, "limit: chest scale stays within 5 percent (%.3f to %.3f)" % [chest_lo, chest_hi])
	check(rear_peak <= 25.0, "limit: rear shoulder stays within 25 degrees (%.1f)" % rear_peak)
	check(step_late <= 18.0, "follow-through and recovery have no snaps (max %.1f degrees per frame)" % step_late)
	var end_off := 0.0
	for b in bones:
		end_off = maxf(end_off, absf(rot.call(b, 19.0 + 1.0)))
	check(end_off < 0.5 and hips_y.call(20) - rest_y < 0.1, "recovery ends exactly on the idle pose")


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

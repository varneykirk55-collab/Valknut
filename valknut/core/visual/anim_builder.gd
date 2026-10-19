class_name AnimBuilder
extends RefCounted
## Builds AnimationPlayer animations from compact frame-based key lists, so a legend's
## whole animation set reads like frame data:
##
##   b.add("jab1", 18, false, {
##       "Rig/SpearArm:rotation": [[0, -0.4], [3, -1.6], [12, -1.6], [18, -0.4]],
##   })
##
## Keys are [frame, value] at 60 fps. Tracks ending in ":frame" (Sprite2D frame index)
## are discrete; all others interpolate linearly. Every track listed in the default pose but not
## in an animation gets a constant key at its default, so poses never leak between
## animations. Track paths are relative to the AnimationPlayer's root (the Visual node).

const FPS := 60.0

var library := AnimationLibrary.new()
var _default_pose := {}


func _init(default_pose: Dictionary) -> void:
	_default_pose = default_pose


func add(anim_name: String, frames: int, loop: bool, tracks: Dictionary) -> void:
	var a := Animation.new()
	a.length = maxf(frames, 1) / FPS
	a.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	var all := _default_pose.duplicate()
	all.merge(tracks, true)
	for path in all:
		var t := a.add_track(Animation.TYPE_VALUE)
		a.track_set_path(t, NodePath(path))
		# Sprite frame indices must snap, everything else blends.
		var discrete := String(path).ends_with(":frame")
		a.value_track_set_update_mode(t, Animation.UPDATE_DISCRETE if discrete else Animation.UPDATE_CONTINUOUS)
		a.track_set_interpolation_type(t, Animation.INTERPOLATION_NEAREST if discrete else Animation.INTERPOLATION_LINEAR)
		var keys = all[path]
		if keys is Array:
			for k in keys:
				a.track_insert_key(t, float(k[0]) / FPS, k[1])
		else:
			a.track_insert_key(t, 0.0, keys)
	library.add_animation(anim_name, a)

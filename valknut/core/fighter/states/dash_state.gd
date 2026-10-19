extends FighterState
## Initial dash burst. Reversing during the dash starts a new dash the other way
## (dash dancing). Holding the direction at the end continues into a run.

var dir := 1


func enter(data: Dictionary) -> void:
	dir = data.get("dir", f.facing)
	f.face(dir)
	f.vel.x = dir * f.stats.dash_speed
	f.play_anim("dash", true)


func tick() -> void:
	if f.try_ground_actions():
		return
	var dx := f.input.dir_x()
	if dx == -dir:
		sm.change(&"dash", {"dir": dx})
		return
	f.vel.x = dir * f.stats.dash_speed
	f.apply_gravity()
	f.move_body()
	if not f.is_on_floor():
		sm.change(&"air")
		return
	if frame >= f.stats.dash_frames:
		sm.change(&"run" if dx == dir else &"idle")

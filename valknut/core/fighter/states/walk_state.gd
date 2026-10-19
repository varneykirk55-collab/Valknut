extends FighterState
## Walking. Speed follows how far the stick is tilted; keyboard always walks at full speed.
## Double-tap a direction to dash.


func enter(_data: Dictionary) -> void:
	f.play_anim("walk")


func tick() -> void:
	if f.try_ground_actions():
		return
	var dash := f.input.double_tapped_x()
	if dash != 0:
		sm.change(&"dash", {"dir": dash})
		return
	var dx := f.input.dir_x()
	if dx == 0:
		sm.change(&"idle")
		return
	if f.input.dir_y() > 0 and absf(f.input.stick.y) > absf(f.input.stick.x):
		sm.change(&"crouch")
		return
	f.face(dx)
	f.ground_accelerate(dx * f.stats.walk_speed * clampf(absf(f.input.x()) * 1.25, 0.4, 1.0))
	f.apply_gravity()
	f.move_body()
	if not f.is_on_floor():
		sm.change(&"air")

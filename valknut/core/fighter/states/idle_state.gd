extends FighterState
## Standing still. Hub for every grounded action.


func enter(_data: Dictionary) -> void:
	f.play_anim("idle")
	f.hurtbox.reset_size()


func tick() -> void:
	if f.try_ground_actions():
		return
	var dash := f.input.double_tapped_x()
	if dash != 0:
		sm.change(&"dash", {"dir": dash})
		return
	if f.input.dir_x() != 0:
		sm.change(&"walk")
		return
	if f.input.dir_y() > 0:
		sm.change(&"crouch")
		return
	f.ground_friction()
	f.apply_gravity()
	f.move_body()
	if not f.is_on_floor():
		sm.change(&"air")

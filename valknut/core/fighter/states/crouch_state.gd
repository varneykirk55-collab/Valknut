extends FighterState
## Crouching shrinks the hurtbox. Down attack here is the down tilt.


func enter(_data: Dictionary) -> void:
	f.play_anim("crouch")
	f.hurtbox.set_height(f.stats.crouch_height)


func exit() -> void:
	f.hurtbox.reset_size()


func tick() -> void:
	if f.try_ground_actions():
		return
	if f.input.dir_y() <= 0:
		sm.change(&"idle")
		return
	f.ground_friction(1.5)
	f.apply_gravity()
	f.move_body()
	if not f.is_on_floor():
		sm.change(&"air")

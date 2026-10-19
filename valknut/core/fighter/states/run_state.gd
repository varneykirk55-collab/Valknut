extends FighterState
## Running. Letting go slides to a stop in idle; pressing back turns with a fresh dash.


func enter(_data: Dictionary) -> void:
	f.play_anim("run")


func tick() -> void:
	if f.try_ground_actions():
		return
	var dx := f.input.dir_x()
	if dx == 0:
		sm.change(&"idle")
		return
	if dx == -f.facing:
		sm.change(&"dash", {"dir": dx})
		return
	if f.input.dir_y() > 0 and absf(f.input.stick.y) > absf(f.input.stick.x):
		sm.change(&"crouch")
		return
	f.ground_accelerate(f.facing * f.stats.run_speed)
	f.apply_gravity()
	f.move_body()
	if not f.is_on_floor():
		sm.change(&"air")

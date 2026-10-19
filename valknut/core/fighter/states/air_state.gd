extends FighterState
## Jumping and falling.

var _rising := true


func enter(data: Dictionary) -> void:
	f.hurtbox.reset_size()
	_rising = f.vel.y < 0.0
	if data.get("air_jump", false):
		f.play_anim("air_jump", true)
	else:
		f.play_anim("jump" if _rising else "fall")


func tick() -> void:
	if f.try_air_actions():
		return
	if f.try_ledge_grab():
		return
	f.check_fast_fall()
	f.apply_gravity()
	f.air_drift()
	f.move_body()
	if f.is_on_floor():
		f.land(Fighter.NORMAL_LANDING_LAG)
		return
	if _rising and f.vel.y >= 0.0:
		_rising = false
		f.play_anim("fall")

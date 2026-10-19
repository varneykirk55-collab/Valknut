extends FighterState
## Landing lag. Normal landings are short; aerials and specials pass their own lag.

var lag := 4


func enter(data: Dictionary) -> void:
	lag = data.get("lag", Fighter.NORMAL_LANDING_LAG)
	f.vel.y = 0.0
	f.fast_falling = false
	f.refresh_air_options()
	f.play_anim("land", true)
	Sfx.play("land", 0.1, -10.0)


func tick() -> void:
	f.ground_friction()
	f.apply_gravity()
	f.move_body()
	if not f.is_on_floor():
		sm.change(&"air")
		return
	if frame >= lag:
		sm.change(&"crouch" if f.input.dir_y() > 0 else &"idle")

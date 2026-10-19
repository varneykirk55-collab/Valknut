extends FighterState
## Light hitstun (knockback below the tumble threshold). Also the pose held during
## hitlag before every launch. No actions until hitstun runs out.

var stun := 0


func enter(data: Dictionary) -> void:
	stun = data.get("hitstun", 0)
	f.hurtbox.reset_size()
	f.play_anim("hurt", true)


func tick() -> void:
	stun -= 1
	if f.is_on_floor():
		f.ground_friction()
		f.apply_gravity()
	else:
		f.apply_gravity()
		f.air_drift(0.4)
	f.move_body()
	if stun <= 0:
		f.combo_count = 0
		sm.change(&"idle" if f.is_on_floor() else &"air")


func is_hitstun() -> bool:
	return stun > 0

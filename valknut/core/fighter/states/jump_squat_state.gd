extends FighterState
## Pre-jump crouch. Releasing jump before it ends gives a short hop.
## Attack pressed during jump squat stays buffered and comes out as an aerial.


func enter(_data: Dictionary) -> void:
	f.play_anim("jump_squat", true)


func tick() -> void:
	f.ground_friction(0.5)
	if frame < f.stats.jump_squat_frames:
		f.apply_gravity()
		f.move_body()
		return
	var full_hop := f.input.held("jump")
	f.vel.y = -(f.stats.jump_velocity if full_hop else f.stats.short_hop_velocity)
	# Keep run momentum, nudged by the stick.
	var cap := f.stats.air_speed * 1.15
	f.vel.x = clampf(f.vel.x + f.input.x() * f.stats.air_speed * 0.35, -cap, cap)
	Sfx.play("jump", 0.05, -6.0)
	sm.change(&"air", {"jumped": true})
	f.move_body()

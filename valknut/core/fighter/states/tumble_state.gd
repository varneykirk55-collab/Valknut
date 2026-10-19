extends FighterState
## Launched hard enough to tumble. During hitstun you can only DI and drift; afterwards
## you can act. Hitting the ground without teching = knockdown (or a bounce if fast),
## hitting a wall or ceiling without teching bounces you off it.

## Faster than this into the ground (px/s) and you bounce instead of lying down.
const BOUNCE_SPEED := 900.0
const BOUNCE_KEEP := 0.55

var stun := 0


func enter(data: Dictionary) -> void:
	stun = data.get("hitstun", 0)
	f.fast_falling = false
	f.hurtbox.reset_size()
	f.play_anim("tumble", true)


func tick() -> void:
	if stun > 0:
		stun -= 1
		if stun == 0:
			f.combo_count = 0
	else:
		if f.try_air_actions():
			return
		if f.try_ledge_grab():
			return
	f.apply_gravity()
	f.air_drift(0.5 if stun > 0 else 1.0)
	f.move_body()

	if f.is_on_floor():
		if f.can_tech():
			f.consume_tech()
			sm.change(&"tech", {"dir": f.input.dir_x()})
		elif f.impact_velocity.y > BOUNCE_SPEED:
			f.kb_velocity.y = -f.impact_velocity.y * BOUNCE_KEEP
			f.vel.y = 0.0
			Sfx.play("land", 0.1, -2.0)
		else:
			sm.change(&"knockdown")
		return
	if f.hit_wall or f.hit_ceiling:
		var n := f.wall_normal if f.hit_wall else Vector2.DOWN
		if f.can_tech():
			f.consume_tech()
			f.kb_velocity = Vector2.ZERO
			f.vel = Vector2(n.x * 180.0, -420.0 if f.hit_wall else 0.0)
			f.invuln_frames = 14
			Sfx.play("tech")
			sm.change(&"air")
			return
		# Bounce: reflect the launch off the surface, losing some speed.
		var v := f.impact_velocity
		if f.hit_wall:
			f.kb_velocity.x = -v.x * BOUNCE_KEEP
		else:
			f.kb_velocity.y = -v.y * BOUNCE_KEEP


func is_hitstun() -> bool:
	return stun > 0

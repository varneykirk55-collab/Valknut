extends FighterState
## Air dodge. Neutral: dodge in place. Directional: a burst of movement with more endlag.
## One per airtime (restored by landing, grabbing a ledge or getting hit).
## Landing during a directional air dodge keeps the slide momentum (wavelanding).

const NEUTRAL_TOTAL := 34
const NEUTRAL_INTANGIBLE := Vector2i(3, 26)
const DIRECTIONAL_TOTAL := 44
const DIRECTIONAL_INTANGIBLE := Vector2i(3, 20)
const BURST_FRAMES := 16
const WAVELAND_LAG := 10

var direction := Vector2.ZERO


func enter(data: Dictionary) -> void:
	f.air_dodge_available = false
	f.fast_falling = false
	var stick: Vector2 = data.get("dir", Vector2.ZERO)
	direction = stick.normalized() if stick.length() > 0.3 else Vector2.ZERO
	if direction != Vector2.ZERO:
		f.vel = direction * f.stats.air_dodge_speed
		f.kb_velocity = Vector2.ZERO
	else:
		f.vel *= 0.3
	f.play_anim("air_dodge", true)
	Sfx.play("dodge", 0.1, -6.0)


func tick() -> void:
	if direction != Vector2.ZERO:
		if frame <= BURST_FRAMES:
			# Burst decays linearly to ~10% of the dodge speed; no gravity during it.
			var t := float(frame) / BURST_FRAMES
			f.vel = direction * f.stats.air_dodge_speed * lerpf(1.0, 0.1, t)
		else:
			f.apply_gravity()
			f.air_drift(0.3)
	else:
		f.apply_gravity(0.6)
		f.air_drift(0.5)
	f.move_body()
	if f.is_on_floor():
		f.vel.x *= 0.85
		f.land(WAVELAND_LAG)
		return
	if f.try_ledge_grab():
		return
	if frame >= (DIRECTIONAL_TOTAL if direction != Vector2.ZERO else NEUTRAL_TOTAL):
		sm.change(&"air")


func is_intangible() -> bool:
	var w := DIRECTIONAL_INTANGIBLE if direction != Vector2.ZERO else NEUTRAL_INTANGIBLE
	return frame >= w.x and frame <= w.y

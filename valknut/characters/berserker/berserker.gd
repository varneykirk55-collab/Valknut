class_name Berserker
extends Fighter
## Berserker — heavyweight with twin hand axes. Slow on the ground and in the air,
## one mid-air jump, falls fast, but nearly every hit launches. Poor recovery.

const LEAP_FRAME := 8
const LEAP_SPEED := 900.0
const LEAP_DRIFT := 150.0

const LUNGE_FROM := 13
const LUNGE_TO := 22
const LUNGE_SPEED := 720.0

const SPIN_FROM := 9
const SPIN_TO := 52
const SPIN_DRIFT := 240.0
## Fall speed cap while spinning in the air (the spin slows his fall, it doesn't stop it).
const SPIN_MAX_FALL := 300.0


func _ready() -> void:
	stats = _make_stats()
	super()


static func _make_stats() -> FighterStats:
	var s := FighterStats.new()
	s.display_name = "Berserker"
	s.archetype = "Heavy"
	s.weight = 118.0
	s.walk_speed = 200.0
	s.dash_speed = 470.0
	s.run_speed = 400.0
	s.dash_frames = 12
	s.ground_accel = 2000.0
	s.ground_friction = 2600.0
	s.roll_distance = 130.0
	s.air_speed = 250.0
	s.air_accel = 1100.0
	s.air_friction = 300.0
	s.gravity = 2700.0
	s.max_fall_speed = 950.0
	s.fast_fall_speed = 1500.0
	s.jump_velocity = 860.0
	s.short_hop_velocity = 520.0
	s.air_jump_velocity = 760.0
	s.air_jumps = 1
	s.jump_squat_frames = 5
	s.air_dodge_speed = 820.0
	s.height = 92.0
	s.crouch_height = 62.0
	s.half_width = 22.0
	return s


## P1 as drawn; P2's red cloth and war paint are hue-shifted to woad blue.
func costumes() -> Array[Dictionary]:
	return [{}, {"hue_shift": 0.6, "hue_width": 0.07}]


func build_moves() -> Dictionary:
	return BerserkerMoves.build(self)


func build_animations() -> AnimationLibrary:
	return BerserkerAnims.build()


# --- Skull Leap ---------------------------------------------------------------------

func leap_tick(_self: Fighter, t: int) -> void:
	if t < LEAP_FRAME:
		vel = Vector2(vel.x * 0.7, minf(vel.y, 0.0) * 0.5)  # crouch, kill momentum
	elif t == LEAP_FRAME:
		vel = Vector2(input.x() * LEAP_DRIFT, -LEAP_SPEED)
		Sfx.play("jump", 0.05, -2.0)


# --- Cleaving Lunge -------------------------------------------------------------------

func lunge_tick(_self: Fighter, t: int) -> void:
	if t < LUNGE_FROM:
		vel = Vector2(vel.x * 0.6, minf(vel.y, 0.0) * 0.5)
	elif t <= LUNGE_TO:
		vel = Vector2(facing * LUNGE_SPEED, 0.0)
	else:
		vel.x = move_toward(vel.x, 0.0, 2600.0 * DT)
		if not is_on_floor():
			vel.y = minf(vel.y + stats.gravity * DT, stats.max_fall_speed)


func lunge_hit(_self: Fighter, _target: Fighter) -> void:
	vel.x = facing * 80.0
	move_frame = LUNGE_TO + 1  # stop the lunge, straight into endlag


# --- Rage Spin -------------------------------------------------------------------------

func rage_spin_tick(_self: Fighter, t: int) -> void:
	var airborne := not is_on_floor()
	if t < SPIN_FROM:
		vel = Vector2(vel.x * 0.7, minf(vel.y, 0.0) * 0.5)
		return
	if t <= SPIN_TO:
		# He can steer the spin slowly; in the air it slows his fall.
		vel.x = input.x() * SPIN_DRIFT if input.dir_x() != 0 else vel.x * 0.85
		if airborne:
			vel.y = minf(vel.y + stats.gravity * 0.35 * DT, SPIN_MAX_FALL)
	else:
		vel.x = move_toward(vel.x, 0.0, 2600.0 * DT)
		if airborne:
			vel.y = minf(vel.y + stats.gravity * DT, stats.max_fall_speed)

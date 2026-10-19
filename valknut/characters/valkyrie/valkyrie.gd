class_name Valkyrie
extends Fighter
## Valkyrie — aerial specialist. Spear + shield, two mid-air jumps, floaty fall,
## hover recovery and the Spear Dive.

const HOVER_LIFT_FRAME := 7
const HOVER_LIFT_SPEED := 1000.0
const HOVER_RISE_END := 24
const HOVER_FALL_SPEED := 90.0

const CHARGE_DASH_FROM := 9
const CHARGE_DASH_TO := 24
const CHARGE_SPEED := 860.0

const DIVE_START := 11
const DIVE_SPEED := 1350.0
## 60° below horizontal.
const DIVE_DIR := Vector2(0.5, 0.866)

var _dive_from_ground := false


func _ready() -> void:
	stats = _make_stats()
	super()


static func _make_stats() -> FighterStats:
	var s := FighterStats.new()
	s.display_name = "Valkyrie"
	s.weight = 92.0
	s.walk_speed = 290.0
	s.dash_speed = 640.0
	s.run_speed = 540.0
	s.air_speed = 330.0
	s.air_accel = 1800.0
	s.gravity = 2200.0
	s.max_fall_speed = 800.0
	s.fast_fall_speed = 1300.0
	s.jump_velocity = 880.0
	s.short_hop_velocity = 540.0
	s.air_jump_velocity = 800.0
	s.air_jumps = 2
	s.height = 84.0
	s.crouch_height = 56.0
	s.half_width = 18.0
	return s


func build_moves() -> Dictionary:
	return ValkyrieMoves.build(self)


func build_animations() -> AnimationLibrary:
	return ValkyrieAnims.build()


## Up and neutral both give the hover (her recovery).
func get_special(dir: Vector2i, _grounded: bool) -> String:
	if dir.y > 0:
		return "dspecial"
	if dir.x != 0:
		return "sspecial"
	return "nspecial"


# --- Wings of Valhalla --------------------------------------------------------------

func hover_tick(_self: Fighter, t: int) -> void:
	if t < HOVER_LIFT_FRAME:
		vel = Vector2(vel.x * 0.85, minf(vel.y, 0.0) * 0.5)  # brief stall
	elif t == HOVER_LIFT_FRAME:
		vel.y = -HOVER_LIFT_SPEED
		Sfx.play("jump", 0.05, -2.0)
	elif t <= HOVER_RISE_END:
		vel.y += stats.gravity * DT
	elif input.held("special"):
		vel.y = move_toward(vel.y, HOVER_FALL_SPEED, 3000.0 * DT)
	else:
		end_move()  # let go of special → stop hovering, fall helpless


# --- Shield Charge --------------------------------------------------------------------

func shield_charge_tick(_self: Fighter, t: int) -> void:
	if t < CHARGE_DASH_FROM:
		vel = Vector2(vel.x * 0.8, minf(vel.y, 0.0) * 0.4)
	elif t <= CHARGE_DASH_TO:
		vel = Vector2(facing * CHARGE_SPEED, 0.0)
	else:
		vel.x = move_toward(vel.x, 0.0, 2400.0 * DT)
		if not is_on_floor():
			vel.y = minf(vel.y + stats.gravity * DT, stats.max_fall_speed)


func shield_charge_hit(_self: Fighter, _target: Fighter) -> void:
	vel.x = -facing * 120.0
	move_frame = CHARGE_DASH_TO + 1  # skip the rest of the dash, straight into endlag


# --- Spear Dive -----------------------------------------------------------------------

func spear_dive_tick(_self: Fighter, t: int) -> void:
	if t == 1:
		_dive_from_ground = is_on_floor()
	if t < DIVE_START:
		# From the ground she leaps first; in the air she hangs for a moment.
		vel = Vector2(vel.x * 0.5, -650.0 if _dive_from_ground else -160.0)
	else:
		vel = Vector2(DIVE_DIR.x * facing, DIVE_DIR.y) * DIVE_SPEED


func spear_dive_hit(_self: Fighter, _target: Fighter) -> void:
	# Bounce off the victim and get control back (dive stays used until landing).
	vel = Vector2(-facing * 240.0, -760.0)
	sm.change(&"air")

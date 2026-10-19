class_name Knockback
extends RefCounted
## All launch math in one place.
##
## "KB" below is an abstract knockback value in the same units as Smash Bros' formula,
## so frame-data intuitions carry over. LAUNCH_SPEED turns KB into pixels/second.
## Tuned so an uncharged Valkyrie forward smash KOs a
## middleweight at ~100-110% near stage center and ~85% near the ledge
## (tests/sim_test.gd measures it in-engine).

## px/s of initial launch speed per KB unit.
const LAUNCH_SPEED := 8.4
## Launch speed lost per second, along the launch direction (px/s²). Gravity is applied
## separately to the victim's own velocity, so arcs curve down naturally.
const LAUNCH_DECAY := 1100.0
## Launch speed bleeds off faster while sliding on the ground.
const GROUND_DECAY_MULT := 2.5
## Hitstun frames per KB unit (Smash uses 0.4).
const HITSTUN_PER_KB := 0.4
## KB at or above this sends the victim into tumble (can tech, can be knocked down).
const TUMBLE_THRESHOLD := 80.0
## Max angle DI can rotate a launch, in radians (18°).
const MAX_DI := 0.3141593

## Percent past this point counts for extra: the "spike" where kills suddenly come online.
const RAMP_START := 100.0
const RAMP_STRENGTH := 0.003

## Combo decay: hitstun multiplier for the Nth consecutive hit of one combo.
## Hits 1-2 are full strength, then hitstun shrinks so loops always drop by hit 4-5.
const COMBO_HITSTUN := [1.0, 1.0, 1.0, 0.8, 0.6, 0.45]


## Percent actually used by the formula. Linear up to RAMP_START, then grows
## quadratically: 120% acts like ~127%, 150% like ~172%, 200% like ~260%.
static func effective_percent(percent: float) -> float:
	if percent <= RAMP_START:
		return percent
	return percent * (1.0 + RAMP_STRENGTH * (percent - RAMP_START))


## Smash-style knockback:
##   KB = ((p/10 + p·d/20) · 200/(w+100) · 1.4 + 18) · (growth/100) + base
## p = victim percent *after* the hit, d = damage, w = weight.
## The p·d term makes strong hits scale much faster with percent than weak ones, and
## since travel distance ∝ launch speed², kill power rises sharply at high percent.
static func compute(percent_after: float, damage: float, weight: float,
		base_kb: float, growth: float) -> float:
	var p := effective_percent(percent_after)
	var weight_factor := 200.0 / (weight + 100.0)
	return ((p / 10.0 + p * damage / 20.0) * weight_factor * 1.4 + 18.0) * (growth / 100.0) + base_kb


## Fixed ("set") knockback: same launch at any percent, still weight-dependent.
## Used for multi-hit links so they always connect.
static func fixed(set_kb: float, weight: float, base_kb: float, growth: float) -> float:
	var weight_factor := 200.0 / (weight + 100.0)
	return ((set_kb * 10.0 / 20.0 + 1.0) * weight_factor * 1.4 + 18.0) * (growth / 100.0) + base_kb


## Angle 361 is the "Sakurai angle": grounded victims slide flat at low KB and pop up
## to 40° at high KB, so weak hits don't send grounded players flying; airborne → 40°.
static func resolve_angle(angle_deg: float, kb: float, grounded: bool) -> float:
	if angle_deg != 361.0:
		return angle_deg
	if not grounded:
		return 40.0
	if kb < 60.0:
		return 0.0
	if kb >= 88.0:
		return 40.0
	return (kb - 60.0) / 28.0 * 40.0


static func hitstun_frames(kb: float, combo_count: int) -> int:
	var idx := clampi(combo_count - 1, 0, COMBO_HITSTUN.size() - 1)
	return int(kb * HITSTUN_PER_KB * COMBO_HITSTUN[idx])


## Freeze frames for both fighters on contact. Bigger hits freeze longer = more impact.
static func hitlag_frames(damage: float, mult: float) -> int:
	return clampi(int(floor((damage * 0.45 + 4.0) * mult)), 2, 20)


## Directional Influence: the victim's stick, read at the end of hitlag, rotates the
## launch by up to MAX_DI. Only the component perpendicular to the launch counts —
## holding along the launch line does nothing, holding at 90° gives the full 18°.
## (In Godot's y-down space, a positive cross product means "clockwise".)
static func apply_di(launch_dir: Vector2, stick: Vector2) -> Vector2:
	if stick.length() < 0.25:
		return launch_dir
	var perpendicular := launch_dir.cross(stick.normalized())  # -1..1
	return launch_dir.rotated(MAX_DI * perpendicular * minf(stick.length(), 1.0))

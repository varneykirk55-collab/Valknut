class_name ValkyrieAnims
extends RefCounted
## Valkyrie's animations. Visuals come from her 128×128 frames
## (frames/valkyrie_*.png, packed in valkyrie_frames.tres); timing is keyed in frames so
## every animation lines up with valkyrie_moves.gd (attack length = move total_frames).
##
## Attacks use the sheet's startup → active → recovery frames, with the active frame
## landing on the move's first hitbox frame. Motion is layered on top: Body rotation
## (spins, aiming the thrust down for down-attacks), Body position (lunges, bobs),
## Rig scale (squash, facing flips), Rig tint (ghosting) and SlashFX effects.

const FRAME := "Rig/Body/Sprite:frame"
const BODY_POS := "Rig/Body:position"
const BODY_ROT := "Rig/Body:rotation"
const RIG_SCALE := "Rig:scale"
const RIG_TINT := "Rig:modulate"

# Frame indices in the "frames" strip of valkyrie_frames.tres.
const IDLE := 0
const WALK_1 := 1
const WALK_2 := 2
const WALK_3 := 3
const WALK_4 := 4
const JUMP := 5
const FALL := 6
const HURT := 7
const STARTUP := 8
const ACTIVE := 9      ## deep thrust, motion lines drawn in
const RECOVERY := 10

const BODY := Vector2(0, -42)
const GHOST := Color(1, 1, 1, 0.45)
const FLASH := Color(1.7, 1.7, 1.7)
const SPENT := Color(0.65, 0.65, 0.8)
const SPIN := TAU
## Effect colour for her swings and dives.
const GOLD := Color(1.0, 0.84, 0.42)

const DEFAULT_POSE := {
	FRAME: IDLE, BODY_POS: BODY, BODY_ROT: 0.0, RIG_SCALE: Vector2.ONE, RIG_TINT: Color.WHITE,
}


## Startup → active → recovery → `end` frame (idle on the ground, fall in the air).
static func strike(startup: int, active: int, recovery: int, back: int, end := IDLE, first := STARTUP) -> Array:
	var keys := [[startup, STARTUP], [active, ACTIVE], [recovery, RECOVERY], [back, end]]
	if startup > 0:
		keys.push_front([0, first])
	return keys


static func build() -> AnimationLibrary:
	var b := AnimBuilder.new(SlashFX.with(DEFAULT_POSE, SlashFX.default_tracks()))

	# --- Movement -------------------------------------------------------------------
	b.add("idle", 60, true, {
		BODY_POS: [[0, BODY], [30, BODY + Vector2(0, 1.5)], [60, BODY]],
		RIG_SCALE: [[0, Vector2.ONE], [30, Vector2(1.01, 0.985)], [60, Vector2.ONE]],
	})
	b.add("walk", 32, true, {
		FRAME: [[0, WALK_1], [8, WALK_2], [16, WALK_3], [24, WALK_4]],
		BODY_POS: [[0, BODY], [8, BODY + Vector2(0, -1.5)], [16, BODY], [24, BODY + Vector2(0, -1.5)], [32, BODY]],
	})
	b.add("dash", 10, false, {FRAME: WALK_2, BODY_ROT: 0.08})
	b.add("run", 24, true, {
		FRAME: [[0, WALK_1], [6, WALK_2], [12, WALK_3], [18, WALK_4]],
		BODY_ROT: 0.06,
		BODY_POS: [[0, BODY], [6, BODY + Vector2(0, -3)], [12, BODY], [18, BODY + Vector2(0, -3)], [24, BODY]],
	})
	b.add("crouch", 1, false, {FRAME: STARTUP, RIG_SCALE: Vector2(1.04, 0.86)})
	b.add("jump_squat", 4, false, {FRAME: STARTUP, RIG_SCALE: [[0, Vector2(1.04, 0.92)], [4, Vector2(1.1, 0.82)]]})
	b.add("jump", 20, false, {FRAME: JUMP, RIG_SCALE: [[0, Vector2(0.9, 1.12)], [8, Vector2.ONE]]})
	b.add("air_jump", 22, false, {
		FRAME: JUMP,
		BODY_ROT: [[0, 0.0], [18, SPIN]],  # forward flip
		RIG_SCALE: [[0, Vector2(0.9, 1.1)], [10, Vector2.ONE]],
	})
	b.add("fall", 1, false, {FRAME: FALL})
	b.add("land", 6, false, {FRAME: [[0, STARTUP], [4, IDLE]], RIG_SCALE: [[0, Vector2(1.15, 0.82)], [6, Vector2.ONE]]})

	# --- Jab string ---------------------------------------------------------------------
	b.add("jab1", 18, false, {
		FRAME: strike(0, 3, 8, 14),
		BODY_POS: [[0, BODY + Vector2(-2, 0)], [3, BODY + Vector2(4, 0)], [10, BODY]],
	})
	b.add("jab2", 20, false, SlashFX.with({  # shield bash: step in shield-first
		FRAME: [[0, STARTUP], [4, WALK_2], [10, RECOVERY], [16, IDLE]],
		BODY_POS: [[0, BODY + Vector2(-2, 0)], [4, BODY + Vector2(10, 0)], [12, BODY + Vector2(10, 0)], [20, BODY]],
		RIG_SCALE: [[0, Vector2.ONE], [4, Vector2(1.08, 0.94)], [12, Vector2.ONE]],
	}, SlashFX.arc(Vector2(14, -46), 28, -70, 70, 10, GOLD, 4, 2, 3)))
	b.add("jab3", 34, false, {
		FRAME: strike(0, 7, 18, 28),
		BODY_POS: [[0, BODY + Vector2(-6, 2)], [6, BODY + Vector2(-8, 2)], [7, BODY + Vector2(6, 0)],
			[22, BODY + Vector2(6, 0)], [34, BODY]],
	})

	# --- Tilts / smashes -------------------------------------------------------------
	b.add("ftilt", 30, false, {
		FRAME: strike(3, 8, 16, 25),
		BODY_POS: [[0, BODY], [6, BODY + Vector2(-6, 1)], [8, BODY + Vector2(5, 0)], [20, BODY + Vector2(5, 0)], [30, BODY]],
	})
	b.add("dtilt", 20, false, {  # the thrust aimed low
		FRAME: strike(0, 6, 12, 17),
		BODY_ROT: [[0, 0.0], [6, 0.28], [12, 0.28], [17, 0.0]],
		RIG_SCALE: [[0, Vector2(1.04, 0.9)], [6, Vector2(1.04, 0.84)], [14, Vector2.ONE]],
	})
	b.add("fsmash", 52, false, {
		# Crouched wind-up (held while charging), then the full lunge.
		FRAME: strike(4, 13, 30, 44, IDLE, IDLE),
		BODY_ROT: [[0, 0.0], [9, -0.08], [13, 0.0]],
		BODY_POS: [[0, BODY], [9, BODY + Vector2(-10, 3)], [13, BODY + Vector2(8, 0)], [30, BODY + Vector2(8, 0)], [52, BODY]],
		RIG_SCALE: [[0, Vector2.ONE], [9, Vector2(1.04, 0.92)], [13, Vector2.ONE]],
	})
	b.add("dsmash", 48, false, SlashFX.with({
		FRAME: [[0, STARTUP], [10, ACTIVE], [30, RECOVERY], [40, IDLE]],
		BODY_ROT: [[0, 0.0], [10, 0.32], [30, 0.32], [40, 0.0]],
		# Second hitbox is behind her: flip the drawing to sell the backward sweep.
		RIG_SCALE: [[0, Vector2.ONE], [16, Vector2.ONE], [17, Vector2(-1, 1)], [30, Vector2(-1, 1)], [31, Vector2.ONE]],
	}, SlashFX.ring(Vector2(0, -14), 62, 12, GOLD, 10, 22, 1.0, 0.3)))

	# --- Aerials -------------------------------------------------------------------------
	b.add("nair", 38, false, SlashFX.with({
		FRAME: [[0, FALL], [4, RECOVERY], [24, FALL]],
		BODY_ROT: [[0, 0.0], [4, 0.0], [20, SPIN], [38, SPIN]],
	}, SlashFX.ring(Vector2(0, -42), 50, 14, GOLD, 5, 20, 1.5)))
	b.add("fair", 36, false, SlashFX.with({
		# Overhead-to-forward sweep with a gold arc.
		FRAME: strike(3, 7, 18, 28, FALL, FALL),
		BODY_ROT: [[0, 0.0], [5, -0.5], [10, 0.25], [18, 0.25], [36, 0.0]],
	}, SlashFX.arc(Vector2(8, -46), 64, -95, 45, 18, GOLD, 6, 5, 6)))
	b.add("dair", 44, false, SlashFX.with({  # the thrust aimed straight down
		FRAME: strike(6, 12, 26, 34, FALL, FALL),
		BODY_ROT: [[0, 0.0], [10, -0.2], [12, 1.35], [26, 1.35], [34, 0.0]],
		BODY_POS: [[0, BODY], [10, BODY + Vector2(0, -8)], [13, BODY + Vector2(0, 4)], [28, BODY]],
	}, SlashFX.streak(Vector2(14, 30), 60, 90, 10, GOLD, 12, 3, 6)))

	# --- Specials ------------------------------------------------------------------------
	b.add("nspecial", 80, false, SlashFX.with({
		FRAME: [[0, STARTUP], [7, JUMP]],
		RIG_SCALE: [[0, Vector2(1.08, 0.88)], [6, Vector2(1.08, 0.88)], [8, Vector2(0.88, 1.15)], [16, Vector2.ONE]],
	}, SlashFX.streak(Vector2(0, 0), 70, -90, 16, Color(1, 1, 1), 7, 6, 10)))
	b.add("sspecial", 44, false, SlashFX.with({
		FRAME: [[0, STARTUP], [9, FALL], [28, RECOVERY], [38, IDLE]],
		BODY_ROT: [[0, 0.0], [7, -0.1], [9, 0.3], [26, 0.3], [40, 0.0]],
		BODY_POS: [[0, BODY], [7, BODY + Vector2(-6, 2)], [9, BODY], [44, BODY]],
	}, SlashFX.streak(Vector2(22, -46), 90, 0, 22, GOLD, 9, 4, 12)))
	b.add("dspecial", 40, false, SlashFX.with({
		FRAME: [[0, JUMP], [8, STARTUP], [11, ACTIVE]],
		BODY_ROT: [[0, 0.0], [8, -0.3], [10, -0.3], [12, 1.0], [40, 1.0]],
	}, SlashFX.streak(Vector2(14, -40), 120, 60, 18, GOLD, 11, 4, 25)))

	# --- Defense -------------------------------------------------------------------------
	b.add("spot_dodge", 24, false, {
		FRAME: STARTUP,
		RIG_TINT: [[0, Color.WHITE], [3, GHOST], [16, GHOST], [17, Color.WHITE]],
		RIG_SCALE: [[0, Vector2.ONE], [4, Vector2(1.04, 0.9)], [16, Vector2(1.04, 0.9)], [24, Vector2.ONE]],
	})
	b.add("roll", 34, false, {
		FRAME: JUMP,
		RIG_TINT: [[0, Color.WHITE], [3, GHOST], [18, GHOST], [19, Color.WHITE]],
		BODY_ROT: [[0, 0.0], [3, 0.0], [21, SPIN], [34, SPIN]],
		BODY_POS: [[0, BODY], [3, Vector2(0, -30)], [21, Vector2(0, -30)], [26, BODY]],
		RIG_SCALE: [[0, Vector2.ONE], [3, Vector2(0.85, 0.85)], [21, Vector2(0.85, 0.85)], [26, Vector2.ONE]],
	})
	b.add("air_dodge", 34, false, {
		FRAME: FALL,
		RIG_TINT: [[0, Color.WHITE], [3, GHOST], [24, GHOST], [26, Color.WHITE]],
	})

	# --- Getting hit ---------------------------------------------------------------------
	b.add("hurt", 20, false, {FRAME: HURT})
	b.add("tumble", 24, true, {FRAME: HURT, BODY_ROT: [[0, 0.0], [24, -SPIN]]})
	b.add("tech", 20, false, {
		FRAME: STARTUP,
		RIG_TINT: [[0, FLASH], [6, GHOST], [18, GHOST], [19, Color.WHITE]],
		RIG_SCALE: [[0, Vector2(1.15, 0.8)], [8, Vector2.ONE]],
	})
	b.add("knockdown", 20, false, {FRAME: HURT, BODY_ROT: -1.4, BODY_POS: [[0, Vector2(0, -26)], [4, Vector2(0, -18)]]})
	b.add("getup", 30, false, {
		FRAME: [[0, HURT], [12, STARTUP], [22, IDLE]],
		RIG_TINT: [[0, GHOST], [22, GHOST], [23, Color.WHITE]],
		BODY_ROT: [[0, -1.4], [12, 0.0]],
		BODY_POS: [[0, Vector2(0, -18)], [12, BODY]],
	})
	b.add("getup_attack", 34, false, SlashFX.with({
		FRAME: [[0, HURT], [12, STARTUP], [16, ACTIVE], [24, RECOVERY], [30, IDLE]],
		RIG_TINT: [[0, GHOST], [15, GHOST], [16, Color.WHITE]],
		BODY_ROT: [[0, -1.4], [12, -1.4], [14, 0.0]],
		BODY_POS: [[0, Vector2(0, -18)], [14, BODY]],
	}, SlashFX.ring(Vector2(0, -18), 52, 12, GOLD, 16, 21, 0.75, 0.3)))

	# --- Ledge / recovery ----------------------------------------------------------------
	b.add("ledge_hang", 1, false, {FRAME: JUMP, BODY_ROT: -0.35, BODY_POS: BODY + Vector2(0, 6)})
	b.add("ledge_climb", 28, false, {
		FRAME: [[0, JUMP], [10, STARTUP], [20, IDLE]],
		RIG_TINT: [[0, GHOST], [24, GHOST], [25, Color.WHITE]],
	})
	b.add("ledge_attack", 30, false, {
		FRAME: strike(0, 10, 18, 26),
		RIG_TINT: [[0, GHOST], [9, GHOST], [10, Color.WHITE]],
	})
	b.add("helpless", 30, true, {
		FRAME: FALL,
		RIG_TINT: SPENT,
		BODY_ROT: [[0, -0.1], [15, 0.1], [30, -0.1]],
	})
	return b.library

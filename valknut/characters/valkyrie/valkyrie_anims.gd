class_name ValkyrieAnims
extends RefCounted
## Valkyrie's animations, built from her sprite sheet (valkyrie_sheet.png) and keyed in
## frames so they line up with valkyrie_moves.gd (an attack animation's length = the
## move's total_frames).
##
## Each animation picks sheet frames (discrete) and adds motion on top: Body rotation
## (spins, leans), Body position (bobs, lunges), Rig scale (squash/stretch, facing flips),
## Rig tint (intangibility ghosting) and a SlashFX effect (gold arcs, speed lines, rings).
## Attack choreography (wind-up → strike → hold → recover) follows the motion references. Moves without a dedicated drawing reuse the
## closest frame, e.g. down air is the low thrust rotated to point down.

const FRAME := "Rig/Body/Sprite:frame"
const BODY_POS := "Rig/Body:position"
const BODY_ROT := "Rig/Body:rotation"
const RIG_SCALE := "Rig:scale"
const RIG_TINT := "Rig:modulate"

# Sheet frames (art/source/valkyrie_sheet_source.jpg, left to right, top to bottom).
const IDLE := 0
const WALK_A := 1
const WALK_B := 2
const RUN := 3
const WALK_C := 4
const JUMP := 5       ## wings out, knees tucked
const AIR := 6        ## leaning forward, shield first
const HURT := 7
const THRUST := 8     ## level spear thrust
const LUNGE := 9      ## deep lunging thrust
const LOW := 10       ## low thrust
const RAISED := 11    ## wings spread, spear raised

const BODY := Vector2(0, -42)
const GHOST := Color(1, 1, 1, 0.45)
const FLASH := Color(1.7, 1.7, 1.7)
const SPENT := Color(0.65, 0.65, 0.8)
const SPIN := TAU
## Effect colour for her swings (gold, like the reference's arc).
const GOLD := Color(1.0, 0.84, 0.42)

const DEFAULT_POSE := {
	FRAME: IDLE, BODY_POS: BODY, BODY_ROT: 0.0, RIG_SCALE: Vector2.ONE, RIG_TINT: Color.WHITE,
}


static func build() -> AnimationLibrary:
	var b := AnimBuilder.new(SlashFX.with(DEFAULT_POSE, SlashFX.default_tracks()))

	# --- Movement -------------------------------------------------------------------
	b.add("idle", 60, true, {
		BODY_POS: [[0, BODY], [30, BODY + Vector2(0, 1.5)], [60, BODY]],
		RIG_SCALE: [[0, Vector2.ONE], [30, Vector2(1.01, 0.985)], [60, Vector2.ONE]],
	})
	b.add("walk", 32, true, {
		FRAME: [[0, WALK_A], [8, WALK_B], [16, WALK_C], [24, WALK_B]],
		BODY_POS: [[0, BODY], [8, BODY + Vector2(0, -2)], [16, BODY], [24, BODY + Vector2(0, -2)], [32, BODY]],
	})
	b.add("dash", 10, false, {FRAME: RUN, BODY_ROT: 0.08})
	b.add("run", 24, true, {
		FRAME: [[0, RUN], [12, WALK_C]],
		BODY_ROT: 0.06,
		BODY_POS: [[0, BODY], [6, BODY + Vector2(0, -3)], [12, BODY], [18, BODY + Vector2(0, -3)], [24, BODY]],
	})
	b.add("crouch", 1, false, {RIG_SCALE: Vector2(1.08, 0.72)})
	b.add("jump_squat", 4, false, {RIG_SCALE: [[0, Vector2(1.04, 0.9)], [4, Vector2(1.12, 0.8)]]})
	b.add("jump", 20, false, {FRAME: JUMP, RIG_SCALE: [[0, Vector2(0.9, 1.12)], [8, Vector2.ONE]]})
	b.add("air_jump", 22, false, {
		FRAME: JUMP,
		BODY_ROT: [[0, 0.0], [18, SPIN]],  # forward flip
		RIG_SCALE: [[0, Vector2(0.9, 1.1)], [10, Vector2.ONE]],
	})
	b.add("fall", 1, false, {FRAME: AIR})
	b.add("land", 6, false, {RIG_SCALE: [[0, Vector2(1.18, 0.8)], [6, Vector2.ONE]]})

	# --- Jab string ---------------------------------------------------------------------
	# Thrusts follow the reference: a short pull-back, a snap forward with speed lines,
	# then a held extension before recovering.
	b.add("jab1", 18, false, SlashFX.with({
		FRAME: [[0, IDLE], [2, THRUST], [10, IDLE]],
		BODY_POS: [[0, BODY], [1, BODY + Vector2(-3, 0)], [3, BODY + Vector2(4, 0)], [10, BODY]],
	}, SlashFX.streak(Vector2(72, -54), 46, 0, 7, GOLD, 3, 2, 4)))
	b.add("jab2", 20, false, SlashFX.with({  # shield bash: step in shield-first
		FRAME: [[0, WALK_A], [14, IDLE]],
		BODY_POS: [[0, BODY + Vector2(-2, 0)], [4, BODY + Vector2(10, 0)], [12, BODY + Vector2(10, 0)], [20, BODY]],
		RIG_SCALE: [[0, Vector2.ONE], [4, Vector2(1.08, 0.94)], [12, Vector2.ONE]],
	}, SlashFX.arc(Vector2(14, -46), 28, -70, 70, 10, GOLD, 4, 2, 3)))
	b.add("jab3", 34, false, SlashFX.with({
		FRAME: [[0, LOW], [7, LUNGE], [24, IDLE]],
		BODY_POS: [[0, BODY + Vector2(-6, 4)], [6, BODY + Vector2(-9, 4)], [7, BODY + Vector2(6, 0)],
			[22, BODY + Vector2(6, 0)], [34, BODY]],
	}, SlashFX.streak(Vector2(84, -52), 80, 0, 12, GOLD, 7, 3, 6)))

	# --- Tilts / smashes -------------------------------------------------------------
	b.add("ftilt", 30, false, SlashFX.with({
		FRAME: [[0, IDLE], [4, LOW], [8, THRUST], [20, IDLE]],
		BODY_POS: [[0, BODY], [6, BODY + Vector2(-7, 2)], [8, BODY + Vector2(6, 0)], [20, BODY + Vector2(6, 0)], [30, BODY]],
	}, SlashFX.streak(Vector2(84, -54), 70, 0, 9, GOLD, 8, 3, 5)))
	b.add("dtilt", 20, false, SlashFX.with({
		FRAME: [[0, IDLE], [3, LOW], [14, IDLE]],
		BODY_POS: [[0, BODY], [6, BODY + Vector2(8, 2)], [14, BODY + Vector2(8, 2)], [20, BODY]],
	}, SlashFX.streak(Vector2(84, -10), 50, 12, 6, GOLD, 6, 3, 4)))
	b.add("fsmash", 52, false, SlashFX.with({
		# Crouched wind-up (held while charging), then an explosive lunge.
		FRAME: [[0, IDLE], [5, LOW], [13, LUNGE], [32, IDLE]],
		BODY_ROT: [[0, 0.0], [9, -0.1], [13, 0.03], [32, 0.0]],
		BODY_POS: [[0, BODY], [9, BODY + Vector2(-11, 3)], [13, BODY + Vector2(9, 0)], [32, BODY + Vector2(9, 0)], [52, BODY]],
		RIG_SCALE: [[0, Vector2.ONE], [9, Vector2(1.04, 0.94)], [13, Vector2(1.04, 0.98)], [20, Vector2.ONE]],
	}, SlashFX.streak(Vector2(94, -52), 110, 0, 14, GOLD, 13, 3, 9)))
	b.add("dsmash", 48, false, SlashFX.with({
		FRAME: [[0, IDLE], [6, LOW], [34, IDLE]],
		# Second hitbox is behind her: flip the drawing to sell the backward sweep.
		RIG_SCALE: [[0, Vector2.ONE], [16, Vector2.ONE], [17, Vector2(-1, 1)], [30, Vector2(-1, 1)], [31, Vector2.ONE]],
	}, SlashFX.ring(Vector2(0, -14), 62, 12, GOLD, 10, 22, 1.0, 0.3)))

	# --- Aerials -------------------------------------------------------------------------
	b.add("nair", 38, false, SlashFX.with({
		FRAME: AIR, BODY_ROT: [[0, 0.0], [4, 0.0], [20, SPIN], [38, SPIN]],
	}, SlashFX.ring(Vector2(0, -42), 50, 14, GOLD, 5, 20, 1.5)))
	b.add("fair", 36, false, SlashFX.with({
		# Reference: a big overhead-to-forward sweep with a golden arc.
		FRAME: [[0, AIR], [5, THRUST], [18, AIR]],
		BODY_ROT: [[0, 0.0], [5, -0.55], [11, 0.3], [18, 0.3], [36, 0.0]],
	}, SlashFX.arc(Vector2(8, -46), 64, -95, 45, 18, GOLD, 6, 5, 6)))
	b.add("dair", 44, false, SlashFX.with({
		FRAME: [[0, AIR], [11, LOW], [28, AIR]],
		BODY_ROT: [[0, 0.0], [10, -0.25], [12, 0.85], [24, 0.85], [32, 0.0]],
		BODY_POS: [[0, BODY], [10, BODY + Vector2(0, -8)], [13, BODY + Vector2(0, 4)], [28, BODY]],
	}, SlashFX.streak(Vector2(14, 30), 60, 90, 10, GOLD, 12, 3, 6)))

	# --- Specials ------------------------------------------------------------------------
	b.add("nspecial", 80, false, SlashFX.with({
		FRAME: RAISED,
		RIG_SCALE: [[0, Vector2(1.08, 0.88)], [6, Vector2(1.08, 0.88)], [8, Vector2(0.88, 1.15)], [16, Vector2.ONE]],
	}, SlashFX.streak(Vector2(0, 0), 70, -90, 16, Color(1, 1, 1), 7, 6, 10)))
	b.add("sspecial", 44, false, SlashFX.with({
		FRAME: [[0, IDLE], [8, AIR], [30, IDLE]],
		BODY_ROT: [[0, 0.0], [7, -0.1], [9, 0.25], [26, 0.25], [40, 0.0]],
		BODY_POS: [[0, BODY], [7, BODY + Vector2(-6, 2)], [9, BODY], [44, BODY]],
	}, SlashFX.streak(Vector2(22, -46), 90, 0, 22, GOLD, 9, 4, 12)))
	b.add("dspecial", 40, false, SlashFX.with({
		FRAME: [[0, JUMP], [11, LUNGE]],
		BODY_ROT: [[0, 0.0], [8, -0.3], [10, -0.3], [12, 1.0], [40, 1.0]],
	}, SlashFX.streak(Vector2(14, -40), 120, 60, 18, GOLD, 11, 4, 25)))

	# --- Defense -------------------------------------------------------------------------
	b.add("spot_dodge", 24, false, {
		RIG_TINT: [[0, Color.WHITE], [3, GHOST], [16, GHOST], [17, Color.WHITE]],
		RIG_SCALE: [[0, Vector2.ONE], [4, Vector2(1.06, 0.88)], [16, Vector2(1.06, 0.88)], [24, Vector2.ONE]],
	})
	b.add("roll", 34, false, {
		FRAME: AIR,
		RIG_TINT: [[0, Color.WHITE], [3, GHOST], [18, GHOST], [19, Color.WHITE]],
		BODY_ROT: [[0, 0.0], [3, 0.0], [21, SPIN], [34, SPIN]],
		BODY_POS: [[0, BODY], [3, Vector2(0, -30)], [21, Vector2(0, -30)], [26, BODY]],
		RIG_SCALE: [[0, Vector2.ONE], [3, Vector2(0.85, 0.85)], [21, Vector2(0.85, 0.85)], [26, Vector2.ONE]],
	})
	b.add("air_dodge", 34, false, {
		FRAME: JUMP,
		RIG_TINT: [[0, Color.WHITE], [3, GHOST], [24, GHOST], [26, Color.WHITE]],
	})

	# --- Getting hit ---------------------------------------------------------------------
	b.add("hurt", 20, false, {FRAME: HURT})
	b.add("tumble", 24, true, {FRAME: HURT, BODY_ROT: [[0, 0.0], [24, -SPIN]]})
	b.add("tech", 20, false, {
		RIG_TINT: [[0, FLASH], [6, GHOST], [18, GHOST], [19, Color.WHITE]],
		RIG_SCALE: [[0, Vector2(1.15, 0.8)], [8, Vector2.ONE]],
	})
	b.add("knockdown", 20, false, {FRAME: HURT, BODY_ROT: -1.4, BODY_POS: [[0, Vector2(0, -26)], [4, Vector2(0, -18)]]})
	b.add("getup", 30, false, {
		FRAME: [[0, HURT], [12, IDLE]],
		RIG_TINT: [[0, GHOST], [22, GHOST], [23, Color.WHITE]],
		BODY_ROT: [[0, -1.4], [12, 0.0]],
		BODY_POS: [[0, Vector2(0, -18)], [12, BODY]],
	})
	b.add("getup_attack", 34, false, SlashFX.with({
		FRAME: [[0, HURT], [14, LOW], [26, IDLE]],
		RIG_TINT: [[0, GHOST], [15, GHOST], [16, Color.WHITE]],
		BODY_ROT: [[0, -1.4], [12, -1.4], [14, 0.0]],
		BODY_POS: [[0, Vector2(0, -18)], [14, BODY]],
	}, SlashFX.ring(Vector2(0, -18), 52, 12, GOLD, 16, 21, 0.75, 0.3)))

	# --- Ledge / recovery ----------------------------------------------------------------
	b.add("ledge_hang", 1, false, {FRAME: RAISED, BODY_POS: BODY + Vector2(0, 6)})
	b.add("ledge_climb", 28, false, {
		FRAME: [[0, RAISED], [10, WALK_A], [20, IDLE]],
		RIG_TINT: [[0, GHOST], [24, GHOST], [25, Color.WHITE]],
	})
	b.add("ledge_attack", 30, false, SlashFX.with({
		FRAME: [[0, IDLE], [6, LOW], [9, THRUST], [20, IDLE]],
		RIG_TINT: [[0, GHOST], [9, GHOST], [10, Color.WHITE]],
	}, SlashFX.streak(Vector2(82, -54), 64, 0, 9, GOLD, 10, 3, 5)))
	b.add("helpless", 30, true, {
		FRAME: AIR,
		RIG_TINT: SPENT,
		BODY_ROT: [[0, -0.1], [15, 0.1], [30, -0.1]],
	})
	return b.library

class_name BerserkerAnims
extends RefCounted
## Berserker's animations. Visuals come from his 128×128 frames
## (frames/berserker_*.png, packed in berserker_frames.tres); timing is keyed in frames
## to match berserker_moves.gd. Attacks use the sheet's startup → active → recovery
## frames with the active frame on the move's first hitbox frame; motion (hops, lunges,
## spins, squash) and SlashFX effects are layered on top.

const FRAME := "Rig/Body/Sprite:frame"
const BODY_POS := "Rig/Body:position"
const BODY_ROT := "Rig/Body:rotation"
const RIG_SCALE := "Rig:scale"
const RIG_TINT := "Rig:modulate"

# Frame indices in the "frames" strip of berserker_frames.tres.
const IDLE := 0
const WALK_1 := 1
const WALK_2 := 2
const WALK_3 := 3
const WALK_4 := 4
const JUMP := 5
const FALL := 6        ## the sheet has one jump/fall drawing; both names point to it
const HURT := 7
const STARTUP := 8
const ACTIVE := 9      ## wide axe swing, slash arc and motion lines drawn in
const RECOVERY := 10

const BODY := Vector2(0, -46)
const GHOST := Color(1, 1, 1, 0.45)
const FLASH := Color(1.7, 1.7, 1.7)
const SPENT := Color(0.7, 0.7, 0.85)
const RAGE := Color(1.45, 0.75, 0.7)
const SPIN := TAU
## Effect colour for his swings.
const RED := Color(0.86, 0.12, 0.1)

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

	# --- Movement: heavy, stompy ---------------------------------------------------------
	b.add("idle", 60, true, {
		BODY_POS: [[0, BODY], [30, BODY + Vector2(0, 2)], [60, BODY]],
		RIG_SCALE: [[0, Vector2.ONE], [30, Vector2(1.015, 0.98)], [60, Vector2.ONE]],
	})
	b.add("walk", 40, true, {
		FRAME: [[0, WALK_1], [10, WALK_2], [20, WALK_3], [30, WALK_4]],
		BODY_POS: [[0, BODY], [10, BODY + Vector2(0, 2)], [20, BODY], [30, BODY + Vector2(0, 2)], [40, BODY]],
	})
	b.add("dash", 12, false, {FRAME: WALK_2, BODY_ROT: 0.1})
	b.add("run", 30, true, {
		FRAME: [[0, WALK_1], [7, WALK_2], [15, WALK_3], [22, WALK_4]],
		BODY_ROT: 0.08,
		BODY_POS: [[0, BODY], [7, BODY + Vector2(0, 3)], [15, BODY], [22, BODY + Vector2(0, 3)], [30, BODY]],
	})
	b.add("crouch", 1, false, {FRAME: STARTUP, RIG_SCALE: Vector2(1.06, 0.84)})
	b.add("jump_squat", 5, false, {FRAME: STARTUP, RIG_SCALE: [[0, Vector2(1.06, 0.9)], [5, Vector2(1.14, 0.8)]]})
	b.add("jump", 20, false, {FRAME: JUMP, RIG_SCALE: [[0, Vector2(0.9, 1.1)], [8, Vector2.ONE]]})
	b.add("air_jump", 22, false, {FRAME: JUMP, RIG_SCALE: [[0, Vector2(0.88, 1.12)], [10, Vector2.ONE]]})
	b.add("fall", 1, false, {FRAME: FALL, BODY_ROT: 0.08})
	b.add("land", 8, false, {FRAME: [[0, STARTUP], [6, IDLE]], RIG_SCALE: [[0, Vector2(1.2, 0.78)], [8, Vector2.ONE]]})

	# --- Jab string ------------------------------------------------------------------------
	b.add("jab1", 20, false, {
		FRAME: strike(0, 4, 10, 16),
		BODY_POS: [[0, BODY + Vector2(-3, 1)], [4, BODY + Vector2(5, 0)], [12, BODY]],
	})
	b.add("jab2", 22, false, {  # second swing, stepping in
		FRAME: strike(0, 5, 12, 18),
		BODY_POS: [[0, BODY], [3, BODY + Vector2(-2, 1)], [5, BODY + Vector2(10, 0)], [14, BODY + Vector2(10, 0)], [22, BODY]],
	})
	b.add("jab3", 40, false, {  # hop, then the swing comes down as an overhead chop
		FRAME: [[0, STARTUP], [3, JUMP], [8, ACTIVE], [20, RECOVERY], [32, IDLE]],
		BODY_POS: [[0, BODY], [3, BODY + Vector2(0, -12)], [6, BODY + Vector2(4, -18)], [8, BODY + Vector2(8, 0)],
			[26, BODY + Vector2(8, 0)], [40, BODY]],
		BODY_ROT: [[0, 0.0], [6, -0.2], [8, 0.35], [20, 0.35], [30, 0.0]],
		RIG_SCALE: [[0, Vector2(1.08, 0.9)], [3, Vector2(0.94, 1.08)], [8, Vector2(1.12, 0.88)], [16, Vector2.ONE]],
	})

	# --- Tilts / smashes -----------------------------------------------------------------
	b.add("ftilt", 38, false, {
		FRAME: strike(4, 10, 22, 32, IDLE, IDLE),
		BODY_POS: [[0, BODY], [7, BODY + Vector2(-7, 1)], [10, BODY + Vector2(7, 0)], [24, BODY + Vector2(7, 0)], [38, BODY]],
	})
	b.add("dtilt", 30, false, {  # the swing aimed at the shins
		FRAME: strike(0, 8, 16, 24),
		BODY_ROT: [[0, 0.0], [8, 0.3], [16, 0.3], [24, 0.0]],
		RIG_SCALE: [[0, Vector2(1.06, 0.9)], [8, Vector2(1.06, 0.84)], [18, Vector2.ONE]],
	})
	b.add("fsmash", 64, false, {
		# Deep crouched wind-up (held while charging), then a full-body sweep.
		FRAME: strike(5, 20, 36, 54, IDLE, IDLE),
		BODY_ROT: [[0, 0.0], [12, -0.12], [20, 0.04], [40, 0.0]],
		BODY_POS: [[0, BODY], [12, BODY + Vector2(-12, 4)], [20, BODY + Vector2(12, 0)], [40, BODY + Vector2(12, 0)], [64, BODY]],
		RIG_SCALE: [[0, Vector2.ONE], [12, Vector2(1.08, 0.9)], [20, Vector2.ONE]],
	})
	b.add("dsmash", 58, false, SlashFX.with({  # leap, then slam into the ground
		FRAME: [[0, STARTUP], [8, JUMP], [16, ACTIVE], [32, RECOVERY], [46, IDLE]],
		BODY_POS: [[0, BODY], [8, BODY + Vector2(0, -6)], [12, BODY + Vector2(0, -20)], [16, BODY], [46, BODY]],
		BODY_ROT: [[0, 0.0], [16, 0.4], [32, 0.4], [44, 0.0]],
		RIG_SCALE: [[0, Vector2.ONE], [8, Vector2(1.06, 0.92)], [12, Vector2(0.94, 1.08)], [16, Vector2(1.15, 0.85)],
			[30, Vector2(1.1, 0.9)], [46, Vector2.ONE]],
	}, SlashFX.ring(Vector2(0, -8), 74, 14, RED, 16, 24, 0.5, 0.25)))

	# --- Aerials -------------------------------------------------------------------------------
	b.add("nair", 44, false, SlashFX.with({
		FRAME: [[0, FALL], [6, ACTIVE], [24, FALL]],
		BODY_ROT: [[0, 0.0], [6, 0.0], [22, SPIN], [44, SPIN]],
	}, SlashFX.ring(Vector2(0, -46), 58, 18, RED, 8, 22, 1.5)))
	b.add("fair", 46, false, SlashFX.with({
		# Axes raised behind the head, then a leaping overhead chop.
		FRAME: strike(6, 12, 26, 36, FALL, FALL),
		BODY_ROT: [[0, 0.0], [8, -0.35], [13, 0.45], [26, 0.45], [40, 0.0]],
	}, SlashFX.arc(Vector2(20, -44), 62, -120, 70, 22, RED, 12, 4, 6)))
	b.add("dair", 54, false, SlashFX.with({  # the swing aimed straight down
		FRAME: strike(10, 16, 30, 40, FALL, FALL),
		BODY_ROT: [[0, 0.0], [14, -0.25], [16, 1.1], [30, 1.1], [40, 0.0]],
		RIG_SCALE: [[0, Vector2.ONE], [14, Vector2(1.05, 0.92)], [16, Vector2(0.92, 1.1)], [24, Vector2.ONE]],
	}, SlashFX.streak(Vector2(8, 20), 70, 90, 14, RED, 16, 3, 6)))

	# --- Specials --------------------------------------------------------------------------
	b.add("nspecial", 40, false, SlashFX.with({
		FRAME: [[0, STARTUP], [7, JUMP]],
		RIG_SCALE: [[0, Vector2.ONE], [6, Vector2(1.15, 0.8)], [8, Vector2(0.88, 1.15)], [16, Vector2.ONE]],
	}, SlashFX.streak(Vector2(0, 0), 60, -90, 18, Color(1, 1, 1), 8, 5, 8)))
	b.add("sspecial", 52, false, SlashFX.with({
		FRAME: strike(0, 13, 30, 44),
		BODY_ROT: [[0, 0.0], [12, -0.2], [14, 0.2], [26, 0.2], [44, 0.0]],
		BODY_POS: [[0, BODY], [12, BODY + Vector2(-10, 2)], [14, BODY], [52, BODY]],
	}, SlashFX.streak(Vector2(0, -46), 100, 0, 24, Color(1, 1, 1), 13, 4, 8)))
	b.add("dspecial", 90, false, SlashFX.with(_rage_spin_tracks(),
		SlashFX.ring(Vector2(0, -46), 72, 20, RED, 9, 52, 6.0, 0.55)))

	# --- Defense ---------------------------------------------------------------------------
	b.add("spot_dodge", 24, false, {
		FRAME: STARTUP,
		RIG_TINT: [[0, Color.WHITE], [3, GHOST], [16, GHOST], [17, Color.WHITE]],
		RIG_SCALE: [[0, Vector2.ONE], [4, Vector2(1.06, 0.88)], [16, Vector2(1.06, 0.88)], [24, Vector2.ONE]],
	})
	b.add("roll", 34, false, {
		FRAME: JUMP,
		RIG_TINT: [[0, Color.WHITE], [3, GHOST], [18, GHOST], [19, Color.WHITE]],
		BODY_ROT: [[0, 0.0], [3, 0.0], [21, SPIN], [34, SPIN]],
		BODY_POS: [[0, BODY], [3, Vector2(0, -32)], [21, Vector2(0, -32)], [26, BODY]],
		RIG_SCALE: [[0, Vector2.ONE], [3, Vector2(0.85, 0.85)], [21, Vector2(0.85, 0.85)], [26, Vector2.ONE]],
	})
	b.add("air_dodge", 34, false, {
		FRAME: JUMP,
		RIG_TINT: [[0, Color.WHITE], [3, GHOST], [24, GHOST], [26, Color.WHITE]],
	})

	# --- Getting hit -----------------------------------------------------------------------
	b.add("hurt", 20, false, {FRAME: HURT})
	b.add("tumble", 24, true, {FRAME: HURT, BODY_ROT: [[0, 0.0], [24, -SPIN]]})
	b.add("tech", 20, false, {
		FRAME: STARTUP,
		RIG_TINT: [[0, FLASH], [6, GHOST], [18, GHOST], [19, Color.WHITE]],
		RIG_SCALE: [[0, Vector2(1.15, 0.8)], [8, Vector2.ONE]],
	})
	b.add("knockdown", 20, false, {FRAME: HURT, BODY_ROT: -1.4, BODY_POS: [[0, Vector2(0, -28)], [4, Vector2(0, -20)]]})
	b.add("getup", 30, false, {
		FRAME: [[0, HURT], [12, STARTUP], [22, IDLE]],
		RIG_TINT: [[0, GHOST], [22, GHOST], [23, Color.WHITE]],
		BODY_ROT: [[0, -1.4], [12, 0.0]],
		BODY_POS: [[0, Vector2(0, -20)], [12, BODY]],
	})
	b.add("getup_attack", 34, false, SlashFX.with({
		FRAME: [[0, HURT], [12, STARTUP], [16, ACTIVE], [24, RECOVERY], [30, IDLE]],
		RIG_TINT: [[0, GHOST], [15, GHOST], [16, Color.WHITE]],
		BODY_ROT: [[0, -1.4], [12, -1.4], [14, 0.0]],
		BODY_POS: [[0, Vector2(0, -20)], [14, BODY]],
	}, SlashFX.ring(Vector2(0, -20), 56, 14, RED, 16, 21, 0.75, 0.3)))

	# --- Ledge / recovery ------------------------------------------------------------------
	b.add("ledge_hang", 1, false, {FRAME: JUMP, BODY_ROT: -0.3, BODY_POS: BODY + Vector2(0, 6)})
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
		BODY_ROT: [[0, -0.08], [15, 0.08], [30, -0.08]],
	})
	return b.library


## Rage Spin: the swing frame whirls (the drawing flips facing every few frames, which
## reads as spinning) with a red rage tint, then he slumps, exhausted and tinted dull.
static func _rage_spin_tracks() -> Dictionary:
	var frames := [[0, STARTUP], [9, ACTIVE]]
	var flips := [[0, Vector2(1.1, 0.9)], [8, Vector2(1.1, 0.9)]]
	# Each 6-frame spin: face front, swing through to back (scale.x 1 → -1), hold.
	# Stop the cycle before frame 52 so no flip key bleeds into the slump.
	for f in range(9, 47, 6):
		flips.append([f, Vector2(1, 1)])
		flips.append([f + 2, Vector2(-1, 1)])
		flips.append([f + 5, Vector2(-1, 1)])
	flips.append([51, Vector2(1, 1)])
	frames.append([53, RECOVERY])
	flips.append([53, Vector2(1.05, 0.9)])
	flips.append([90, Vector2.ONE])
	return {
		FRAME: frames,
		RIG_SCALE: flips,
		RIG_TINT: [[0, Color.WHITE], [8, RAGE], [52, RAGE], [56, SPENT], [86, SPENT], [90, Color.WHITE]],
		BODY_POS: [[0, BODY], [52, BODY], [56, BODY + Vector2(0, 5)], [86, BODY + Vector2(0, 5)], [90, BODY]],
	}

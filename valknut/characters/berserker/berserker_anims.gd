class_name BerserkerAnims
extends RefCounted
## Berserker's animations, built from his sprite sheet (berserker_sheet.png) and keyed
## in frames to match berserker_moves.gd. Same approach as ValkyrieAnims: sheet frames
## are discrete keys, motion (spins, lunges, squash) is layered on top.

const FRAME := "Rig/Body/Sprite:frame"
const BODY_POS := "Rig/Body:position"
const BODY_ROT := "Rig/Body:rotation"
const RIG_SCALE := "Rig:scale"
const RIG_TINT := "Rig:modulate"

# Sheet frames (art/source/berserker_sheet_source.jpg, in label order).
const IDLE := 0
const WALK_1 := 1
const WALK_2 := 2
const WALK_3 := 3
const WALK_4 := 4
const JUMP := 5
const FALL := 6
const HURT := 7
const NEUTRAL := 8    ## axe swing
const SIDE := 9       ## lunging sweep
const DOWN := 10      ## low chop into the ground
const RAGE_1 := 11
const RAGE_2 := 12

const BODY := Vector2(0, -46)
const GHOST := Color(1, 1, 1, 0.45)
const FLASH := Color(1.7, 1.7, 1.7)
const SPENT := Color(0.7, 0.7, 0.85)
const SPIN := TAU

const DEFAULT_POSE := {
	FRAME: IDLE, BODY_POS: BODY, BODY_ROT: 0.0, RIG_SCALE: Vector2.ONE, RIG_TINT: Color.WHITE,
}


static func build() -> AnimationLibrary:
	var b := AnimBuilder.new(DEFAULT_POSE)

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
	b.add("crouch", 1, false, {RIG_SCALE: Vector2(1.1, 0.72)})
	b.add("jump_squat", 5, false, {RIG_SCALE: [[0, Vector2(1.06, 0.9)], [5, Vector2(1.15, 0.78)]]})
	b.add("jump", 20, false, {FRAME: JUMP, RIG_SCALE: [[0, Vector2(0.9, 1.1)], [8, Vector2.ONE]]})
	b.add("air_jump", 22, false, {FRAME: JUMP, RIG_SCALE: [[0, Vector2(0.88, 1.12)], [10, Vector2.ONE]]})
	b.add("fall", 1, false, {FRAME: FALL})
	b.add("land", 8, false, {RIG_SCALE: [[0, Vector2(1.22, 0.76)], [8, Vector2.ONE]]})

	# --- Jab string --------------------------------------------------------------------------
	b.add("jab1", 20, false, {FRAME: [[0, IDLE], [3, NEUTRAL], [12, IDLE]]})
	b.add("jab2", 22, false, {
		FRAME: [[0, IDLE], [4, NEUTRAL], [14, IDLE]],
		BODY_POS: [[0, BODY], [5, BODY + Vector2(8, 0)], [14, BODY + Vector2(8, 0)], [22, BODY]],
	})
	b.add("jab3", 40, false, {
		FRAME: [[0, IDLE], [7, DOWN], [26, IDLE]],
		RIG_SCALE: [[0, Vector2.ONE], [6, Vector2(0.95, 1.06)], [8, Vector2(1.1, 0.9)], [16, Vector2.ONE]],
	})

	# --- Tilts / smashes -----------------------------------------------------------------
	b.add("ftilt", 38, false, {FRAME: [[0, IDLE], [9, SIDE], [24, IDLE]]})
	b.add("dtilt", 30, false, {FRAME: [[0, IDLE], [7, DOWN], [20, IDLE]]})
	b.add("fsmash", 64, false, {
		FRAME: [[0, IDLE], [19, SIDE], [40, IDLE]],
		BODY_ROT: [[0, 0.0], [12, -0.15], [19, 0.0]],
		BODY_POS: [[0, BODY], [12, BODY + Vector2(-10, 1)], [19, BODY + Vector2(10, 0)], [40, BODY + Vector2(10, 0)], [64, BODY]],
	})
	b.add("dsmash", 58, false, {
		FRAME: [[0, IDLE], [15, DOWN], [42, IDLE]],
		RIG_SCALE: [[0, Vector2.ONE], [8, Vector2(1.0, 1.06)], [15, Vector2(1.12, 0.88)], [28, Vector2(1.12, 0.88)], [42, Vector2.ONE]],
	})

	# --- Aerials -------------------------------------------------------------------------------
	b.add("nair", 44, false, {FRAME: SIDE, BODY_ROT: [[0, 0.0], [6, 0.0], [22, SPIN], [44, SPIN]]})
	b.add("fair", 46, false, {
		FRAME: [[0, FALL], [10, NEUTRAL], [13, DOWN], [28, FALL]],
		BODY_ROT: [[0, 0.0], [10, -0.2], [14, 0.35], [26, 0.35], [40, 0.0]],
	})
	b.add("dair", 54, false, {
		FRAME: [[0, FALL], [15, DOWN], [34, FALL]],
		BODY_ROT: [[0, 0.0], [14, -0.2], [16, 0.45], [30, 0.45], [40, 0.0]],
		RIG_SCALE: [[0, Vector2.ONE], [14, Vector2(1.05, 0.92)], [16, Vector2(0.92, 1.1)], [24, Vector2.ONE]],
	})

	# --- Specials --------------------------------------------------------------------------
	b.add("nspecial", 40, false, {
		FRAME: [[0, IDLE], [7, JUMP]],
		RIG_SCALE: [[0, Vector2.ONE], [6, Vector2(1.15, 0.8)], [8, Vector2(0.88, 1.15)], [16, Vector2.ONE]],
	})
	b.add("sspecial", 52, false, {
		FRAME: [[0, IDLE], [13, SIDE], [34, IDLE]],
		BODY_ROT: [[0, 0.0], [12, -0.2], [14, 0.25], [26, 0.25], [44, 0.0]],
		BODY_POS: [[0, BODY], [12, BODY + Vector2(-8, 0)], [14, BODY], [52, BODY]],
	})
	b.add("dspecial", 90, false, _rage_spin_tracks())

	# --- Defense ---------------------------------------------------------------------------
	b.add("spot_dodge", 24, false, {
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
		RIG_TINT: [[0, FLASH], [6, GHOST], [18, GHOST], [19, Color.WHITE]],
		RIG_SCALE: [[0, Vector2(1.15, 0.8)], [8, Vector2.ONE]],
	})
	b.add("knockdown", 20, false, {FRAME: HURT, BODY_ROT: -1.4, BODY_POS: [[0, Vector2(0, -28)], [4, Vector2(0, -20)]]})
	b.add("getup", 30, false, {
		FRAME: [[0, HURT], [12, IDLE]],
		RIG_TINT: [[0, GHOST], [22, GHOST], [23, Color.WHITE]],
		BODY_ROT: [[0, -1.4], [12, 0.0]],
		BODY_POS: [[0, Vector2(0, -20)], [12, BODY]],
	})
	b.add("getup_attack", 34, false, {
		FRAME: [[0, HURT], [14, SIDE], [26, IDLE]],
		RIG_TINT: [[0, GHOST], [15, GHOST], [16, Color.WHITE]],
		BODY_ROT: [[0, -1.4], [12, -1.4], [14, 0.0]],
		BODY_POS: [[0, Vector2(0, -20)], [14, BODY]],
	})

	# --- Ledge / recovery ------------------------------------------------------------------
	b.add("ledge_hang", 1, false, {FRAME: JUMP, BODY_ROT: -0.3, BODY_POS: BODY + Vector2(0, 6)})
	b.add("ledge_climb", 28, false, {
		FRAME: [[0, JUMP], [10, WALK_1], [20, IDLE]],
		RIG_TINT: [[0, GHOST], [24, GHOST], [25, Color.WHITE]],
	})
	b.add("ledge_attack", 30, false, {
		FRAME: [[0, IDLE], [9, SIDE], [22, IDLE]],
		RIG_TINT: [[0, GHOST], [9, GHOST], [10, Color.WHITE]],
	})
	b.add("helpless", 30, true, {
		FRAME: FALL,
		RIG_TINT: SPENT,
		BODY_ROT: [[0, -0.08], [15, 0.08], [30, -0.08]],
	})
	return b.library


## Rage Spin: the two rage frames flicker while the drawing flips facing every few
## frames (reads as spinning), then he slumps, exhausted and tinted dull.
static func _rage_spin_tracks() -> Dictionary:
	var frames := [[0, IDLE]]
	var flips := [[0, Vector2(1.1, 0.9)], [8, Vector2(1.1, 0.9)]]
	for f in range(9, 53, 3):
		frames.append([f, RAGE_1 if (f / 3) % 2 == 0 else RAGE_2])
	for f in range(9, 53, 6):
		flips.append([f, Vector2(1, 1)])
		flips.append([f + 2, Vector2(-1, 1)])
		flips.append([f + 5, Vector2(-1, 1)])
	frames.append([53, IDLE])
	flips.append([53, Vector2(1.05, 0.9)])
	flips.append([90, Vector2.ONE])
	return {
		FRAME: frames,
		RIG_SCALE: flips,
		RIG_TINT: [[0, Color.WHITE], [52, Color.WHITE], [56, SPENT], [86, SPENT], [90, Color.WHITE]],
		BODY_POS: [[0, BODY], [52, BODY], [56, BODY + Vector2(0, 5)], [86, BODY + Vector2(0, 5)], [90, BODY]],
	}

class_name BerserkerAnims
extends RefCounted
## Berserker's placeholder animations, keyed in frames to match berserker_moves.gd.
##
## Same conventions as ValkyrieAnims: radians, clockwise-positive; an arm hangs down at
## 0, points forward at -PI/2 and straight up at -PI. Each axe lies along its arm at
## rotation 0, so swinging the arm swings the axe.

const BODY_POS := "Rig/Body:position"
const BODY_ROT := "Rig/Body:rotation"
const RIG_SCALE := "Rig:scale"
const RIG_TINT := "Rig:modulate"
const ARM_F := "Rig/Body/AxeArmFront:rotation"
const AXE_F := "Rig/Body/AxeArmFront/AxeFront:rotation"
const ARM_B := "Rig/Body/AxeArmBack:rotation"
const AXE_B := "Rig/Body/AxeArmBack/AxeBack:rotation"
const LEG_F := "Rig/Body/LegFront:rotation"
const LEG_B := "Rig/Body/LegBack:rotation"

# Idle: both axes held low, heads tipped up and forward.
const ARM_F_IDLE := -0.4
const AXE_F_IDLE := -2.3
const ARM_B_IDLE := 0.25
const AXE_B_IDLE := -2.6
const ARM_UP := -2.9
const BODY := Vector2(0, -46)
const CROUCH := Vector2(1.12, 0.72)
const GHOST := Color(1, 1, 1, 0.4)
const RAGE := Color(1.45, 0.75, 0.7)
const SPENT := Color(0.75, 0.75, 0.9)
const SPIN := TAU

const DEFAULT_POSE := {
	BODY_POS: BODY, BODY_ROT: 0.0, RIG_SCALE: Vector2.ONE, RIG_TINT: Color.WHITE,
	ARM_F: ARM_F_IDLE, AXE_F: AXE_F_IDLE, ARM_B: ARM_B_IDLE, AXE_B: AXE_B_IDLE,
	LEG_F: 0.0, LEG_B: 0.0,
}


static func build() -> AnimationLibrary:
	var b := AnimBuilder.new(DEFAULT_POSE)

	# --- Movement: heavy, stompy -------------------------------------------------------
	b.add("idle", 60, true, {
		BODY_POS: [[0, BODY], [30, BODY + Vector2(0, 3)], [60, BODY]],
		ARM_F: [[0, ARM_F_IDLE], [30, ARM_F_IDLE - 0.1], [60, ARM_F_IDLE]],
		ARM_B: [[0, ARM_B_IDLE], [30, ARM_B_IDLE + 0.1], [60, ARM_B_IDLE]],
	})
	b.add("walk", 40, true, {
		LEG_F: [[0, 0.35], [20, -0.35], [40, 0.35]],
		LEG_B: [[0, -0.35], [20, 0.35], [40, -0.35]],
		BODY_POS: [[0, BODY], [10, BODY + Vector2(0, 3)], [20, BODY], [30, BODY + Vector2(0, 3)], [40, BODY]],
		BODY_ROT: 0.05,
	})
	b.add("dash", 12, false, {BODY_ROT: 0.25, LEG_F: -0.7, LEG_B: 0.7, ARM_B: 0.9, ARM_F: 0.4})
	b.add("run", 30, true, {
		BODY_ROT: 0.22,
		LEG_F: [[0, 0.7], [15, -0.7], [30, 0.7]],
		LEG_B: [[0, -0.7], [15, 0.7], [30, -0.7]],
		ARM_F: [[0, -0.9], [15, 0.3], [30, -0.9]],
		ARM_B: [[0, 0.6], [15, -0.6], [30, 0.6]],
		BODY_POS: [[0, BODY], [8, BODY + Vector2(0, 4)], [15, BODY], [23, BODY + Vector2(0, 4)], [30, BODY]],
	})
	b.add("crouch", 1, false, {RIG_SCALE: CROUCH, BODY_ROT: 0.12})
	b.add("jump_squat", 5, false, {RIG_SCALE: [[0, Vector2(1.08, 0.9)], [5, Vector2(1.18, 0.78)]]})
	b.add("jump", 20, false, {
		RIG_SCALE: [[0, Vector2(0.9, 1.1)], [8, Vector2.ONE]],
		LEG_F: -0.5, LEG_B: 0.3, ARM_F: -1.0, ARM_B: 0.8,
	})
	b.add("air_jump", 22, false, {
		RIG_SCALE: [[0, Vector2(0.88, 1.12)], [10, Vector2.ONE]],
		LEG_F: [[0, -1.0], [18, -0.4]], LEG_B: [[0, -0.7], [18, 0.2]],
		ARM_F: [[0, -2.6], [18, -1.4]], ARM_B: [[0, -2.4], [18, 0.6]],
	})
	b.add("fall", 1, false, {LEG_F: 0.2, LEG_B: -0.2, ARM_F: -1.2, ARM_B: 1.0})
	b.add("land", 8, false, {RIG_SCALE: [[0, Vector2(1.25, 0.74)], [8, Vector2.ONE]]})

	# --- Jab string ------------------------------------------------------------------
	b.add("jab1", 20, false, {
		ARM_F: [[0, ARM_F_IDLE], [2, -2.4], [4, -1.2], [10, -1.2], [20, ARM_F_IDLE]],
		AXE_F: [[0, AXE_F_IDLE], [2, 0.0], [10, 0.0], [20, AXE_F_IDLE]],
	})
	b.add("jab2", 22, false, {
		ARM_B: [[0, ARM_B_IDLE], [3, -2.4], [5, -1.2], [12, -1.2], [22, ARM_B_IDLE]],
		AXE_B: [[0, AXE_B_IDLE], [3, 0.0], [12, 0.0], [22, AXE_B_IDLE]],
		BODY_POS: [[0, BODY], [5, BODY + Vector2(6, 0)], [12, BODY + Vector2(6, 0)], [22, BODY]],
		BODY_ROT: [[0, 0.0], [5, 0.1], [12, 0.1], [22, 0.0]],
	})
	b.add("jab3", 40, false, {
		ARM_F: [[0, -1.2], [7, ARM_UP], [9, -0.9], [20, -0.9], [40, ARM_F_IDLE]],
		ARM_B: [[0, ARM_B_IDLE], [7, -2.7], [9, -1.0], [20, -1.0], [40, ARM_B_IDLE]],
		AXE_F: [[0, 0.0], [20, 0.0], [40, AXE_F_IDLE]],
		AXE_B: [[0, 0.0], [20, 0.0], [40, AXE_B_IDLE]],
		BODY_ROT: [[0, 0.0], [7, -0.12], [9, 0.25], [20, 0.25], [40, 0.0]],
		RIG_SCALE: [[0, Vector2.ONE], [7, Vector2(0.95, 1.06)], [9, Vector2(1.1, 0.9)], [16, Vector2.ONE]],
	})

	# --- Tilts ------------------------------------------------------------------------
	b.add("ftilt", 38, false, {
		ARM_F: [[0, ARM_F_IDLE], [8, 1.3], [11, -1.45], [20, -1.45], [38, ARM_F_IDLE]],
		AXE_F: [[0, AXE_F_IDLE], [8, 0.0], [20, 0.0], [38, AXE_F_IDLE]],
		ARM_B: [[0, ARM_B_IDLE], [8, -0.8], [11, 1.0], [20, 1.0], [38, ARM_B_IDLE]],
		BODY_ROT: [[0, 0.0], [8, -0.15], [11, 0.15], [20, 0.15], [38, 0.0]],
		LEG_F: [[0, 0.0], [11, -0.5], [20, -0.5], [38, 0.0]],
		LEG_B: [[0, 0.0], [11, 0.4], [20, 0.4], [38, 0.0]],
	})
	b.add("dtilt", 30, false, {
		RIG_SCALE: CROUCH,
		ARM_F: [[0, ARM_F_IDLE], [6, 0.6], [8, -0.8], [16, -0.8], [30, ARM_F_IDLE]],
		AXE_F: [[0, AXE_F_IDLE], [6, 0.0], [16, 0.0], [30, AXE_F_IDLE]],
	})

	# --- Smashes ----------------------------------------------------------------------
	b.add("fsmash", 64, false, {
		ARM_F: [[0, ARM_F_IDLE], [12, 1.4], [20, -1.45], [32, -1.45], [64, ARM_F_IDLE]],
		ARM_B: [[0, ARM_B_IDLE], [12, 1.6], [21, -1.3], [32, -1.3], [64, ARM_B_IDLE]],
		AXE_F: [[0, AXE_F_IDLE], [6, 0.0], [32, 0.0], [64, AXE_F_IDLE]],
		AXE_B: [[0, AXE_B_IDLE], [6, 0.0], [32, 0.0], [64, AXE_B_IDLE]],
		BODY_ROT: [[0, 0.0], [12, -0.25], [20, 0.2], [32, 0.2], [64, 0.0]],
		BODY_POS: [[0, BODY], [12, BODY + Vector2(-8, 2)], [20, BODY + Vector2(8, 2)], [32, BODY + Vector2(8, 2)], [64, BODY]],
		LEG_F: [[0, 0.0], [12, 0.3], [20, -0.6], [32, -0.6], [64, 0.0]],
		LEG_B: [[0, 0.0], [20, 0.5], [32, 0.5], [64, 0.0]],
	})
	b.add("dsmash", 58, false, {
		ARM_F: [[0, ARM_F_IDLE], [8, ARM_UP], [16, -0.6], [30, -0.6], [58, ARM_F_IDLE]],
		ARM_B: [[0, ARM_B_IDLE], [8, 2.9], [16, 0.7], [30, 0.7], [58, ARM_B_IDLE]],
		AXE_F: [[0, AXE_F_IDLE], [6, 0.0], [30, 0.0], [58, AXE_F_IDLE]],
		AXE_B: [[0, AXE_B_IDLE], [6, 0.0], [30, 0.0], [58, AXE_B_IDLE]],
		RIG_SCALE: [[0, Vector2.ONE], [8, Vector2(1.0, 1.06)], [16, Vector2(1.15, 0.85)], [30, Vector2(1.15, 0.85)], [58, Vector2.ONE]],
		LEG_F: [[0, 0.0], [8, -0.9], [16, 0.0]],
	})

	# --- Aerials ----------------------------------------------------------------------
	b.add("nair", 44, false, {
		BODY_ROT: [[0, 0.0], [6, 0.0], [22, SPIN], [44, SPIN]],
		ARM_F: [[0, ARM_F_IDLE], [6, -1.6], [24, -1.6], [44, ARM_F_IDLE]],
		ARM_B: [[0, ARM_B_IDLE], [6, 1.6], [24, 1.6], [44, ARM_B_IDLE]],
		AXE_F: [[0, AXE_F_IDLE], [6, 0.0], [24, 0.0], [44, AXE_F_IDLE]],
		AXE_B: [[0, AXE_B_IDLE], [6, 0.0], [24, 0.0], [44, AXE_B_IDLE]],
		LEG_F: -0.6, LEG_B: -0.3,
	})
	b.add("fair", 46, false, {
		ARM_F: [[0, ARM_F_IDLE], [10, -3.0], [14, -0.5], [24, -0.5], [46, ARM_F_IDLE]],
		ARM_B: [[0, ARM_B_IDLE], [10, -2.8], [14, -0.7], [24, -0.7], [46, ARM_B_IDLE]],
		AXE_F: [[0, AXE_F_IDLE], [8, 0.0], [24, 0.0], [46, AXE_F_IDLE]],
		AXE_B: [[0, AXE_B_IDLE], [8, 0.0], [24, 0.0], [46, AXE_B_IDLE]],
		BODY_ROT: [[0, 0.0], [10, -0.2], [14, 0.3], [24, 0.3], [46, 0.0]],
		LEG_F: -0.4, LEG_B: 0.3,
	})
	b.add("dair", 54, false, {
		ARM_F: [[0, ARM_F_IDLE], [12, ARM_UP], [16, -0.1], [30, -0.1], [54, ARM_F_IDLE]],
		ARM_B: [[0, ARM_B_IDLE], [12, 2.9], [16, 0.1], [30, 0.1], [54, ARM_B_IDLE]],
		AXE_F: [[0, AXE_F_IDLE], [8, 0.0], [30, 0.0], [54, AXE_F_IDLE]],
		AXE_B: [[0, AXE_B_IDLE], [8, 0.0], [30, 0.0], [54, AXE_B_IDLE]],
		LEG_F: [[0, 0.0], [12, -0.9], [30, -0.9], [54, 0.0]],
		LEG_B: [[0, 0.0], [12, 0.7], [30, 0.7], [54, 0.0]],
		RIG_SCALE: [[0, Vector2.ONE], [12, Vector2(1.05, 0.92)], [16, Vector2(0.92, 1.1)], [24, Vector2.ONE]],
	})

	# --- Specials ---------------------------------------------------------------------
	b.add("nspecial", 40, false, {
		ARM_F: [[0, ARM_F_IDLE], [6, 0.3], [8, ARM_UP], [40, -2.7]],
		ARM_B: [[0, ARM_B_IDLE], [6, 0.6], [8, -2.7], [40, -2.6]],
		AXE_F: [[0, AXE_F_IDLE], [6, 0.0], [40, 0.0]],
		AXE_B: [[0, AXE_B_IDLE], [6, 0.0], [40, 0.0]],
		RIG_SCALE: [[0, Vector2.ONE], [6, Vector2(1.15, 0.8)], [8, Vector2(0.88, 1.15)], [16, Vector2.ONE]],
		LEG_F: [[0, 0.0], [8, -0.4], [40, -0.2]], LEG_B: [[0, 0.0], [8, 0.4], [40, 0.2]],
	})
	b.add("sspecial", 52, false, {
		ARM_F: [[0, ARM_F_IDLE], [12, 1.2], [14, -1.5], [26, -1.5], [52, ARM_F_IDLE]],
		ARM_B: [[0, ARM_B_IDLE], [12, 1.5], [15, -1.35], [26, -1.35], [52, ARM_B_IDLE]],
		AXE_F: [[0, AXE_F_IDLE], [8, 0.0], [26, 0.0], [52, AXE_F_IDLE]],
		AXE_B: [[0, AXE_B_IDLE], [8, 0.0], [26, 0.0], [52, AXE_B_IDLE]],
		BODY_ROT: [[0, 0.0], [12, -0.2], [14, 0.35], [26, 0.35], [52, 0.0]],
		LEG_F: [[0, 0.0], [14, -0.7], [26, -0.7], [52, 0.0]],
		LEG_B: [[0, 0.0], [14, 0.7], [26, 0.7], [52, 0.0]],
	})
	b.add("dspecial", 90, false, {
		BODY_ROT: [[0, 0.0], [8, 0.0], [52, SPIN * 4], [90, SPIN * 4]],
		ARM_F: [[0, ARM_F_IDLE], [8, -1.57], [52, -1.57], [56, 0.3], [90, ARM_F_IDLE]],
		ARM_B: [[0, ARM_B_IDLE], [8, 1.57], [52, 1.57], [56, 0.4], [90, ARM_B_IDLE]],
		AXE_F: [[0, AXE_F_IDLE], [8, 0.0], [56, 0.0], [90, AXE_F_IDLE]],
		AXE_B: [[0, AXE_B_IDLE], [8, 0.0], [56, 0.0], [90, AXE_B_IDLE]],
		RIG_TINT: [[0, Color.WHITE], [8, RAGE], [52, RAGE], [58, SPENT], [86, SPENT], [90, Color.WHITE]],
		# Exhausted, hunched over: the punishable window.
		BODY_POS: [[0, BODY], [52, BODY], [58, BODY + Vector2(0, 6)], [86, BODY + Vector2(0, 6)], [90, BODY]],
		LEG_F: [[0, 0.0], [8, -0.3], [52, -0.3], [56, 0.0]],
		LEG_B: [[0, 0.0], [8, 0.3], [52, 0.3], [56, 0.0]],
	})

	# --- Defense ------------------------------------------------------------------------
	b.add("spot_dodge", 24, false, {
		RIG_TINT: [[0, Color.WHITE], [3, GHOST], [16, GHOST], [17, Color.WHITE]],
		RIG_SCALE: [[0, Vector2.ONE], [4, Vector2(1.08, 0.88)], [16, Vector2(1.08, 0.88)], [24, Vector2.ONE]],
		ARM_F: [[0, ARM_F_IDLE], [4, -2.2], [16, -2.2], [24, ARM_F_IDLE]],
	})
	b.add("roll", 34, false, {
		RIG_TINT: [[0, Color.WHITE], [3, GHOST], [18, GHOST], [19, Color.WHITE]],
		BODY_ROT: [[0, 0.0], [3, 0.0], [21, SPIN], [34, SPIN]],
		BODY_POS: [[0, BODY], [3, Vector2(0, -28)], [21, Vector2(0, -28)], [26, BODY]],
		RIG_SCALE: [[0, Vector2.ONE], [3, Vector2(0.9, 0.85)], [21, Vector2(0.9, 0.85)], [26, Vector2.ONE]],
		LEG_F: -1.2, LEG_B: -1.0,
	})
	b.add("air_dodge", 34, false, {
		RIG_TINT: [[0, Color.WHITE], [3, GHOST], [24, GHOST], [26, Color.WHITE]],
		RIG_SCALE: [[0, Vector2.ONE], [3, Vector2(0.9, 0.9)], [24, Vector2(0.9, 0.9)], [30, Vector2.ONE]],
		ARM_F: -2.0, ARM_B: -1.8, LEG_F: -0.7, LEG_B: -0.5,
	})

	# --- Getting hit --------------------------------------------------------------------
	b.add("hurt", 20, false, {
		BODY_ROT: [[0, -0.25], [20, -0.08]],
		ARM_F: 0.8, ARM_B: 1.1, LEG_F: 0.3, LEG_B: -0.2,
	})
	b.add("tumble", 24, true, {
		BODY_ROT: [[0, 0.0], [24, -SPIN]],
		ARM_F: 1.2, ARM_B: -1.4, LEG_F: 0.6, LEG_B: -0.6,
	})
	b.add("tech", 20, false, {
		RIG_TINT: [[0, Color(1.6, 1.6, 1.6)], [6, GHOST], [18, GHOST], [19, Color.WHITE]],
		RIG_SCALE: [[0, Vector2(1.2, 0.75)], [8, Vector2.ONE]],
	})
	b.add("knockdown", 20, false, {
		BODY_ROT: -1.571, BODY_POS: [[0, Vector2(0, -26)], [4, Vector2(0, -14)]],
		ARM_F: 0.4, ARM_B: -0.6,
	})
	b.add("getup", 30, false, {
		RIG_TINT: [[0, GHOST], [22, GHOST], [23, Color.WHITE]],
		BODY_ROT: [[0, -1.571], [14, 0.0]],
		BODY_POS: [[0, Vector2(0, -14)], [14, BODY]],
	})
	b.add("getup_attack", 34, false, {
		BODY_ROT: [[0, -1.571], [10, -1.571], [16, 0.0]],
		BODY_POS: [[0, Vector2(0, -14)], [16, BODY]],
		ARM_F: [[0, ARM_F_IDLE], [14, ARM_UP], [17, -1.0], [24, -1.0], [34, ARM_F_IDLE]],
		ARM_B: [[0, ARM_B_IDLE], [14, 2.9], [17, 1.0], [24, 1.0], [34, ARM_B_IDLE]],
		AXE_F: [[0, AXE_F_IDLE], [12, 0.0], [24, 0.0], [34, AXE_F_IDLE]],
		AXE_B: [[0, AXE_B_IDLE], [12, 0.0], [24, 0.0], [34, AXE_B_IDLE]],
		RIG_TINT: [[0, GHOST], [15, GHOST], [16, Color.WHITE]],
	})

	# --- Ledge / recovery ---------------------------------------------------------------
	b.add("ledge_hang", 1, false, {
		BODY_POS: Vector2(0, -30), ARM_F: -3.0, ARM_B: -3.0, AXE_F: 3.0, AXE_B: 3.0,
		LEG_F: 0.2, LEG_B: -0.1,
	})
	b.add("ledge_climb", 28, false, {
		RIG_TINT: [[0, GHOST], [24, GHOST], [25, Color.WHITE]],
		BODY_POS: [[0, Vector2(0, -30)], [12, BODY]],
		RIG_SCALE: [[0, Vector2.ONE], [12, Vector2(1.1, 0.85)], [20, Vector2.ONE]],
		ARM_F: [[0, -3.0], [12, ARM_F_IDLE]], ARM_B: [[0, -3.0], [12, ARM_B_IDLE]],
	})
	b.add("ledge_attack", 30, false, {
		ARM_F: [[0, ARM_F_IDLE], [8, 1.2], [11, -1.4], [18, -1.4], [30, ARM_F_IDLE]],
		AXE_F: [[0, AXE_F_IDLE], [8, 0.0], [18, 0.0], [30, AXE_F_IDLE]],
		RIG_TINT: [[0, GHOST], [9, GHOST], [10, Color.WHITE]],
	})
	b.add("helpless", 30, true, {
		RIG_TINT: Color(0.65, 0.65, 0.8),
		BODY_ROT: [[0, -0.08], [15, 0.08], [30, -0.08]],
		ARM_F: [[0, -2.6], [15, -2.9], [30, -2.6]], ARM_B: [[0, -2.9], [15, -2.6], [30, -2.9]],
		AXE_F: 0.0, AXE_B: 0.0, LEG_F: 0.3, LEG_B: -0.3,
	})
	return b.library

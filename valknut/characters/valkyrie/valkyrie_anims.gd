class_name ValkyrieAnims
extends RefCounted
## Valkyrie's placeholder animations, keyed in frames so they line up with
## valkyrie_moves.gd (an attack animation's length = the move's total_frames).
##
## Rotations are radians, clockwise-positive (Godot is y-down). Arms hang down at 0;
## -PI/2 points an arm straight forward, -PI straight up. The spear lies along its arm
## at Spear:rotation 0, so "arm forward + spear 0" is a forward thrust.

const BODY_POS := "Rig/Body:position"
const BODY_ROT := "Rig/Body:rotation"
const RIG_SCALE := "Rig:scale"
const RIG_TINT := "Rig:modulate"
const SPEAR_ARM := "Rig/Body/SpearArm:rotation"
const SPEAR := "Rig/Body/SpearArm/Spear:rotation"
const SPEAR_POS := "Rig/Body/SpearArm/Spear:position"
const SHIELD_ARM := "Rig/Body/ShieldArm:rotation"
const LEG_F := "Rig/Body/LegFront:rotation"
const LEG_B := "Rig/Body/LegBack:rotation"
const CAPE := "Rig/Body/Cape:rotation"
const WINGS := "Rig/Body/Wings:modulate"

# Idle stance: spear held diagonally forward-up.
const ARM_IDLE := -0.9
const SPEAR_IDLE := -1.456
const ARM_FWD := -1.571
const ARM_UP := -2.9
const ARM_FWD_UP := -1.75
const ARM_FWD_DOWN := -1.134
const HAND := Vector2(0, 20)
const BODY := Vector2(0, -42)
const CROUCH := Vector2(1.1, 0.7)
const GHOST := Color(1, 1, 1, 0.4)
const HIDDEN := Color(1, 1, 1, 0)
const SPIN := TAU

const DEFAULT_POSE := {
	BODY_POS: BODY, BODY_ROT: 0.0, RIG_SCALE: Vector2.ONE, RIG_TINT: Color.WHITE,
	SPEAR_ARM: ARM_IDLE, SPEAR: SPEAR_IDLE, SPEAR_POS: HAND, SHIELD_ARM: 0.15,
	LEG_F: 0.0, LEG_B: 0.0, CAPE: 0.0, WINGS: HIDDEN,
}


static func build() -> AnimationLibrary:
	var b := AnimBuilder.new(DEFAULT_POSE)

	# --- Movement -------------------------------------------------------------------
	b.add("idle", 60, true, {
		BODY_POS: [[0, BODY], [30, BODY + Vector2(0, 2)], [60, BODY]],
		CAPE: [[0, 0.0], [30, 0.12], [60, 0.0]],
	})
	b.add("walk", 32, true, {
		LEG_F: [[0, 0.45], [16, -0.45], [32, 0.45]],
		LEG_B: [[0, -0.45], [16, 0.45], [32, -0.45]],
		BODY_POS: [[0, BODY], [8, BODY + Vector2(0, -2)], [16, BODY], [24, BODY + Vector2(0, -2)], [32, BODY]],
		CAPE: 0.2,
	})
	b.add("dash", 10, false, {
		BODY_ROT: 0.22, LEG_F: -0.8, LEG_B: 0.8, CAPE: 0.5, SHIELD_ARM: 0.6,
	})
	b.add("run", 24, true, {
		BODY_ROT: 0.18, CAPE: [[0, 0.5], [12, 0.6], [24, 0.5]], SHIELD_ARM: 0.6,
		LEG_F: [[0, 0.8], [12, -0.8], [24, 0.8]],
		LEG_B: [[0, -0.8], [12, 0.8], [24, -0.8]],
		BODY_POS: [[0, BODY], [6, BODY + Vector2(0, -3)], [12, BODY], [18, BODY + Vector2(0, -3)], [24, BODY]],
	})
	b.add("crouch", 1, false, {RIG_SCALE: CROUCH, BODY_ROT: 0.1})
	b.add("jump_squat", 4, false, {RIG_SCALE: [[0, Vector2(1.05, 0.9)], [4, Vector2(1.15, 0.8)]]})
	b.add("jump", 20, false, {
		RIG_SCALE: [[0, Vector2(0.88, 1.14)], [8, Vector2.ONE]],
		LEG_F: -0.5, LEG_B: 0.4, CAPE: -0.3,
	})
	b.add("air_jump", 22, false, {
		BODY_ROT: [[0, 0.0], [18, SPIN]],  # forward flip
		LEG_F: [[0, -0.9], [18, -0.3]], LEG_B: [[0, -0.6], [18, 0.3]],
	})
	b.add("fall", 1, false, {LEG_F: 0.25, LEG_B: -0.2, CAPE: -0.5, SHIELD_ARM: -0.4})
	b.add("land", 6, false, {RIG_SCALE: [[0, Vector2(1.2, 0.78)], [6, Vector2.ONE]]})

	# --- Jab string -------------------------------------------------------------------
	b.add("jab1", 18, false, {
		SPEAR_ARM: [[0, ARM_IDLE], [2, ARM_FWD], [8, ARM_FWD], [18, ARM_IDLE]],
		SPEAR: [[0, SPEAR_IDLE], [2, 0.0], [8, 0.0], [18, SPEAR_IDLE]],
		SPEAR_POS: [[0, HAND], [2, Vector2(0, 0)], [3, Vector2(0, 8)], [8, Vector2(0, 8)], [18, HAND]],
	})
	b.add("jab2", 20, false, {
		SHIELD_ARM: [[0, 0.15], [3, ARM_FWD], [10, ARM_FWD], [20, 0.15]],
		BODY_POS: [[0, BODY], [4, BODY + Vector2(8, 0)], [12, BODY + Vector2(8, 0)], [20, BODY]],
		BODY_ROT: [[0, 0.0], [4, 0.12], [12, 0.12], [20, 0.0]],
		SPEAR_ARM: 0.6, SPEAR: 3.3,
	})
	b.add("jab3", 34, false, {
		SPEAR_ARM: [[0, -1.2], [6, -1.2], [7, ARM_FWD - 0.2], [18, ARM_FWD - 0.2], [34, ARM_IDLE]],
		SPEAR: [[0, 0.0], [18, 0.0], [34, SPEAR_IDLE]],
		SPEAR_POS: [[0, Vector2(0, 0)], [6, Vector2(0, -6)], [7, Vector2(0, 28)], [18, Vector2(0, 28)], [34, HAND]],
		BODY_ROT: [[0, -0.1], [6, -0.1], [7, 0.2], [18, 0.2], [34, 0.0]],
		LEG_F: [[0, 0.0], [6, 0.0], [7, -0.6], [18, -0.6], [34, 0.0]],
		LEG_B: [[0, 0.0], [6, 0.0], [7, 0.5], [18, 0.5], [34, 0.0]],
		CAPE: [[0, 0.0], [7, 0.5], [34, 0.0]],
	})

	# --- Tilts ------------------------------------------------------------------------
	b.add("ftilt", 30, false, {
		SPEAR_ARM: [[0, ARM_IDLE], [6, -1.3], [8, ARM_FWD - 0.12], [16, ARM_FWD - 0.12], [30, ARM_IDLE]],
		SPEAR: [[0, SPEAR_IDLE], [6, 0.0], [16, 0.0], [30, SPEAR_IDLE]],
		SPEAR_POS: [[0, HAND], [7, Vector2(0, 6)], [8, Vector2(0, 28)], [16, Vector2(0, 28)], [30, HAND]],
		BODY_ROT: [[0, 0.0], [7, -0.05], [8, 0.12], [16, 0.12], [30, 0.0]],
		LEG_F: [[0, 0.0], [8, -0.4], [16, -0.4], [30, 0.0]],
	})
	b.add("dtilt", 20, false, {
		RIG_SCALE: CROUCH,
		SPEAR_ARM: [[0, -0.6], [5, -0.9], [6, ARM_FWD_DOWN], [12, ARM_FWD_DOWN], [20, -0.6]],
		SPEAR: [[0, 0.0], [20, 0.0]],
		SPEAR_POS: [[0, HAND], [5, Vector2(0, 4)], [6, Vector2(0, 28)], [12, Vector2(0, 28)], [20, HAND]],
	})

	# --- Smashes ----------------------------------------------------------------------
	b.add("fsmash", 52, false, {
		SPEAR_ARM: [[0, ARM_IDLE], [9, -1.25], [13, ARM_FWD - 0.25], [24, ARM_FWD - 0.25], [52, ARM_IDLE]],
		SPEAR: [[0, SPEAR_IDLE], [6, 0.0], [24, 0.0], [52, SPEAR_IDLE]],
		SPEAR_POS: [[0, HAND], [9, Vector2(0, -14)], [13, Vector2(0, 34)], [24, Vector2(0, 34)], [52, HAND]],
		BODY_ROT: [[0, 0.0], [9, -0.2], [13, 0.25], [24, 0.25], [52, 0.0]],
		BODY_POS: [[0, BODY], [9, BODY + Vector2(-6, 2)], [13, BODY + Vector2(6, 4)], [24, BODY + Vector2(6, 4)], [52, BODY]],
		LEG_F: [[0, 0.0], [9, 0.2], [13, -0.7], [24, -0.7], [52, 0.0]],
		LEG_B: [[0, 0.0], [13, 0.6], [24, 0.6], [52, 0.0]],
		CAPE: [[0, 0.0], [9, -0.2], [13, 0.7], [24, 0.6], [52, 0.0]],
	})
	b.add("dsmash", 48, false, {
		RIG_SCALE: [[0, Vector2.ONE], [6, Vector2(1.1, 0.82)], [16, Vector2(1.1, 0.82)],
			[17, Vector2(-1.1, 0.82)], [30, Vector2(-1.1, 0.82)], [31, Vector2(1.0, 1.0)]],
		SPEAR_ARM: [[0, ARM_IDLE], [6, -2.2], [10, -1.0], [16, -1.0], [17, -2.2], [18, -1.0], [30, -1.0], [48, ARM_IDLE]],
		SPEAR: [[0, SPEAR_IDLE], [6, 0.0], [30, 0.0], [48, SPEAR_IDLE]],
		SPEAR_POS: [[0, HAND], [10, Vector2(0, 26)], [30, Vector2(0, 26)], [48, HAND]],
	})

	# --- Aerials ----------------------------------------------------------------------
	b.add("nair", 38, false, {
		BODY_ROT: [[0, 0.0], [4, 0.0], [20, SPIN], [38, SPIN]],
		SHIELD_ARM: [[0, 0.15], [4, ARM_FWD], [22, ARM_FWD], [38, 0.15]],
		SPEAR_ARM: [[0, ARM_IDLE], [4, 1.3], [22, 1.3], [38, ARM_IDLE]],
		SPEAR: [[0, SPEAR_IDLE], [4, 0.0], [22, 0.0], [38, SPEAR_IDLE]],
		LEG_F: -0.6, LEG_B: -0.3,
	})
	b.add("fair", 36, false, {
		SPEAR_ARM: [[0, ARM_IDLE], [5, -1.0], [7, ARM_FWD_UP], [15, ARM_FWD_UP], [36, ARM_IDLE]],
		SPEAR: [[0, SPEAR_IDLE], [5, 0.0], [15, 0.0], [36, SPEAR_IDLE]],
		SPEAR_POS: [[0, HAND], [6, Vector2(0, 2)], [7, Vector2(0, 30)], [15, Vector2(0, 30)], [36, HAND]],
		BODY_ROT: [[0, 0.0], [6, 0.1], [7, -0.05], [15, -0.05], [36, 0.0]],
		LEG_F: -0.5, LEG_B: 0.2, CAPE: -0.4,
	})
	b.add("dair", 44, false, {
		SPEAR_ARM: [[0, ARM_IDLE], [8, ARM_UP], [11, ARM_UP], [12, 0.0], [24, 0.0], [44, ARM_IDLE]],
		SPEAR: [[0, SPEAR_IDLE], [8, 0.0], [24, 0.0], [44, SPEAR_IDLE]],
		SPEAR_POS: [[0, HAND], [11, Vector2(0, -6)], [12, Vector2(0, 32)], [24, Vector2(0, 32)], [44, HAND]],
		LEG_F: [[0, 0.0], [10, -0.8], [24, -0.8], [44, 0.0]],
		LEG_B: [[0, 0.0], [10, -0.4], [24, -0.4], [44, 0.0]],
		RIG_SCALE: [[0, Vector2.ONE], [11, Vector2(1.05, 0.92)], [12, Vector2(0.92, 1.1)], [20, Vector2.ONE]],
	})

	# --- Specials ---------------------------------------------------------------------
	b.add("nspecial", 80, false, {
		WINGS: [[0, HIDDEN], [6, Color.WHITE], [74, Color.WHITE], [80, HIDDEN]],
		SPEAR_ARM: [[0, ARM_IDLE], [6, ARM_UP], [24, ARM_UP], [30, -2.3], [80, -2.3]],
		SPEAR: [[0, SPEAR_IDLE], [6, 0.0], [80, 0.0]],
		SHIELD_ARM: [[0, 0.15], [6, -2.4], [24, -2.4], [30, -1.8], [80, -1.8]],
		RIG_SCALE: [[0, Vector2(1.1, 0.85)], [6, Vector2(1.1, 0.85)], [8, Vector2(0.85, 1.2)], [16, Vector2.ONE]],
		LEG_F: -0.3, LEG_B: 0.3,
		CAPE: [[0, 0.0], [7, -0.8], [24, -0.3], [52, -0.5], [80, -0.3]],
	})
	b.add("sspecial", 44, false, {
		SHIELD_ARM: [[0, 0.15], [7, 0.5], [9, ARM_FWD], [28, ARM_FWD], [44, 0.15]],
		BODY_ROT: [[0, 0.0], [7, -0.15], [9, 0.35], [26, 0.35], [44, 0.0]],
		SPEAR_ARM: [[0, ARM_IDLE], [9, 0.9], [28, 0.9], [44, ARM_IDLE]],
		SPEAR: [[0, SPEAR_IDLE], [9, 3.0], [28, 3.0], [44, SPEAR_IDLE]],
		LEG_F: [[0, 0.0], [9, -0.7], [26, -0.7], [44, 0.0]],
		LEG_B: [[0, 0.0], [9, 0.7], [26, 0.7], [44, 0.0]],
		CAPE: [[0, 0.0], [9, 0.9], [26, 0.9], [44, 0.0]],
	})
	b.add("dspecial", 40, false, {
		BODY_ROT: [[0, 0.0], [8, -0.5], [10, -0.5], [12, 1.0], [40, 1.0]],
		SPEAR_ARM: [[0, ARM_IDLE], [8, ARM_UP], [10, ARM_UP], [12, ARM_FWD], [40, ARM_FWD]],
		SPEAR: [[0, SPEAR_IDLE], [8, 0.0], [40, 0.0]],
		SPEAR_POS: [[0, HAND], [11, HAND], [12, Vector2(0, 30)], [40, Vector2(0, 30)]],
		LEG_F: [[0, 0.0], [12, 0.5], [40, 0.5]],
		LEG_B: [[0, 0.0], [12, 0.9], [40, 0.9]],
		CAPE: [[0, 0.0], [12, -1.2], [40, -1.2]],
		WINGS: [[0, HIDDEN], [10, Color(1, 1, 1, 0.8)], [40, Color(1, 1, 1, 0.8)]],
	})

	# --- Defense ----------------------------------------------------------------------
	b.add("spot_dodge", 24, false, {
		RIG_TINT: [[0, Color.WHITE], [3, GHOST], [16, GHOST], [17, Color.WHITE]],
		BODY_POS: [[0, BODY], [4, BODY + Vector2(-4, 4)], [16, BODY + Vector2(-4, 4)], [24, BODY]],
		SHIELD_ARM: [[0, 0.15], [4, -1.2], [16, -1.2], [24, 0.15]],
	})
	b.add("roll", 34, false, {
		RIG_TINT: [[0, Color.WHITE], [3, GHOST], [18, GHOST], [19, Color.WHITE]],
		BODY_ROT: [[0, 0.0], [3, 0.0], [21, SPIN], [34, SPIN]],
		BODY_POS: [[0, BODY], [3, Vector2(0, -26)], [21, Vector2(0, -26)], [26, BODY]],
		RIG_SCALE: [[0, Vector2.ONE], [3, Vector2(0.9, 0.85)], [21, Vector2(0.9, 0.85)], [26, Vector2.ONE]],
		LEG_F: -1.2, LEG_B: -1.0,
	})
	b.add("air_dodge", 34, false, {
		RIG_TINT: [[0, Color.WHITE], [3, GHOST], [24, GHOST], [26, Color.WHITE]],
		RIG_SCALE: [[0, Vector2.ONE], [3, Vector2(0.9, 0.9)], [24, Vector2(0.9, 0.9)], [30, Vector2.ONE]],
		SHIELD_ARM: [[0, 0.15], [3, -1.4], [24, -1.4], [34, 0.15]],
		LEG_F: -0.7, LEG_B: -0.5,
	})

	# --- Getting hit ------------------------------------------------------------------
	b.add("hurt", 20, false, {
		BODY_ROT: [[0, -0.3], [20, -0.1]],
		SPEAR_ARM: 0.7, SPEAR: 3.0, SHIELD_ARM: 1.0, LEG_F: 0.35, LEG_B: -0.2, CAPE: -0.6,
	})
	b.add("tumble", 24, true, {
		BODY_ROT: [[0, 0.0], [24, -SPIN]],
		SPEAR_ARM: 1.2, SPEAR: 2.6, SHIELD_ARM: -1.6, LEG_F: 0.6, LEG_B: -0.6,
	})
	b.add("tech", 20, false, {
		RIG_TINT: [[0, Color(1.6, 1.6, 1.6)], [6, GHOST], [18, GHOST], [19, Color.WHITE]],
		RIG_SCALE: [[0, Vector2(1.2, 0.75)], [8, Vector2.ONE]],
	})
	b.add("knockdown", 20, false, {
		BODY_ROT: -1.571, BODY_POS: [[0, Vector2(0, -24)], [4, Vector2(0, -12)]],
		SPEAR_ARM: 0.4, SPEAR: 0.0, SHIELD_ARM: -0.6,
	})
	b.add("getup", 30, false, {
		RIG_TINT: [[0, GHOST], [22, GHOST], [23, Color.WHITE]],
		BODY_ROT: [[0, -1.571], [14, 0.0]],
		BODY_POS: [[0, Vector2(0, -12)], [14, BODY]],
	})
	b.add("getup_attack", 34, false, {
		BODY_ROT: [[0, -1.571], [10, -1.571], [16, 0.0]],
		BODY_POS: [[0, Vector2(0, -12)], [16, BODY]],
		SPEAR_ARM: [[0, ARM_IDLE], [14, ARM_UP], [16, ARM_FWD], [20, 1.4], [34, ARM_IDLE]],
		SPEAR: [[0, SPEAR_IDLE], [14, 0.0], [20, 0.0], [34, SPEAR_IDLE]],
		RIG_TINT: [[0, GHOST], [15, GHOST], [16, Color.WHITE]],
	})

	# --- Ledge / recovery -------------------------------------------------------------
	b.add("ledge_hang", 1, false, {
		BODY_POS: Vector2(0, -28), SPEAR_ARM: -3.0, SPEAR: 3.2, SHIELD_ARM: -3.0,
		LEG_F: 0.2, LEG_B: -0.1, CAPE: 0.3,
	})
	b.add("ledge_climb", 28, false, {
		RIG_TINT: [[0, GHOST], [24, GHOST], [25, Color.WHITE]],
		BODY_POS: [[0, Vector2(0, -28)], [12, BODY]],
		RIG_SCALE: [[0, Vector2.ONE], [12, Vector2(1.1, 0.85)], [20, Vector2.ONE]],
		SPEAR_ARM: [[0, -3.0], [12, ARM_IDLE]], SHIELD_ARM: [[0, -3.0], [12, 0.15]],
	})
	b.add("ledge_attack", 30, false, {
		SPEAR_ARM: [[0, ARM_IDLE], [8, -1.2], [10, ARM_FWD], [16, ARM_FWD], [30, ARM_IDLE]],
		SPEAR: [[0, SPEAR_IDLE], [8, 0.0], [16, 0.0], [30, SPEAR_IDLE]],
		SPEAR_POS: [[0, HAND], [10, Vector2(0, 26)], [16, Vector2(0, 26)], [30, HAND]],
		RIG_TINT: [[0, GHOST], [9, GHOST], [10, Color.WHITE]],
	})
	b.add("helpless", 30, true, {
		RIG_TINT: Color(0.65, 0.65, 0.8),
		BODY_ROT: [[0, -0.08], [15, 0.08], [30, -0.08]],
		SPEAR_ARM: [[0, -2.6], [15, -2.9], [30, -2.6]], SPEAR: 0.0,
		SHIELD_ARM: [[0, -2.9], [15, -2.6], [30, -2.9]],
		LEG_F: 0.3, LEG_B: -0.3, CAPE: -0.7,
	})
	return b.library

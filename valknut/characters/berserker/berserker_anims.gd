class_name BerserkerAnims
extends RefCounted
## Berserker's animations. Visuals come from his 128×128 frames
## (frames/berserker_*.png, packed in berserker_frames.tres); timing is keyed in frames
## to match berserker_moves.gd. Attacks use the sheet's startup → active → recovery
## frames with the active frame on the move's first hitbox frame; motion (hops, lunges,
## spins, squash) and SlashFX effects are layered on top.

## Pose track: names an animation in <legend>_frames.tres (one per pose / pose slot).
const FRAME := "Rig/Body/Sprite:animation"
const BODY_POS := "Rig/Body:position"
const BODY_ROT := "Rig/Body:rotation"
const RIG_SCALE := "Rig:scale"
const RIG_TINT := "Rig:modulate"

# Base poses (cut from the source sheet). Combo/heavy poses are named slots (pose_slots.py).
const IDLE := &"idle"
const WALK_1 := &"walk_01"
const WALK_2 := &"walk_02"
const WALK_3 := &"walk_03"
const WALK_4 := &"walk_04"
const JUMP := &"jump"
const FALL := &"fall"        ## the sheet has one jump/fall drawing; both names point to it
const HURT := &"hurt"
const STARTUP := &"attack_startup"
const ACTIVE := &"attack_active"      ## wide axe swing, slash arc and motion lines drawn in
const RECOVERY := &"attack_recovery"

## Cutout rig (art set "rig", berserker_rig_rig.tscn): the forearm + axe bone.
const ELBOW := "Rig/Body/ArtRig/Skeleton/Elbow:rotation"
## Elbow in Rig space (game px), from tools/build_berserker_rig.py.
const RIG_ELBOW := Vector2(22.5, -58.9)

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
static func strike(startup: int, active: int, recovery: int, back: int, end: StringName = IDLE, first: StringName = STARTUP) -> Array:
	var keys := [[startup, STARTUP], [active, ACTIVE], [recovery, RECOVERY], [back, end]]
	if startup > 0:
		keys.push_front([0, first])
	return keys


## `art` is the active art set (Fighter.art_set). Sets only add pose keys for their own
## drawings (tools/art_sets.py); every frame number stays the same, so gameplay can't
## change. Moves not listed keep their keys (each set's SpriteFrames defines them all).
static func build(art: StringName = &"") -> AnimationLibrary:
	var v2 := art == &"v2"
	var cutout := art == &"rig"
	var full := art == &"fullrig"
	var defaults := SlashFX.with(DEFAULT_POSE, SlashFX.default_tracks())
	if cutout:
		defaults[ELBOW] = 0.0
	if full:
		defaults.merge(_full_defaults(), true)
	var b := AnimBuilder.new(defaults)

	# --- Movement: heavy, stompy ---------------------------------------------------------
	b.add("idle", 60, true, _full_idle() if full else _rig_idle() if cutout else {
		# v2: three breathing drawings over the same procedural bob.
		FRAME: [[0, &"idle_01"], [15, &"idle_02"], [30, &"idle_03"], [45, &"idle_02"]] if v2 else IDLE,
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

	# --- Neutral combo: Right Axe → Left Axe → Double-Axe Overhead -------------------------
	# Anticipation → smear → contact (first hitbox frame) → follow-through per hit; the
	# right-axe follow-through already cocks the left axe, the left-axe follow-through
	# starts raising both, so the string never passes through idle. Poses are named slots
	# (tools/pose_slots.py); undrawn ones show placeholders (F1 debug view). Motion is
	# only weight transfer and the finisher's hop — the swings come from the drawings.
	b.add("jab1", 20, false, _full_jab1() if full else _rig_jab1() if cutout else {
		FRAME: [[0, &"light_anticipation"], [3, &"light_smear"], [4, &"light_contact"], [8, &"light_recovery"],
			[15, &"light_settle"], [18, IDLE]] if v2 else
			[[0, &"right_anticipation"], [3, &"right_smear"], [4, &"right_contact"], [8, &"right_follow"],
			[15, RECOVERY], [18, IDLE]],
		BODY_POS: [[0, BODY + Vector2(-3, 1)], [4, BODY + Vector2(5, 0)], [14, BODY]],
	})
	b.add("jab2", 22, false, {
		FRAME: [[0, &"left_anticipation"], [4, &"left_smear"], [5, &"left_contact"], [9, &"left_follow"],
			[17, RECOVERY], [20, IDLE]],
		BODY_POS: [[0, BODY], [5, BODY + Vector2(6, 0)], [16, BODY + Vector2(4, 0)], [22, BODY]],
	})
	b.add("jab3", 46, false, SlashFX.with({
		FRAME: [[0, &"overhead_windup"], [7, &"overhead_smear"], [8, &"overhead_contact"], [12, &"overhead_impact"],
			[34, RECOVERY], [42, IDLE]],
		BODY_POS: [[0, BODY], [4, BODY + Vector2(0, -8)], [7, BODY + Vector2(2, -4)], [8, BODY + Vector2(6, 2)],
			[30, BODY + Vector2(6, 2)], [46, BODY]],
	}, SlashFX.ring(Vector2(48, -4), 40, 10, RED, 8, 16, 0.5, 0.25)))  # ground impact shockwave

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
		# Heavy axe: its own deep wind-up, a held charge pose, a full-body sweep and an
		# overcommitted recovery. Charge holds on frame 12 (heavy_charge).
		FRAME: [[0, &"heavy_windup"], [8, &"heavy_charge"], [18, &"heavy_smear"], [20, &"heavy_contact"],
			[30, &"heavy_recovery"], [54, IDLE]],
		BODY_POS: [[0, BODY], [12, BODY + Vector2(-12, 4)], [20, BODY + Vector2(12, 0)], [40, BODY + Vector2(12, 0)], [64, BODY]],
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


## Cutout rig idle: the same procedural breathing as the sprites, plus the axe arm
## swaying a few degrees with each breath. Feet stay planted (Rig scales from them).
static func _rig_idle() -> Dictionary:
	return {
		BODY_POS: [[0, BODY], [30, BODY + Vector2(0, 2)], [60, BODY]],
		RIG_SCALE: [[0, Vector2.ONE], [30, Vector2(1.015, 0.98)], [60, Vector2.ONE]],
		ELBOW: _eased([[0, 0.0], [30, deg_to_rad(-3.0)], [60, 0.0]]),
	}


## Cutout rig light attack (jab1, 20 frames, hit on 4-5): a compact hatchet chop from
## the elbow. Cock the axe up beside the head (0-2), whip it down through a smear arc
## (3) to contact out in front at elbow height (4, held through hitlag), carry it on
## past the hip (8-11) and settle back to idle (11-19). Weight: a squash into the
## cock and a stretch through the chop, scaled from the feet so they never slide.
static func _rig_jab1() -> Dictionary:
	return SlashFX.with({
		ELBOW: _eased([[0, 0.0], [2, deg_to_rad(-140.0)], [3, deg_to_rad(-100.0)], [4, deg_to_rad(-55.0)],
			[7, deg_to_rad(-50.0)], [11, deg_to_rad(18.0)], [15, deg_to_rad(6.0)], [19, 0.0]]),
		RIG_SCALE: [[0, Vector2.ONE], [2, Vector2(1.025, 0.97)], [4, Vector2(0.985, 1.02)], [11, Vector2(1.01, 0.99)],
			[18, Vector2.ONE]],
		BODY_POS: BODY,
	}, SlashFX.arc(RIG_ELBOW, 34, -125, 10, 9, Color(1, 1, 1), 3, 2, 3))


## Fills every frame between keys with smoothstep easing (AnimBuilder interpolates
## linearly), so rig motion accelerates and settles instead of moving robotically.
static func _eased(keys: Array) -> Array:
	var out := []
	for i in keys.size() - 1:
		var f0: int = keys[i][0]
		var f1: int = keys[i + 1][0]
		for f in range(f0, f1):
			var t := float(f - f0) / (f1 - f0)
			out.append([f, lerpf(keys[i][1], keys[i + 1][1], t * t * (3.0 - 2.0 * t))])
	out.append(keys[-1])
	return out


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


# --- Full-body cutout rig (art set "fullrig") --------------------------------------------
# Bone tracks, paths relative to the fighter's Visual node. Rest values come from
# berserker_fullrig_data.gd (generated by tools/build_berserker_fullrig.py).
const FR := preload("res://valknut/characters/berserker/berserker_fullrig_data.gd")
const SK := "Rig/Body/ArtRig/Skeleton/"
const P_HIPS := SK + "Hips"
const P_THIGH_L := SK + "Hips/ThighL"
const P_SHIN_L := SK + "Hips/ThighL/ShinL"
const P_THIGH_R := SK + "Hips/ThighR"
const P_SHIN_R := SK + "Hips/ThighR/ShinR"
const P_SPINE := SK + "Hips/Spine"
const P_CAPE := SK + "Hips/Cape"
const P_CHEST := SK + "Hips/Spine/Chest"
const P_NECK := SK + "Hips/Spine/Neck"
const P_SH_L := SK + "Hips/Spine/ShoulderL"
const P_EL_L := SK + "Hips/Spine/ShoulderL/ElbowL"
const P_AX_L := SK + "Hips/Spine/ShoulderL/ElbowL/AxeL"
const P_SH_R := SK + "Hips/Spine/ShoulderR"
const P_EL_R := SK + "Hips/Spine/ShoulderR/ElbowR"
const P_AX_R := SK + "Hips/Spine/ShoulderR/ElbowR/AxeR"


## Every bone at rest, so moves the rig doesn't animate hold the idle pose.
static func _full_defaults() -> Dictionary:
	var d := {}
	for p in [P_HIPS, P_THIGH_L, P_SHIN_L, P_THIGH_R, P_SHIN_R, P_SPINE, P_CAPE, P_NECK, P_SH_L, P_EL_L,
			P_AX_L, P_SH_R, P_EL_R, P_AX_R]:
		d[p + ":rotation"] = 0.0
	d[P_CHEST + ":scale"] = Vector2.ONE
	d[P_HIPS + ":position"] = FR.POS_HIPS
	d[P_SH_L + ":position"] = FR.POS_SHOULDERL
	d[P_SH_R + ":position"] = FR.POS_SHOULDERR
	d[P_NECK + ":position"] = FR.POS_NECK
	return d


## Value of a keyed curve at frame `f`. Keys are [frame, value, mode?]; mode shapes the
## segment that ENDS at the key: "s" smoothstep (default), "i" ease-in (accelerating, for
## whips), "o" ease-out (decelerating, for impacts and settles), "l" linear.
static func _ease_at(keys: Array, f: float) -> float:
	if f <= keys[0][0]:
		return keys[0][1]
	for i in keys.size() - 1:
		var a: Array = keys[i]
		var b: Array = keys[i + 1]
		if f <= b[0]:
			var t: float = (f - float(a[0])) / float(b[0] - a[0])
			match (b[2] if b.size() > 2 else "s"):
				"i": t = t * t
				"o": t = 1.0 - (1.0 - t) * (1.0 - t)
				"l": pass
				_: t = t * t * (3.0 - 2.0 * t)
			return lerpf(a[1], b[1], t)
	return keys[-1][1]


## Two-bone leg IK that keeps the boot's ground point exactly where it is at rest while
## the hips move and turn. Returns Vector2(thigh rotation, shin rotation), bone-local, in
## radians. The knee always bends to the same side as at rest. When the hips are moved
## out of reach of the leg, the foot is pulled to the nearest reachable point (the
## caller keeps hip offsets small enough that this never happens in jab1).
static func _leg_ik(hips_pos: Vector2, hips_rot: float, thigh: Vector2, knee: Vector2, foot: Vector2) -> Vector2:
	var target: Vector2 = FR.POS_HIPS + thigh + knee + foot
	var hip := Transform2D(hips_rot, hips_pos) * thigh
	var l1 := knee.length()
	var l2 := foot.length()
	var to := target - hip
	var d := clampf(to.length(), absf(l1 - l2) + 0.01, l1 + l2 - 0.01)
	var u := to.normalized()
	var a := (l1 * l1 - l2 * l2 + d * d) / (2.0 * d)
	var h := sqrt(maxf(l1 * l1 - a * a, 0.0))
	var side := signf((foot + knee).cross(knee))
	var k := hip + u * a + Vector2(-u.y, u.x) * h * side
	var thigh_world := (k - hip).angle() - knee.angle()
	var shin_world := (target - k).angle() - foot.angle()
	return Vector2(wrapf(thigh_world - hips_rot, -PI, PI), wrapf(shin_world - thigh_world, -PI, PI))


## Samples the pose curves `pp` (name → keys) every frame and turns them into bone tracks.
## Angles are degrees, offsets canvas px (+x forward, +y down). The legs come from IK so
## the feet stay planted whatever the hips do; the cape swings on a lag behind the spine.
static func _full_tracks(pp: Dictionary, frames: int) -> Dictionary:
	var t := {}
	for p in [P_HIPS, P_THIGH_L, P_SHIN_L, P_THIGH_R, P_SHIN_R, P_SPINE, P_CAPE, P_NECK, P_SH_L, P_EL_L,
			P_AX_L, P_SH_R, P_EL_R, P_AX_R]:
		t[p + ":rotation"] = []
	for p in [P_CHEST + ":scale", P_HIPS + ":position", P_SH_L + ":position", P_SH_R + ":position",
			P_NECK + ":position"]:
		t[p] = []
	var g := func(name: String, f: float) -> float:
		return _ease_at(pp[name], f) if pp.has(name) else 0.0
	for f in range(frames + 1):
		var hp: Vector2 = FR.POS_HIPS + Vector2(g.call("hip_x", f), g.call("hip_y", f))
		var hr := deg_to_rad(g.call("hip_rot", f))
		t[P_HIPS + ":position"].append([f, hp])
		t[P_HIPS + ":rotation"].append([f, hr])
		var ikl := _leg_ik(hp, hr, FR.THIGH_L, FR.KNEE_L, FR.FOOT_L)
		var ikr := _leg_ik(hp, hr, FR.THIGH_R, FR.KNEE_R, FR.FOOT_R)
		t[P_THIGH_L + ":rotation"].append([f, ikl.x])
		t[P_SHIN_L + ":rotation"].append([f, ikl.y])
		t[P_THIGH_R + ":rotation"].append([f, ikr.x])
		t[P_SHIN_R + ":rotation"].append([f, ikr.y])
		var sp: float = g.call("spine", f)
		t[P_SPINE + ":rotation"].append([f, deg_to_rad(sp)])
		t[P_CAPE + ":rotation"].append([f, deg_to_rad(0.45 * (g.call("hip_x", f) - g.call("hip_x", maxf(f - 3.0, 0.0))))])
		t[P_CHEST + ":scale"].append([f, Vector2(1.0 + g.call("chest_sx", f), 1.0)])
		t[P_NECK + ":rotation"].append([f, deg_to_rad(g.call("neck", f))])
		t[P_NECK + ":position"].append([f, FR.POS_NECK + Vector2(g.call("neck_x", f), 0.0)])
		t[P_SH_L + ":position"].append([f, FR.POS_SHOULDERL + Vector2(g.call("shL_x", f), 0.0)])
		t[P_SH_R + ":position"].append([f, FR.POS_SHOULDERR + Vector2(g.call("shR_x", f), 0.0)])
		t[P_SH_L + ":rotation"].append([f, deg_to_rad(g.call("shL", f))])
		t[P_EL_L + ":rotation"].append([f, deg_to_rad(g.call("elL", f))])
		t[P_AX_L + ":rotation"].append([f, deg_to_rad(g.call("wrL", f))])
		t[P_SH_R + ":rotation"].append([f, deg_to_rad(g.call("shR", f))])
		t[P_EL_R + ":rotation"].append([f, deg_to_rad(g.call("elR", f))])
		t[P_AX_R + ":rotation"].append([f, deg_to_rad(g.call("wrR", f))])
	return t


## Full-body idle: the same procedural-feeling breathing as the sprites, done with the
## skeleton (chest swell, shoulders and head easing, hips settling). Feet stay planted.
static func _full_idle() -> Dictionary:
	var pp := {
		"hip_y": [[0, 0.0], [30, 0.5, "s"], [60, 0.0, "s"]],
		"spine": [[0, 0.0], [30, -0.5, "s"], [60, 0.0, "s"]],
		"chest_sx": [[0, 0.0], [30, 0.012, "s"], [60, 0.0, "s"]],
		"neck": [[0, 0.0], [30, 0.5, "s"], [60, 0.0, "s"]],
		"shR": [[0, 0.0], [30, 1.2, "s"], [60, 0.0, "s"]],
		"shL": [[0, 0.0], [30, -1.2, "s"], [60, 0.0, "s"]],
	}
	var t := _full_tracks(pp, 60)
	t[RIG_SCALE] = [[0, Vector2.ONE]]
	t[BODY_POS] = [[0, BODY]]
	return t


## Full-body light attack (jab1, 20 frames; the hit is on frames 4-5). The whole body
## works: weight rocks back and the torso coils away with the axe cocked up (0-2), then
## the hips drive forward and drop into a deeper stance as the torso unwinds and the
## front shoulder whips the axe down through a smear (3) to contact (4, held through
## hitlag), the follow-through carries on and low (8-11) and the body settles back to
## idle (12-19). Hips lead, then chest, then shoulder, then wrist.
static func _full_jab1() -> Dictionary:
	var pp := {
		"hip_x": [[0, -3.0], [2, -7.5, "o"], [4, 9.0, "l"], [8, 10.0, "o"], [12, 5.0], [16, 1.5], [19, 0.0, "o"]],
		"hip_y": [[0, 1.5], [2, 5.0, "o"], [4, 7.0, "l"], [8, 7.0], [12, 4.0], [16, 1.0], [19, 0.0, "o"]],
		"hip_rot": [[0, -1.0], [2, -3.0, "o"], [4, 5.0, "l"], [8, 5.0], [12, 3.0], [19, 0.0, "o"]],
		"spine": [[0, -3.0], [2, -11.0, "o"], [4, 12.0, "l"], [8, 12.0], [12, 8.0], [16, 3.0], [19, 0.0, "o"]],
		"chest_sx": [[0, -0.02], [2, -0.07, "o"], [4, 0.03, "l"], [8, 0.03], [12, 0.01], [19, 0.0, "o"]],
		"neck": [[0, 1.0], [2, 6.0, "o"], [4, -8.0, "l"], [8, -8.0], [12, -4.0], [19, 0.0, "o"]],
		"neck_x": [[0, -1.0], [2, -3.0, "o"], [4, 3.0, "l"], [8, 3.0], [12, 1.0], [19, 0.0, "o"]],
		"shR_x": [[0, -3.0], [2, -9.0, "o"], [4, 8.0, "l"], [8, 8.0], [12, 4.0], [19, 0.0, "o"]],
		"shL_x": [[0, 2.0], [2, 6.0, "o"], [4, -5.0, "l"], [8, -5.0], [12, -2.0], [19, 0.0, "o"]],
		"shR": [[0, -40.0], [2, -150.0, "o"], [4, -80.0, "l"], [8, -76.0, "o"], [12, -25.0], [16, -6.0], [19, 0.0, "o"]],
		"elR": [[0, -5.0], [2, -12.0, "o"], [4, 4.0, "l"], [8, 6.0, "o"], [12, 12.0], [16, 3.0], [19, 0.0, "o"]],
		"wrR": [[0, 0.0], [2, -25.0, "o"], [4, 35.0, "l"], [8, 40.0, "o"], [12, 15.0], [19, 0.0, "o"]],
		"shL": [[0, 8.0], [2, 22.0, "o"], [4, -20.0, "l"], [8, -20.0], [12, -8.0], [19, 0.0, "o"]],
		"elL": [[0, 0.0], [2, 10.0, "o"], [4, -10.0, "l"], [8, -10.0], [12, -4.0], [19, 0.0, "o"]],
	}
	var t := _full_tracks(pp, 20)
	t[RIG_SCALE] = [[0, Vector2.ONE]]
	t[BODY_POS] = [[0, BODY]]
	return SlashFX.with(t, SlashFX.arc(Vector2(17.7, -73.2), 40, -105, 5, 7, Color(1, 1, 1), 3, 2, 3))

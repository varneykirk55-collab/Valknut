class_name ValkyrieMoves
extends RefCounted
## Valkyrie frame data. Offsets: +x = in front, -y = up, origin at her feet.
## HitboxData.make(start, end, offset, size, damage, angle, base_kb, growth)
##
## Combo design: jab1 → jab2 → jab3 is the only string; jab3 ends in real endlag.
## Down tilt pops up (80°) for a short jump confirm into neutral/forward air at low
## percent, then hitstun stops covering the gap — back to neutral.


static func build(v: Valkyrie) -> Dictionary:
	var m := {}

	# --- Jab string ---------------------------------------------------------------
	var jab1 := MoveData.make("jab1", 18)
	jab1.grounded = true
	jab1.land_cancels = false
	jab1.chain_to = "jab2"
	jab1.chain_from = 7
	jab1.hit(HitboxData.make(3, 4, Vector2(44, -58), Vector2(46, 18), 3, 70, 25, 20))
	m[jab1.id] = jab1

	var jab2 := MoveData.make("jab2", 20)  # shield bash
	jab2.grounded = true
	jab2.land_cancels = false
	jab2.chain_to = "jab3"
	jab2.chain_from = 8
	jab2.hit(HitboxData.make(4, 5, Vector2(30, -50), Vector2(36, 38), 3, 60, 25, 20))
	m[jab2.id] = jab2

	var jab3 := MoveData.make("jab3", 34)  # two-handed thrust finisher
	jab3.grounded = true
	jab3.land_cancels = false
	jab3.velocity_keys = {5: Vector2(200, 0)}
	jab3.hit(HitboxData.make(7, 9, Vector2(64, -54), Vector2(64, 20), 6, 40, 50, 70))
	m[jab3.id] = jab3

	# --- Tilts --------------------------------------------------------------------
	var ftilt := MoveData.make("ftilt", 30)  # long spear poke
	ftilt.grounded = true
	ftilt.land_cancels = false
	ftilt.turn_on_start = true
	ftilt.hit(HitboxData.make(8, 10, Vector2(78, -54), Vector2(30, 18), 10, 35, 30, 90))  # tip
	ftilt.hit(HitboxData.make(8, 10, Vector2(42, -54), Vector2(44, 18), 8, 35, 30, 85))
	m[ftilt.id] = ftilt

	var dtilt := MoveData.make("dtilt", 20)  # low sweep, pops up
	dtilt.grounded = true
	dtilt.land_cancels = false
	dtilt.hit(HitboxData.make(6, 8, Vector2(66, -10), Vector2(64, 18), 6, 80, 40, 50))
	m[dtilt.id] = dtilt

	# --- Smashes (hold to charge) ---------------------------------------------------
	var fsmash := MoveData.make("fsmash", 52)  # lunging thrust
	fsmash.grounded = true
	fsmash.land_cancels = false
	fsmash.turn_on_start = true
	fsmash.charge_frame = 9
	fsmash.velocity_keys = {10: Vector2(420, 0)}
	fsmash.hit(HitboxData.make(14, 17, Vector2(88, -54), Vector2(30, 22), 16, 361, 35, 100))
	fsmash.hit(HitboxData.make(14, 17, Vector2(52, -54), Vector2(44, 22), 14, 361, 32, 95))
	m[fsmash.id] = fsmash

	var dsmash := MoveData.make("dsmash", 48)  # sweep front, then back
	dsmash.grounded = true
	dsmash.land_cancels = false
	dsmash.charge_frame = 6
	dsmash.hit(HitboxData.make(10, 13, Vector2(48, -14), Vector2(70, 24), 13, 30, 30, 95).away())
	dsmash.hit(HitboxData.make(18, 21, Vector2(-48, -14), Vector2(70, 24), 12, 30, 30, 95).away())
	m[dsmash.id] = dsmash

	# --- Aerials ------------------------------------------------------------------
	var nair := MoveData.make("nair", 38)  # shield spin
	nair.landing_lag = 8
	nair.autocancel_from = 3
	nair.autocancel_to = 30
	nair.hit(HitboxData.make(5, 8, Vector2(0, -42), Vector2(86, 86), 9, 45, 25, 75).away())
	nair.hit(HitboxData.make(9, 20, Vector2(0, -42), Vector2(80, 80), 5, 45, 20, 60).away())
	m[nair.id] = nair

	var fair := MoveData.make("fair", 36)  # rising spear thrust: edgeguard + kill move
	fair.landing_lag = 10
	fair.autocancel_from = 4
	fair.autocancel_to = 28
	fair.turn_on_start = true
	fair.hit(HitboxData.make(7, 10, Vector2(80, -68), Vector2(32, 24), 12, 40, 25, 95))  # tip
	fair.hit(HitboxData.make(7, 10, Vector2(46, -60), Vector2(40, 22), 9, 45, 20, 85))
	m[fair.id] = fair

	var dair := MoveData.make("dair", 44)  # downward stab; tip spikes
	dair.landing_lag = 14
	dair.autocancel_from = 3
	dair.autocancel_to = 38
	dair.hit(HitboxData.make(12, 15, Vector2(6, 34), Vector2(24, 26), 13, 270, 20, 80).with_hitlag(1.3))
	dair.hit(HitboxData.make(12, 15, Vector2(6, 4), Vector2(28, 34), 9, 60, 30, 60))
	m[dair.id] = dair

	# --- Specials -------------------------------------------------------------------
	# Neutral/up special — Wings of Valhalla: a rising flap, then hover while special is
	# held. Ends helpless. Her main recovery.
	var hover := MoveData.make("nspecial", 80)
	hover.once_per_air = true
	hover.ends_helpless = true
	hover.helpless_landing_lag = 18
	hover.landing_lag = 10
	hover.autocancel_from = 1
	hover.gravity_scale = 0.0
	hover.drift = 0.9
	hover.allow_fast_fall = false
	hover.can_grab_ledge_from = 14
	hover.on_frame = v.hover_tick
	hover.hit(HitboxData.make(7, 14, Vector2(0, -50), Vector2(60, 66), 6, 85, 60, 40))
	m[hover.id] = hover

	# Side special — Shield Charge: horizontal dash, stops on hit. Not helpless.
	var charge := MoveData.make("sspecial", 44)
	charge.once_per_air = true
	charge.land_cancels = false
	charge.turn_on_start = true
	charge.gravity_scale = 0.0
	charge.drift = 0.0
	charge.allow_fast_fall = false
	charge.can_grab_ledge_from = 20
	charge.on_frame = v.shield_charge_tick
	charge.on_hit = v.shield_charge_hit
	charge.hit(HitboxData.make(9, 24, Vector2(30, -44), Vector2(40, 60), 8, 40, 60, 50))
	m[charge.id] = charge

	# Down special — Spear Dive (signature): hop, then dive at 60° down-forward. Spikes
	# airborne targets and bounces her back up on hit. Whiff it off-stage and you fall.
	var dive := MoveData.make("dspecial", 40)
	dive.once_per_air = true
	dive.ends_helpless = true
	dive.helpless_landing_lag = 22
	dive.landing_lag = 22
	dive.autocancel_from = 1
	dive.gravity_scale = 0.0
	dive.drift = 0.0
	dive.allow_fast_fall = false
	dive.on_frame = v.spear_dive_tick
	dive.on_hit = v.spear_dive_hit
	dive.hit(HitboxData.make(11, 16, Vector2(24, -12), Vector2(46, 46), 13, 290, 35, 70).with_hitlag(1.2))
	dive.hit(HitboxData.make(17, 40, Vector2(24, -12), Vector2(44, 44), 10, 290, 30, 65))
	m[dive.id] = dive

	return m

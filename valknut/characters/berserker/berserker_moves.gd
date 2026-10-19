class_name BerserkerMoves
extends RefCounted
## Berserker frame data. Offsets: +x = in front, -y = up, origin at his feet.
## HitboxData.make(start, end, offset, size, damage, angle, base_kb, growth)
##
## Compared to the Valkyrie: every move starts later and ends later, but hits harder
## and launches further. Grounded moves are his strength; aerials are slow with big
## landing lag. Smashes carry a little extra hitlag so the hits feel heavy.


static func build(b: Berserker) -> Dictionary:
	var m := {}

	# --- Neutral combo: Right Axe → Left Axe → Double-Axe Overhead -------------------------
	# Original jab damage/angles/knockback. Hitboxes follow the new swing paths: two
	# diagonal cuts, then an overhead chop that covers from above his head to the floor.
	var jab1 := MoveData.make("jab1", 20)  # right axe, diagonal
	jab1.grounded = true
	jab1.land_cancels = false
	jab1.chain_to = "jab2"
	jab1.chain_from = 9
	jab1.hit(HitboxData.make(4, 5, Vector2(42, -52), Vector2(50, 40), 4, 70, 30, 25).with_sfx("axe_light"))
	m[jab1.id] = jab1

	var jab2 := MoveData.make("jab2", 22)  # left axe, carrying the first swing's momentum
	jab2.grounded = true
	jab2.land_cancels = false
	jab2.chain_to = "jab3"
	jab2.chain_from = 10
	jab2.velocity_keys = {2: Vector2(120, 0)}
	jab2.hit(HitboxData.make(5, 6, Vector2(40, -44), Vector2(50, 40), 4, 65, 30, 25).with_sfx("axe_light"))
	m[jab2.id] = jab2

	# Overhead finisher. Recovery is 6 frames longer than the old jab3 (40 → 46): the
	# brief asks for a noticeably committed finisher (reported as a frame-data change).
	var jab3 := MoveData.make("jab3", 46)
	jab3.grounded = true
	jab3.land_cancels = false
	jab3.velocity_keys = {6: Vector2(160, 0)}
	jab3.swing_sfx = "swing_heavy"
	jab3.hit(HitboxData.make(8, 10, Vector2(48, -46), Vector2(62, 84), 8, 40, 60, 85)
		.with_hitlag(1.15).with_sfx("axe_heavy"))
	m[jab3.id] = jab3

	# --- Tilts ----------------------------------------------------------------------
	var ftilt := MoveData.make("ftilt", 38)  # wide horizontal sweep
	ftilt.grounded = true
	ftilt.land_cancels = false
	ftilt.turn_on_start = true
	ftilt.hit(HitboxData.make(10, 13, Vector2(58, -50), Vector2(84, 36), 13, 361, 40, 95).with_hitlag(1.1))
	m[ftilt.id] = ftilt

	var dtilt := MoveData.make("dtilt", 30)  # low shin sweep, sends low and away
	dtilt.grounded = true
	dtilt.land_cancels = false
	dtilt.hit(HitboxData.make(8, 10, Vector2(54, -12), Vector2(76, 24), 10, 25, 45, 80))
	m[dtilt.id] = dtilt

	# --- Smashes ----------------------------------------------------------------------
	var fsmash := MoveData.make("fsmash", 64)  # double sweep, the big one
	fsmash.grounded = true
	fsmash.land_cancels = false
	fsmash.turn_on_start = true
	fsmash.charge_frame = 12
	fsmash.velocity_keys = {18: Vector2(260, 0)}
	fsmash.swing_sfx = "swing_heavy"
	fsmash.hit(HitboxData.make(20, 23, Vector2(64, -48), Vector2(98, 46), 20, 361, 35, 92)
		.with_hitlag(1.25).with_sfx("axe_heavy"))
	m[fsmash.id] = fsmash

	var dsmash := MoveData.make("dsmash", 58)  # stomp + both axes slam either side
	dsmash.grounded = true
	dsmash.land_cancels = false
	dsmash.charge_frame = 8
	dsmash.hit(HitboxData.make(16, 19, Vector2(50, -14), Vector2(80, 32), 19, 30, 40, 100).away().with_hitlag(1.2))
	dsmash.hit(HitboxData.make(16, 19, Vector2(-50, -14), Vector2(80, 32), 19, 30, 40, 100).away().with_hitlag(1.2))
	m[dsmash.id] = dsmash

	# --- Aerials (slow, heavy landing lag) ------------------------------------------
	var nair := MoveData.make("nair", 44)  # spinning double-axe swipe
	nair.landing_lag = 12
	nair.autocancel_from = 4
	nair.autocancel_to = 36
	nair.hit(HitboxData.make(8, 11, Vector2(0, -46), Vector2(100, 92), 12, 45, 30, 90).away())
	nair.hit(HitboxData.make(12, 20, Vector2(0, -46), Vector2(92, 86), 7, 45, 25, 70).away())
	m[nair.id] = nair

	var fair := MoveData.make("fair", 46)  # overhead chop; bottom of the arc spikes
	fair.landing_lag = 16
	fair.autocancel_from = 4
	fair.autocancel_to = 38
	fair.turn_on_start = true
	fair.hit(HitboxData.make(12, 13, Vector2(52, -74), Vector2(50, 40), 13, 45, 30, 95))
	fair.hit(HitboxData.make(14, 15, Vector2(50, -26), Vector2(50, 42), 15, 285, 30, 85).with_hitlag(1.3))
	m[fair.id] = fair

	var dair := MoveData.make("dair", 54)  # both axes straight down: strongest spike
	dair.landing_lag = 22
	dair.autocancel_from = 4
	dair.autocancel_to = 46
	dair.hit(HitboxData.make(16, 19, Vector2(4, 12), Vector2(54, 32), 16, 270, 30, 90).with_hitlag(1.4))
	dair.hit(HitboxData.make(16, 19, Vector2(4, -22), Vector2(58, 34), 11, 60, 35, 70))
	m[dair.id] = dair

	# --- Specials -----------------------------------------------------------------------
	# Neutral/up special — Skull Leap: short hop with both axes raised. Weak recovery,
	# ends helpless with long landing lag.
	var leap := MoveData.make("nspecial", 40)
	leap.once_per_air = true
	leap.ends_helpless = true
	leap.helpless_landing_lag = 26
	leap.landing_lag = 20
	leap.autocancel_from = 9
	leap.drift = 0.5
	leap.allow_fast_fall = false
	leap.can_grab_ledge_from = 12
	leap.on_frame = b.leap_tick
	leap.hit(HitboxData.make(8, 14, Vector2(0, -64), Vector2(64, 56), 9, 80, 60, 60))
	m[leap.id] = leap

	# Side special — Cleaving Lunge: long wind-up, then a lunging double-axe strike.
	var lunge := MoveData.make("sspecial", 52)
	lunge.once_per_air = true
	lunge.land_cancels = false
	lunge.turn_on_start = true
	lunge.gravity_scale = 0.0
	lunge.drift = 0.0
	lunge.allow_fast_fall = false
	lunge.can_grab_ledge_from = 18
	lunge.on_frame = b.lunge_tick
	lunge.on_hit = b.lunge_hit
	lunge.hit(HitboxData.make(14, 21, Vector2(42, -48), Vector2(62, 58), 16, 40, 50, 95).with_hitlag(1.2))
	m[lunge.id] = lunge

	# Down special — Rage Spin (signature): spinning axes, linked multi-hits into a
	# launching finisher, then a long exhausted endlag where he's wide open. The link
	# hits pop the victim up and slightly *toward* him (100° away = inward) so the
	# spin keeps them until the finisher.
	var spin := MoveData.make("dspecial", 90)
	spin.once_per_air = true
	spin.land_cancels = false
	spin.gravity_scale = 0.0
	spin.drift = 0.0
	spin.allow_fast_fall = false
	spin.on_frame = b.rage_spin_tick
	spin.hit(HitboxData.make(9, 48, Vector2(0, -46), Vector2(112, 72), 2, 100, 0, 100)
		.with_set_kb(20).with_rehit(6).as_link().away())
	spin.hit(HitboxData.make(49, 52, Vector2(0, -46), Vector2(120, 78), 7, 361, 70, 90).away().with_hitlag(1.2).in_group(1))
	m[spin.id] = spin

	return m

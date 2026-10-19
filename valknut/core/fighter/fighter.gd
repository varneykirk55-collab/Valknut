class_name Fighter
extends CharacterBody2D
## Base class for every legend.
##
## The Match calls tick() once per physics frame for every fighter, then runs the
## CombatResolver, so all fighters move before any hit is checked. A legend subclass
## supplies its stats, move list (build_moves) and animations (build_animations); all
## shared behaviour — movement, hitstun, DI, teching, ledges — lives here and in states/.
##
## Coordinates: the fighter's origin is at its feet. Moves are authored facing right.

signal damaged(fighter: Fighter, amount: float)
signal launched(fighter: Fighter, kb: float)
signal knocked_out(fighter: Fighter)

const DT := 1.0 / 60.0
const NORMAL_LANDING_LAG := 4
const PLATFORM_DROP_FRAMES := 14
const LEDGE_REGRAB_FRAMES := 30
const LEDGE_INVULN_FRAMES := 30
const RESPAWN_INVULN_FRAMES := 120
## A dodge press up to this many frames before hitting the ground/wall techs it…
const TECH_WINDOW := 20
## …but after a press you can't try again for this long, so mashing doesn't work.
const TECH_LOCKOUT := 40
const PLATFORM_LAYER := 2

const STATES := {
	&"idle": preload("states/idle_state.gd"),
	&"walk": preload("states/walk_state.gd"),
	&"dash": preload("states/dash_state.gd"),
	&"run": preload("states/run_state.gd"),
	&"crouch": preload("states/crouch_state.gd"),
	&"jump_squat": preload("states/jump_squat_state.gd"),
	&"air": preload("states/air_state.gd"),
	&"land": preload("states/land_state.gd"),
	&"attack": preload("states/attack_state.gd"),
	&"dodge": preload("states/dodge_state.gd"),
	&"air_dodge": preload("states/air_dodge_state.gd"),
	&"hurt": preload("states/hurt_state.gd"),
	&"tumble": preload("states/tumble_state.gd"),
	&"tech": preload("states/tech_state.gd"),
	&"knockdown": preload("states/knockdown_state.gd"),
	&"ledge_hang": preload("states/ledge_hang_state.gd"),
	&"ledge_action": preload("states/ledge_action_state.gd"),
	&"helpless": preload("states/helpless_state.gd"),
	&"dead": preload("states/dead_state.gd"),
	&"respawn": preload("states/respawn_state.gd"),
}

@export var stats: FighterStats

var player_index := 1
var input: PlayerInput
var stage: Stage
var facing := 1
var percent := 0.0
var stocks := 0
var alive := true
var tag_color := Color.WHITE

## Own velocity: walking, jumping, gravity, drift.
var vel := Vector2.ZERO
## Launch velocity from the last hit. Decays by itself (Knockback.LAUNCH_DECAY) while
## gravity keeps acting on `vel`, which is what gives launches their arc.
var kb_velocity := Vector2.ZERO
var fast_falling := false
var air_jumps_left := 0
var air_dodge_available := true
var ledge_cooldown := 0
var ledge_invuln_available := true
var platform_drop_frames := 0
var invuln_frames := 0
var frame := 0

## Freeze frames left (both attacker and victim freeze on contact).
var hitlag := 0
## Launch waiting for hitlag to finish, so DI can be read on the last frozen frame.
var pending_launch := {}
## Consecutive hits taken without escaping hitstun (drives combo decay).
var combo_count := 0
var tech_press_frame := -100000
var tech_lockout_until := -100000

## Collision results of the last move_body().
var landed := false
var hit_wall := false
var hit_ceiling := false
var wall_normal := Vector2.ZERO
var impact_velocity := Vector2.ZERO
var on_platform := false

var moves := {}
var current_move: MoveData
var move_frame := 0
## Damage multiplier of the current move (smash charge).
var charge_mult := 1.0
## Button that started the current move; holding it charges smash attacks.
var charge_button := "attack"
## Freezes the AnimationPlayer (smash charge hold).
var anim_hold := false

var sm := FighterStateMachine.new()
var _used_air_moves := {}
var _hit_registry := {}
var _hitbox_pool: Array[Hitbox] = []
var _overlay := Node2D.new()

@onready var visual: Node2D = $Visual
@onready var rig: Node2D = $Visual/Rig
@onready var anim: AnimationPlayer = $Visual/AnimationPlayer
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox_root: Node2D = $Hitboxes


## Called by the Match before the fighter enters the tree.
func setup(p_index: int, p_input: PlayerInput, p_stage: Stage) -> void:
	player_index = p_index
	input = p_input
	stage = p_stage


func _ready() -> void:
	set_physics_process(false)
	if stats == null:
		stats = FighterStats.new()
	if input == null:
		input = PlayerInput.new(player_index)
	floor_snap_length = 12.0
	floor_max_angle = deg_to_rad(50)
	collision_layer = 1 << 2
	collision_mask = 0b11
	moves = build_moves()
	_add_shared_moves()
	anim.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	anim.add_animation_library(&"", build_animations())
	_overlay.z_index = 20
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)
	apply_palette(Palette.PLAYER_COLORS.get(player_index, Palette.PLAYER_COLORS[1]))
	for state_name in STATES:
		sm.add(state_name, STATES[state_name].new(), self)
	air_jumps_left = stats.air_jumps
	sm.change(&"idle")


func _notification(what: int) -> void:
	# States and the state machine reference each other; break the cycle on free.
	if what == NOTIFICATION_PREDELETE:
		sm.states.clear()
		sm.current = null


# --- Overridable legend hooks -------------------------------------------------------

## Return {move_id: MoveData}. Expected ids: jab1.., ftilt, dtilt, fsmash, dsmash,
## nair, fair, dair, plus whatever get_special() returns.
func build_moves() -> Dictionary:
	return {}


func build_animations() -> AnimationLibrary:
	return AnimationLibrary.new()


## dir: 4-way stick direction (y = 1 is down).
func get_special(dir: Vector2i, _grounded: bool) -> String:
	if dir.y > 0:
		return "dspecial"
	if dir.x != 0:
		return "sspecial"
	return "nspecial"


func get_ground_attack(dir: Vector2i, strong: bool) -> String:
	if dir.y > 0:
		return "dsmash" if strong else "dtilt"
	if dir.x != 0:
		return "fsmash" if strong else "ftilt"
	return "fsmash" if strong else "jab1"


func get_aerial(dir: Vector2i) -> String:
	if dir.y > 0:
		return "dair"
	if dir.x != 0:
		return "fair"
	return "nair"


# --- Main tick -------------------------------------------------------------------------

func tick() -> void:
	frame += 1
	input.poll(hitlag > 0)
	if hitlag > 0:
		hitlag -= 1
		# Only the victim shakes; the shake sells the impact and reminds you to DI.
		if not pending_launch.is_empty():
			visual.position = Vector2(randf_range(-3, 3), randf_range(-2, 2))
		if hitlag == 0:
			visual.position = Vector2.ZERO
			if not pending_launch.is_empty():
				_launch()
		_overlay.queue_redraw()
		return
	if invuln_frames > 0:
		invuln_frames -= 1
	if ledge_cooldown > 0:
		ledge_cooldown -= 1
	if platform_drop_frames > 0:
		platform_drop_frames -= 1
	set_collision_mask_value(PLATFORM_LAYER, platform_drop_frames == 0)
	_track_tech_input()
	sm.tick()
	_update_hitboxes()
	if not anim_hold:
		anim.advance(DT)
	_update_visual()


func _update_visual() -> void:
	visual.scale.x = facing
	var blink := invuln_frames > 0 and (frame / 4) % 2 == 0
	visual.modulate = Color(1, 1, 1, 0.45) if blink else Color.WHITE
	if anim_hold:
		# Smash charge glow.
		var pulse := 1.0 + 0.35 * absf(sin(frame * 0.4))
		visual.modulate = Color(pulse, pulse, pulse * 0.8)
	_overlay.queue_redraw()


# --- Movement helpers (called by states) -------------------------------------------

func apply_gravity(scale := 1.0) -> void:
	if fast_falling:
		vel.y = stats.fast_fall_speed
		return
	vel.y = minf(vel.y + stats.gravity * scale * DT, maxf(stats.max_fall_speed, vel.y))


## Smash-style fast fall: tap down at or after the peak of a jump.
func check_fast_fall() -> void:
	if not fast_falling and vel.y > -120.0 and input.down_just_pressed():
		fast_falling = true


func air_drift(mult := 1.0) -> void:
	var target := input.x() * stats.air_speed if input.dir_x() != 0 else 0.0
	var faster_same_way := signf(vel.x) == signf(target) and absf(vel.x) > absf(target)
	if target == 0.0 or faster_same_way:
		# Keep momentum from runs/launches, only bleed it off slowly.
		vel.x = move_toward(vel.x, target, stats.air_friction * DT)
	else:
		vel.x = move_toward(vel.x, target, stats.air_accel * mult * DT)


func ground_friction(mult := 1.0) -> void:
	vel.x = move_toward(vel.x, 0.0, stats.ground_friction * mult * DT)


func ground_accelerate(target_speed: float) -> void:
	var accel := stats.ground_accel
	if signf(vel.x) != signf(target_speed):
		accel += stats.ground_friction
	vel.x = move_toward(vel.x, target_speed, accel * DT)


func move_body() -> void:
	var grounded_before := is_on_floor()
	var decay := Knockback.LAUNCH_DECAY * (Knockback.GROUND_DECAY_MULT if grounded_before else 1.0)
	kb_velocity = kb_velocity.move_toward(Vector2.ZERO, decay * DT)
	var wind := Vector2.ZERO
	if stage and not grounded_before:
		wind = stage.get_wind(global_position)
	impact_velocity = vel + kb_velocity
	velocity = impact_velocity + wind
	move_and_slide()

	landed = is_on_floor() and not grounded_before
	hit_wall = is_on_wall()
	hit_ceiling = is_on_ceiling()
	wall_normal = get_wall_normal() if hit_wall else Vector2.ZERO
	on_platform = false
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var collider := c.get_collider()
		if c.get_normal().y < -0.5 and collider is Node and (collider as Node).is_in_group("platform"):
			on_platform = true

	# Surfaces stop whatever part of both velocities pushes into them.
	if is_on_floor():
		vel.y = minf(vel.y, 0.0)
		kb_velocity.y = minf(kb_velocity.y, 0.0)
		fast_falling = false
		if sm.current_name != &"attack":
			refresh_air_options()
	if hit_ceiling:
		vel.y = maxf(vel.y, 0.0)
		kb_velocity.y = maxf(kb_velocity.y, 0.0)
	if hit_wall:
		if signf(vel.x) == -signf(wall_normal.x):
			vel.x = 0.0
		if signf(kb_velocity.x) == -signf(wall_normal.x):
			kb_velocity.x = 0.0


func refresh_air_options() -> void:
	air_jumps_left = stats.air_jumps
	air_dodge_available = true
	ledge_invuln_available = true
	_used_air_moves.clear()


func drop_through_platform() -> void:
	platform_drop_frames = PLATFORM_DROP_FRAMES
	set_collision_mask_value(PLATFORM_LAYER, false)
	vel.y = maxf(vel.y, 120.0)


func face(dir_x: int) -> void:
	if dir_x != 0:
		facing = dir_x


# --- Action selection --------------------------------------------------------------

## Everything you can do from a grounded actionable state. Returns true if a state change
## happened (the caller must stop processing).
func try_ground_actions() -> bool:
	if _try_special(true):
		return true
	if _try_ground_attack():
		return true
	if input.consume("dodge"):
		sm.change(&"dodge", {"dir": input.dir_x()})
		return true
	if input.consume("jump"):
		sm.change(&"jump_squat")
		return true
	if on_platform and input.down_just_pressed():
		drop_through_platform()
		sm.change(&"air")
		return true
	return false


func try_air_actions() -> bool:
	if _try_special(false):
		return true
	if _try_aerial():
		return true
	if air_dodge_available and input.consume("dodge"):
		sm.change(&"air_dodge", {"dir": input.stick})
		return true
	if air_jumps_left > 0 and input.consume("jump"):
		air_jump()
		return true
	return false


func _try_special(grounded: bool) -> bool:
	if not input.buffered("special"):
		return false
	var dir := input.dir()
	var id := get_special(dir, grounded)
	if not can_use_move(id):
		return false
	input.consume("special")
	return start_move(id, dir.x)


func _try_ground_attack() -> bool:
	var dir := input.dir()
	var strong := false
	if input.consume("cstick"):
		strong = true
		dir = input.cstick_dir
		charge_button = "cstick"
	elif input.consume("strong"):
		strong = true
		charge_button = "strong"
	elif input.consume("attack"):
		# Attack together with a fresh flick of the stick = smash, held direction = tilt.
		strong = input.flicked_x() != 0 or input.flicked_down()
		charge_button = "attack"
	else:
		return false
	return start_move(get_ground_attack(dir, strong), dir.x)


func _try_aerial() -> bool:
	var dir := input.dir()
	if input.consume("cstick"):
		dir = input.cstick_dir
	elif not (input.consume("attack") or input.consume("strong")):
		return false
	return start_move(get_aerial(dir), dir.x)


func can_use_move(id: String) -> bool:
	if not moves.has(id):
		return false
	return not (moves[id].once_per_air and _used_air_moves.has(id))


func start_move(id: String, dir_x := 0) -> bool:
	if not moves.has(id):
		return false
	var m: MoveData = moves[id]
	if m.once_per_air:
		_used_air_moves[id] = true
	if m.turn_on_start:
		face(dir_x)
	current_move = m
	sm.change(&"attack")
	return true


## Called by AttackState when a move runs to completion.
func end_move() -> void:
	var m := current_move
	if m and m.ends_helpless:
		sm.change(&"helpless", {"landing_lag": m.helpless_landing_lag})
	elif is_on_floor():
		sm.change(&"idle")
	else:
		sm.change(&"air")


func air_jump() -> void:
	air_jumps_left -= 1
	vel.y = -stats.air_jump_velocity
	vel.x = input.x() * stats.air_speed
	fast_falling = false
	Sfx.play("jump", 0.05, -4.0)
	if sm.current_name == &"air":
		sm.current.enter({"air_jump": true})
	else:
		sm.change(&"air", {"air_jump": true})


func land(lag: int) -> void:
	sm.change(&"land", {"lag": lag})


## Ledge snap. Works while falling (not while rising, not while holding down).
func try_ledge_grab() -> bool:
	if stage == null or ledge_cooldown > 0 or input.dir_y() > 0:
		return false
	if vel.y + kb_velocity.y < 0.0:
		return false
	var top := global_position.y - stats.height
	for ledge in stage.ledges:
		if ledge.occupant != null:
			continue
		# dx < 0 means we're on the off-stage side of this ledge.
		var dx := (global_position.x - ledge.global_position.x) * ledge.dir
		if dx > 12.0 or dx < -(stats.half_width + 46.0):
			continue
		var dy := top - ledge.global_position.y
		if dy < -48.0 or dy > 40.0:
			continue
		sm.change(&"ledge_hang", {"ledge": ledge})
		return true
	return false


## Feet position while hanging from a ledge.
func ledge_hang_position(ledge: Ledge) -> Vector2:
	return ledge.global_position + Vector2(-ledge.dir * (stats.half_width + 2.0), stats.height * 0.78)


func _track_tech_input() -> void:
	if input.just_pressed("dodge") and frame >= tech_lockout_until:
		tech_press_frame = frame
		tech_lockout_until = frame + TECH_LOCKOUT


func can_tech() -> bool:
	return frame - tech_press_frame <= TECH_WINDOW


func consume_tech() -> void:
	tech_press_frame = -100000
	tech_lockout_until = frame


# --- Combat ------------------------------------------------------------------------------

func can_be_hit() -> bool:
	if not alive or invuln_frames > 0 or sm.current.is_intangible():
		return false
	if sm.current_name == &"attack" and current_move and current_move.is_intangible_at(move_frame):
		return false
	return true


func is_in_hitstun() -> bool:
	return not pending_launch.is_empty() or sm.current.is_hitstun()


func get_active_hitboxes() -> Array[Hitbox]:
	var out: Array[Hitbox] = []
	for hb in _hitbox_pool:
		if hb.is_active():
			out.append(hb)
	return out


func reset_hit_registry() -> void:
	_hit_registry.clear()


## Registry is per target *and* hitbox group, so a multi-hit's finisher (another group)
## can still connect after the earlier hits.
func register_hit(target: Fighter, data: HitboxData) -> void:
	_hit_registry[[target, data.group]] = move_frame


func can_hit_with(target: Fighter, data: HitboxData) -> bool:
	var key := [target, data.group]
	if not _hit_registry.has(key):
		return true
	return data.rehit > 0 and move_frame - int(_hit_registry[key]) >= data.rehit


func receive_hit(attacker: Fighter, data: HitboxData, damage_mult := 1.0) -> void:
	var damage := data.damage * damage_mult
	var grounded := is_on_floor()
	percent = minf(percent + damage, 999.0)

	# Knockback uses the percent *after* this hit's damage, like Smash.
	var kb: float
	if data.set_kb >= 0.0:
		kb = Knockback.fixed(data.set_kb, stats.weight, data.base_kb, data.growth)
	else:
		kb = Knockback.compute(percent, damage, stats.weight, data.base_kb, data.growth)

	var angle := deg_to_rad(Knockback.resolve_angle(data.angle, kb, grounded))
	var x_sign := attacker.facing
	if data.direction == HitboxData.Direction.AWAY:
		var dx := global_position.x - attacker.global_position.x
		if absf(dx) > 1.0:
			x_sign = int(signf(dx))
	var dir := Vector2(cos(angle) * x_sign, -sin(angle))
	# A spike on a grounded opponent pops them up instead of driving them into the floor.
	if grounded and dir.y > 0.0:
		dir.y = -dir.y
		kb *= 0.8

	if not is_in_hitstun():
		combo_count = 1
	elif not data.link:
		combo_count += 1
	pending_launch = {
		"kb": kb,
		"dir": dir,
		"hitstun": Knockback.hitstun_frames(kb, combo_count),
	}
	hitlag = Knockback.hitlag_frames(damage, data.hitlag_mult)
	vel = Vector2.ZERO
	kb_velocity = Vector2.ZERO
	fast_falling = false
	# Getting hit gives back your air dodge and recovery specials (not jumps).
	air_dodge_available = true
	_used_air_moves.clear()
	sm.change(&"hurt", {"hitstun": pending_launch.hitstun})
	damaged.emit(self, damage)


## End of hitlag: read DI and fly.
func _launch() -> void:
	var kb: float = pending_launch.kb
	var dir := Knockback.apply_di(pending_launch.dir, input.stick)
	var hitstun: int = pending_launch.hitstun
	pending_launch = {}
	kb_velocity = dir * kb * Knockback.LAUNCH_SPEED
	if kb >= Knockback.TUMBLE_THRESHOLD:
		sm.change(&"tumble", {"hitstun": hitstun})
	else:
		sm.change(&"hurt", {"hitstun": hitstun})
	launched.emit(self, kb)


func on_hit_landed(target: Fighter, data: HitboxData) -> void:
	hitlag = maxi(hitlag, Knockback.hitlag_frames(data.damage * charge_mult, data.hitlag_mult))
	if sm.current_name == &"attack" and current_move and current_move.on_hit.is_valid():
		current_move.on_hit.call(self, target)


func _update_hitboxes() -> void:
	var used := 0
	if sm.current_name == &"attack" and current_move:
		for h in current_move.hitboxes:
			if move_frame >= h.start and move_frame <= h.end:
				if used >= _hitbox_pool.size():
					var hb := Hitbox.new()
					hb.owner_fighter = self
					hitbox_root.add_child(hb)
					_hitbox_pool.append(hb)
				_hitbox_pool[used].activate(h, facing)
				used += 1
	for i in range(used, _hitbox_pool.size()):
		_hitbox_pool[i].deactivate()


func clear_hitboxes() -> void:
	for hb in _hitbox_pool:
		hb.deactivate()


# --- Stocks / rounds -----------------------------------------------------------------

func die() -> void:
	alive = false
	visible = false
	hitlag = 0
	pending_launch = {}
	vel = Vector2.ZERO
	kb_velocity = Vector2.ZERO
	clear_hitboxes()
	sm.change(&"dead")
	knocked_out.emit(self)


func respawn(at: Vector2) -> void:
	reset_physics(at)
	invuln_frames = RESPAWN_INVULN_FRAMES
	sm.change(&"respawn")


func reset_physics(at: Vector2) -> void:
	alive = true
	visible = true
	global_position = at
	vel = Vector2.ZERO
	kb_velocity = Vector2.ZERO
	hitlag = 0
	pending_launch = {}
	combo_count = 0
	fast_falling = false
	refresh_air_options()
	input.clear_buffer()


func reset_for_round(at: Vector2, face_dir: int) -> void:
	reset_physics(at)
	percent = 0.0
	facing = face_dir
	invuln_frames = 0
	sm.change(&"idle")


# --- Visuals -----------------------------------------------------------------------------

func play_anim(anim_name: String, restart := false) -> void:
	if not anim.has_animation(anim_name):
		if not anim.has_animation("idle"):
			return
		anim_name = "idle"
	if restart or anim.assigned_animation != anim_name:
		anim.play(anim_name)
		anim.seek(0.0, true)


func apply_palette(colors: Dictionary) -> void:
	tag_color = colors.get("tag", Color.WHITE)
	for node in rig.find_children("*", "ShapePart", true, false):
		var part := node as ShapePart
		if part.palette_slot != "" and colors.has(part.palette_slot):
			part.fill = colors[part.palette_slot]


func _draw_overlay() -> void:
	if not alive:
		return
	if sm.current_name == &"respawn":
		# Glowing rune disc the fighter stands on after respawning.
		_overlay.draw_rect(Rect2(-36, 0, 72, 8), Palette.GOLD)
		_overlay.draw_rect(Rect2(-36, 0, 72, 8), Palette.OUTLINE, false, 2.0)
	# Player tag above the head.
	var top := -stats.height - 18.0
	_overlay.draw_colored_polygon(PackedVector2Array([
		Vector2(-7, top - 8), Vector2(7, top - 8), Vector2(0, top)]), tag_color)
	_overlay.draw_string(ThemeDB.fallback_font, Vector2(-9, top - 12), "P%d" % player_index,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, tag_color)
	if not Game.debug_draw:
		return
	var hurt := hurtbox.world_rect()
	var hurt_color := Color(0.3, 0.6, 1.0, 0.35) if not can_be_hit() else Color(1.0, 0.9, 0.2, 0.3)
	_overlay.draw_rect(Rect2(hurt.position - global_position, hurt.size), hurt_color)
	for hb in get_active_hitboxes():
		var r := hb.world_rect()
		_overlay.draw_rect(Rect2(r.position - global_position, r.size), Color(1, 0.1, 0.1, 0.45))
	_overlay.draw_string(ThemeDB.fallback_font, Vector2(-30, 16), String(sm.current_name),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)


# --- Moves every legend gets ------------------------------------------------------

func _add_shared_moves() -> void:
	if not moves.has("getup_attack"):
		var m := MoveData.make("getup_attack", 34, "getup_attack")
		m.grounded = true
		m.land_cancels = false
		m.intangible_from = 1
		m.intangible_to = 15
		m.hit(HitboxData.make(16, 19, Vector2(30, -22), Vector2(56, 30), 6, 30, 60, 40).away())
		m.hit(HitboxData.make(16, 19, Vector2(-30, -22), Vector2(56, 30), 6, 30, 60, 40).away())
		moves["getup_attack"] = m
	if not moves.has("ledge_attack"):
		var m := MoveData.make("ledge_attack", 30, "ledge_attack")
		m.grounded = true
		m.land_cancels = false
		m.intangible_from = 1
		m.intangible_to = 9
		m.hit(HitboxData.make(10, 13, Vector2(44, -48), Vector2(76, 36), 7, 30, 60, 30))
		moves["ledge_attack"] = m

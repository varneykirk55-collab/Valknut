extends FighterState
## Plays any MoveData: normals, aerials and specials. Hitboxes are switched on by
## Fighter._update_hitboxes() from move_frame, so this state only advances the frame
## counter and handles motion, charging, chains, landing and interrupts.

var move: MoveData
var charging := false
var charge := 0
var airborne := false


func enter(_data: Dictionary) -> void:
	move = f.current_move
	f.move_frame = 0
	f.charge_mult = 1.0
	f.reset_hit_registry()
	charging = false
	charge = 0
	airborne = not f.is_on_floor()
	if move.grounded:
		f.hurtbox.reset_size()
	f.play_anim(move.anim, true)
	if not move.hitboxes.is_empty():
		Sfx.play("swing", 0.12, -8.0)


func exit() -> void:
	f.anim_hold = false
	f.clear_hitboxes()
	# Chaining into another move sets current_move before this exit runs; keep it.
	if f.current_move == move:
		f.current_move = null


func tick() -> void:
	if charging:
		_tick_charge()
		return

	f.move_frame += 1
	var mf := f.move_frame

	if mf == move.charge_frame and _charge_held():
		charging = true
		f.anim_hold = true

	if move.velocity_keys.has(mf):
		var v: Vector2 = move.velocity_keys[mf]
		f.vel = Vector2(v.x * f.facing, v.y)

	if move.on_frame.is_valid():
		move.on_frame.call(f, mf)
		if sm.current != self:
			return  # the special changed state itself

	_physics()

	if airborne and f.is_on_floor() and move.land_cancels:
		var in_lag_window := mf >= move.autocancel_from and mf <= move.autocancel_to
		f.land(move.landing_lag if in_lag_window else Fighter.NORMAL_LANDING_LAG)
		return
	if not f.is_on_floor():
		if move.grounded and not airborne:
			sm.change(&"air")  # walked off a ledge mid-attack
			return
		airborne = true

	if move.can_grab_ledge_from >= 0 and mf >= move.can_grab_ledge_from and f.try_ledge_grab():
		return

	# Jab strings: pressing attack again during the chain window continues the combo.
	if move.chain_to != "" and mf >= move.chain_from and f.input.consume("attack"):
		f.start_move(move.chain_to)
		return

	if mf >= move.iasa() and mf < move.total_frames:
		if (f.try_ground_actions() if f.is_on_floor() else f.try_air_actions()):
			return

	if mf >= move.total_frames:
		f.end_move()


func _physics() -> void:
	if f.is_on_floor() and not airborne:
		f.ground_friction()
		f.apply_gravity()
	else:
		if move.allow_fast_fall:
			f.check_fast_fall()
		f.apply_gravity(move.gravity_scale)
		if move.drift > 0.0:
			f.air_drift(move.drift)
	f.move_body()


func _charge_held() -> bool:
	if f.charge_button == "cstick":
		return f.input.cstick.length() > 0.6
	return f.input.held(f.charge_button)


## Smash charge: frozen on charge_frame, damage scales up to ×1.4 over max_charge frames.
func _tick_charge() -> void:
	charge += 1
	f.charge_mult = 1.0 + 0.4 * float(charge) / move.max_charge
	f.ground_friction()
	f.apply_gravity()
	f.move_body()
	if charge >= move.max_charge or not _charge_held():
		charging = false
		f.anim_hold = false

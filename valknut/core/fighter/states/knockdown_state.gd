extends FighterState
## Missed tech: lying on the ground, vulnerable. After a short delay pick a getup:
## direction = roll, attack = getup attack, anything else = stand up. Auto-stands later.

const MIN_LIE := 20
const AUTO_GETUP := 90
const STAND_TOTAL := 30
const ROLL_TOTAL := 36
const GETUP_INTANGIBLE := 22
const ROLL_DISTANCE := 130.0

enum Phase { LYING, STAND, ROLL }
var phase := Phase.LYING
var phase_start := 0
var dir := 0


func enter(_data: Dictionary) -> void:
	phase = Phase.LYING
	f.vel = Vector2.ZERO
	f.kb_velocity = Vector2.ZERO
	f.combo_count = 0
	f.play_anim("knockdown", true)
	Sfx.play("land", 0.1, -2.0)


func tick() -> void:
	match phase:
		Phase.LYING:
			if frame >= MIN_LIE:
				_choose_getup()
		Phase.ROLL:
			if frame - phase_start <= 24:
				f.vel.x = dir * ROLL_DISTANCE / 24.0 * 60.0
			else:
				f.vel.x = 0.0
	if sm.current != self:
		return
	if phase != Phase.ROLL:
		f.ground_friction(2.0)
	f.apply_gravity()
	f.move_body()
	if not f.is_on_floor():
		sm.change(&"air")
		return
	var t := frame - phase_start
	if (phase == Phase.STAND and t >= STAND_TOTAL) or (phase == Phase.ROLL and t >= ROLL_TOTAL):
		sm.change(&"idle")


func _choose_getup() -> void:
	var inp := f.input
	if inp.consume("attack") or inp.consume("strong"):
		f.start_move("getup_attack")
		return
	var dx := inp.dir_x()
	if dx != 0 or inp.consume("dodge"):
		_begin(Phase.ROLL, dx if dx != 0 else -f.facing)
		return
	if inp.consume("jump") or inp.consume("special") or inp.dir_y() < 0 or frame >= AUTO_GETUP:
		_begin(Phase.STAND, 0)


func _begin(p: Phase, d: int) -> void:
	phase = p
	phase_start = frame
	dir = d
	f.play_anim("roll" if p == Phase.ROLL else "getup", true)


func is_intangible() -> bool:
	return phase != Phase.LYING and frame - phase_start <= GETUP_INTANGIBLE

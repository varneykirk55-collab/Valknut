extends FighterState
## Ground tech: in place, or rolling left/right. Intangible for most of it.

const IN_PLACE_TOTAL := 20
const ROLL_TOTAL := 34
const INTANGIBLE_TO := 18
const ROLL_DISTANCE := 140.0

var dir := 0


func enter(data: Dictionary) -> void:
	dir = data.get("dir", 0)
	f.vel = Vector2.ZERO
	f.kb_velocity = Vector2.ZERO
	f.combo_count = 0
	f.play_anim("tech" if dir == 0 else "roll", true)
	Sfx.play("tech")


func tick() -> void:
	if dir != 0 and frame <= 24:
		f.vel.x = dir * ROLL_DISTANCE / 24.0 * 60.0
	else:
		f.ground_friction(2.0)
	f.apply_gravity()
	f.move_body()
	if not f.is_on_floor():
		sm.change(&"air")
		return
	if frame >= (IN_PLACE_TOTAL if dir == 0 else ROLL_TOTAL):
		sm.change(&"idle")


func is_intangible() -> bool:
	return frame <= INTANGIBLE_TO

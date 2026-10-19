extends FighterState
## Grounded dodge: spot dodge in place (neutral) or a roll (with a direction).

const SPOT_TOTAL := 24
const SPOT_INTANGIBLE := Vector2i(3, 16)
const ROLL_TOTAL := 30
const ROLL_INTANGIBLE := Vector2i(3, 18)
const ROLL_MOVE_FRAMES := Vector2i(3, 20)

var dir := 0


func enter(data: Dictionary) -> void:
	dir = data.get("dir", 0)
	f.play_anim("spot_dodge" if dir == 0 else "roll", true)
	Sfx.play("dodge", 0.1, -6.0)


func tick() -> void:
	if dir != 0 and frame >= ROLL_MOVE_FRAMES.x and frame <= ROLL_MOVE_FRAMES.y:
		var frames := ROLL_MOVE_FRAMES.y - ROLL_MOVE_FRAMES.x + 1
		f.vel.x = dir * f.stats.roll_distance / frames * 60.0
	else:
		f.ground_friction(2.0)
	f.apply_gravity()
	f.move_body()
	if not f.is_on_floor():
		sm.change(&"air")
		return
	if frame >= (SPOT_TOTAL if dir == 0 else ROLL_TOTAL):
		sm.change(&"idle")


func is_intangible() -> bool:
	var w := SPOT_INTANGIBLE if dir == 0 else ROLL_INTANGIBLE
	return frame >= w.x and frame <= w.y

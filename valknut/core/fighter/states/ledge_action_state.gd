extends FighterState
## Getting up from a ledge: climb, roll, or climb-into-attack. The fighter is moved along
## a scripted path (up onto the stage, then inward) and is intangible for most of it.

const CLIMB := {"total": 28, "rise": 12, "intangible": 24, "inward": 10.0}
const ROLL := {"total": 40, "rise": 10, "intangible": 30, "inward": 150.0}
const ATTACK_CLIMB := {"total": 14, "rise": 10, "intangible": 14, "inward": 10.0}

var ledge: Ledge
var kind := "climb"
var spec := CLIMB
var from := Vector2.ZERO


func enter(data: Dictionary) -> void:
	ledge = data.ledge
	kind = data.get("kind", "climb")
	spec = {"climb": CLIMB, "roll": ROLL, "attack": ATTACK_CLIMB}[kind]
	from = f.global_position
	f.vel = Vector2.ZERO
	f.play_anim("roll" if kind == "roll" else "ledge_climb", true)


func tick() -> void:
	var top := ledge.global_position + Vector2(ledge.dir * (f.stats.half_width + 4.0), -1.0)
	var target := top + Vector2(ledge.dir * spec.inward, 0)
	var rise: int = spec.rise
	if frame <= rise:
		var t := float(frame) / rise
		f.global_position = Vector2(lerpf(from.x, top.x, t), lerpf(from.y, top.y, t * (2.0 - t)))
	else:
		var t := clampf(float(frame - rise) / maxf(spec.total - rise - 4, 1), 0.0, 1.0)
		f.global_position = top.lerp(target, t)
	if frame >= spec.total:
		f.vel = Vector2.ZERO
		f.move_body()  # settle onto the floor
		if kind == "attack":
			f.start_move("ledge_attack")
		else:
			sm.change(&"idle")


func is_intangible() -> bool:
	return frame <= spec.intangible

extends FighterState
## Standing on the respawn rune above the stage. Any input (or a timeout) drops you in.
## Invulnerability (Fighter.invuln_frames) keeps running after you leave.

const MAX_WAIT := 150


func enter(_data: Dictionary) -> void:
	f.vel = Vector2.ZERO
	f.play_anim("idle", true)


func tick() -> void:
	var inp := f.input
	var acted := inp.dir() != Vector2i.ZERO
	for b in ["jump", "attack", "special", "strong", "dodge"]:
		acted = acted or inp.buffered(b)
	if acted or frame >= MAX_WAIT:
		sm.change(&"air")  # buffered inputs come out on the next tick


func is_intangible() -> bool:
	return true

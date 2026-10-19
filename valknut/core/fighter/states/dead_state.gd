extends FighterState
## KO'd: waiting for the Match to respawn us (or end the round).


func enter(_data: Dictionary) -> void:
	f.vel = Vector2.ZERO
	f.kb_velocity = Vector2.ZERO


func is_intangible() -> bool:
	return true

class_name FighterState
extends RefCounted
## Base class for fighter states. Each state owns one behaviour (idle, airborne, hitstun…)
## and decides its own transitions. After calling sm.change() a state must return.

var f: Fighter
var sm: FighterStateMachine
## Ticks spent in this state (1 on the first tick after entering).
var frame: int:
	get: return sm.state_frame


func enter(_data: Dictionary) -> void:
	pass


func exit() -> void:
	pass


func tick() -> void:
	pass


## Intangible states can't be hit at all (dodges, ledge getups, respawn).
func is_intangible() -> bool:
	return false


## True while the fighter is still reeling from a hit (used for combo counting).
func is_hitstun() -> bool:
	return false

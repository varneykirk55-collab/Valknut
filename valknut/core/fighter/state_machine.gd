class_name FighterStateMachine
extends RefCounted
## Minimal named-state machine. States are plain objects registered by name.

signal state_changed(from: StringName, to: StringName)

var states := {}
var current: FighterState
var current_name: StringName = &""
var previous_name: StringName = &""
var state_frame := 0


func add(state_name: StringName, state: FighterState, fighter: Fighter) -> void:
	state.f = fighter
	state.sm = self
	states[state_name] = state


func change(state_name: StringName, data := {}) -> void:
	assert(states.has(state_name), "Unknown fighter state: %s" % state_name)
	if current:
		current.exit()
	previous_name = current_name
	current_name = state_name
	current = states[state_name]
	state_frame = 0
	current.enter(data)
	state_changed.emit(previous_name, current_name)


func tick() -> void:
	state_frame += 1
	current.tick()


func is_in(names: Array) -> bool:
	return current_name in names

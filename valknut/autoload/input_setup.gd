extends Node
## Builds every player's input actions at runtime so all bindings live in one place.
##
## Actions per player n (1 or 2):
##   p{n}_left/right/up/down          movement (keyboard, d-pad, left stick)
##   p{n}_jump/attack/special/strong/dodge
##   p{n}_cstick_left/right/up/down   right stick = directional strong attacks
##   p{n}_pause
## Keyboard bindings are always active. Each player can additionally own one gamepad
## (or none), set through assign_pad().

const PLAYERS := [1, 2]
const MOVE_DEADZONE := 0.3
const CSTICK_DEADZONE := 0.6

const KEYBOARD := {
	1: {
		"left": [KEY_A], "right": [KEY_D], "up": [KEY_W], "down": [KEY_S],
		"jump": [KEY_SPACE], "attack": [KEY_J], "special": [KEY_K], "strong": [KEY_L],
		"dodge": [KEY_SHIFT, KEY_SEMICOLON], "pause": [KEY_ESCAPE],
	},
	2: {
		"left": [KEY_LEFT], "right": [KEY_RIGHT], "up": [KEY_UP], "down": [KEY_DOWN],
		"jump": [KEY_KP_0], "attack": [KEY_KP_1], "special": [KEY_KP_2], "strong": [KEY_KP_3],
		"dodge": [KEY_KP_PERIOD, KEY_KP_ENTER], "pause": [KEY_BACKSPACE],
	},
}

const PAD_BUTTONS := {
	"jump": [JOY_BUTTON_A, JOY_BUTTON_Y],
	"attack": [JOY_BUTTON_X],
	"special": [JOY_BUTTON_B],
	"strong": [JOY_BUTTON_LEFT_SHOULDER],
	"dodge": [JOY_BUTTON_RIGHT_SHOULDER],
	"pause": [JOY_BUTTON_START],
	"left": [JOY_BUTTON_DPAD_LEFT], "right": [JOY_BUTTON_DPAD_RIGHT],
	"up": [JOY_BUTTON_DPAD_UP], "down": [JOY_BUTTON_DPAD_DOWN],
}

## action -> [axis, direction]
const PAD_AXES := {
	"left": [JOY_AXIS_LEFT_X, -1.0], "right": [JOY_AXIS_LEFT_X, 1.0],
	"up": [JOY_AXIS_LEFT_Y, -1.0], "down": [JOY_AXIS_LEFT_Y, 1.0],
	"cstick_left": [JOY_AXIS_RIGHT_X, -1.0], "cstick_right": [JOY_AXIS_RIGHT_X, 1.0],
	"cstick_up": [JOY_AXIS_RIGHT_Y, -1.0], "cstick_down": [JOY_AXIS_RIGHT_Y, 1.0],
	"dodge": [JOY_AXIS_TRIGGER_RIGHT, 1.0],
	"strong": [JOY_AXIS_TRIGGER_LEFT, 1.0],
}

const ACTIONS := [
	"left", "right", "up", "down", "jump", "attack", "special", "strong", "dodge", "pause",
	"cstick_left", "cstick_right", "cstick_up", "cstick_down",
]

## player -> joypad device index, or -1 for keyboard only.
var pads := {1: -1, 2: -1}


func _ready() -> void:
	auto_assign_pads()
	Input.joy_connection_changed.connect(func(_d, _c): auto_assign_pads())


## One pad connected: P1 keeps the keyboard, P2 gets the pad (keyboard + controller 1v1).
## Two or more: one pad each. Keyboards stay bound either way.
func auto_assign_pads() -> void:
	var connected := Input.get_connected_joypads()
	if connected.size() >= 2:
		pads = {1: connected[0], 2: connected[1]}
	elif connected.size() == 1:
		pads = {1: -1, 2: connected[0]}
	else:
		pads = {1: -1, 2: -1}
	rebuild()


func assign_pad(player: int, device: int) -> void:
	pads[player] = device
	rebuild()


func rebuild() -> void:
	for p in PLAYERS:
		for a in ACTIONS:
			var action := "p%d_%s" % [p, a]
			if InputMap.has_action(action):
				InputMap.erase_action(action)
			var deadzone := CSTICK_DEADZONE if a.begins_with("cstick") else MOVE_DEADZONE
			InputMap.add_action(action, deadzone)
			for key in KEYBOARD[p].get(a, []):
				InputMap.action_add_event(action, _key(key))
			var device: int = pads[p]
			if device < 0:
				continue
			for button in PAD_BUTTONS.get(a, []):
				InputMap.action_add_event(action, _pad_button(button, device))
			if PAD_AXES.has(a):
				InputMap.action_add_event(action, _pad_axis(PAD_AXES[a][0], PAD_AXES[a][1], device))


## Human-readable binding list for the controls screen.
func describe_keyboard(player: int) -> Array[String]:
	var lines: Array[String] = []
	for a in ["left", "right", "up", "down", "jump", "attack", "strong", "special", "dodge", "pause"]:
		var names: Array[String] = []
		for key in KEYBOARD[player].get(a, []):
			names.append(OS.get_keycode_string(key))
		lines.append("%-8s %s" % [a.capitalize(), " / ".join(names)])
	return lines


func pad_name(device: int) -> String:
	if device < 0:
		return "Keyboard only"
	var n := Input.get_joy_name(device)
	return "Pad %d%s" % [device + 1, (" (" + n + ")") if n != "" else ""]


func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.device = -1
	return e


func _pad_button(button: JoyButton, device: int) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = button
	e.device = device
	return e


func _pad_axis(axis: JoyAxis, direction: float, device: int) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = direction
	e.device = device
	return e

class_name PlayerInput
extends RefCounted
## Samples one player's actions once per physics tick and remembers recent presses.
##
## Buttons are buffered: a press stays "live" for BUFFER_FRAMES ticks until a state
## consumes it, so inputs pressed slightly early (during landing lag, hitlag, the end of
## an attack) still come out on the first actionable frame.

const BUFFER_FRAMES := 7
## A direction pressed this recently counts as a flick (attack + flick = smash attack).
const FLICK_FRAMES := 4
## Second press of the same direction within this window = dash.
const DOUBLE_TAP_FRAMES := 14
const DEADZONE := 0.3
const BUTTONS := ["jump", "attack", "special", "strong", "dodge"]
const NEVER := -100000

var prefix := "p1_"
## Disabled input reads as fully neutral (training dummy, round intro).
var enabled := true
var tap_jump := false
var frame := 0

var stick := Vector2.ZERO
var cstick := Vector2.ZERO
## Direction of the most recent right-stick flick, used with the virtual "cstick" button.
var cstick_dir := Vector2i.ZERO
## Training dummy DI override (Vector2.ZERO = none).
var forced_stick := Vector2.ZERO

var _held := {}
var _pressed_at := {}
var _consumed_at := {}
var _dir_pressed_at := {}
var _dir_prev_pressed_at := {}


func _init(player_index := 1) -> void:
	prefix = "p%d_" % player_index
	for b in BUTTONS + ["cstick"]:
		_held[b] = false
		_pressed_at[b] = NEVER
		_consumed_at[b] = NEVER
	for d in ["left", "right", "up", "down"]:
		_held[d] = false
		_dir_pressed_at[d] = NEVER
		_dir_prev_pressed_at[d] = NEVER


## frozen = true during hitlag: the stick still updates (for DI) and presses are recorded,
## but the buffer clock stops, so inputs pressed during hitlag don't expire.
func poll(frozen := false) -> void:
	if not frozen:
		frame += 1
	if not enabled:
		_poll_disabled()
		return
	stick = Vector2(
		Input.get_action_strength(prefix + "right") - Input.get_action_strength(prefix + "left"),
		Input.get_action_strength(prefix + "down") - Input.get_action_strength(prefix + "up"))
	stick = stick.limit_length(1.0)
	cstick = Vector2(
		Input.get_action_strength(prefix + "cstick_right") - Input.get_action_strength(prefix + "cstick_left"),
		Input.get_action_strength(prefix + "cstick_down") - Input.get_action_strength(prefix + "cstick_up"))

	_update_dir("left", stick.x < -DEADZONE)
	_update_dir("right", stick.x > DEADZONE)
	_update_dir("down", stick.y > DEADZONE)
	var up_now := stick.y < -DEADZONE
	var up_was: bool = _held["up"]
	_update_dir("up", up_now)

	for b in BUTTONS:
		var down := Input.is_action_pressed(prefix + b)
		if b == "jump" and tap_jump:
			if up_now and not up_was:
				_pressed_at["jump"] = frame
			down = down or up_now
		_set_button(b, down)

	# The right stick acts as a "strong attack in this direction" button.
	var c_active := cstick.length() > 0.6
	if c_active and not _held["cstick"]:
		cstick_dir = _to_dir(cstick)
	_set_button("cstick", c_active)


func _poll_disabled() -> void:
	stick = forced_stick
	cstick = Vector2.ZERO
	for b in BUTTONS + ["cstick"]:
		_held[b] = false
	for d in ["left", "right", "up", "down"]:
		_held[d] = false


func _set_button(b: String, down: bool) -> void:
	if down and not _held[b]:
		_pressed_at[b] = frame
	_held[b] = down


func _update_dir(d: String, down: bool) -> void:
	if down and not _held[d]:
		_dir_prev_pressed_at[d] = _dir_pressed_at[d]
		_dir_pressed_at[d] = frame
	_held[d] = down


# --- Buttons ---------------------------------------------------------------------

func held(b: String) -> bool:
	return _held.get(b, false)


## Pressed exactly this tick (unbuffered). Used for tech timing.
func just_pressed(b: String) -> bool:
	return _pressed_at.get(b, NEVER) == frame


## Pressed within the buffer window and not yet consumed.
func buffered(b: String) -> bool:
	var at: int = _pressed_at.get(b, NEVER)
	return frame - at < BUFFER_FRAMES and _consumed_at[b] != at


func consume(b: String) -> bool:
	if not buffered(b):
		return false
	_consumed_at[b] = _pressed_at[b]
	return true


func clear_buffer() -> void:
	for b in _pressed_at:
		_consumed_at[b] = _pressed_at[b]


# --- Directions ------------------------------------------------------------------

func x() -> float:
	return stick.x


## -1, 0 or 1 with deadzone.
func dir_x() -> int:
	return -1 if stick.x < -DEADZONE else (1 if stick.x > DEADZONE else 0)


## -1 = up, 1 = down.
func dir_y() -> int:
	return -1 if stick.y < -DEADZONE else (1 if stick.y > DEADZONE else 0)


## Dominant 4-way direction of the stick (zero when neutral).
func dir() -> Vector2i:
	return _to_dir(stick)


## Horizontal direction flicked within FLICK_FRAMES (0 if none).
func flicked_x() -> int:
	if dir_x() == -1 and frame - _dir_pressed_at["left"] < FLICK_FRAMES:
		return -1
	if dir_x() == 1 and frame - _dir_pressed_at["right"] < FLICK_FRAMES:
		return 1
	return 0


func flicked_down() -> bool:
	return dir_y() == 1 and frame - _dir_pressed_at["down"] < FLICK_FRAMES


func down_just_pressed() -> bool:
	return _dir_pressed_at["down"] == frame


## Returns ±1 on the tick a direction is pressed for the second time in quick succession.
func double_tapped_x() -> int:
	for d in [["left", -1], ["right", 1]]:
		if _dir_pressed_at[d[0]] == frame \
				and frame - _dir_prev_pressed_at[d[0]] <= DOUBLE_TAP_FRAMES:
			return d[1]
	return 0


static func _to_dir(v: Vector2) -> Vector2i:
	if v.length() < DEADZONE:
		return Vector2i.ZERO
	if absf(v.x) >= absf(v.y):
		return Vector2i(int(signf(v.x)), 0)
	return Vector2i(0, int(signf(v.y)))

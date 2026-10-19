class_name MenuList
extends VBoxContainer
## Keyboard/gamepad-driven vertical menu. Rows are either plain actions or option
## pickers ("< value >") changed with left/right. Any player's controls work.

signal activated(index: int)
signal value_changed(index: int, value_index: int)
signal back

const UP := ["ui_up", "p1_up", "p2_up"]
const DOWN := ["ui_down", "p1_down", "p2_down"]
const LEFT := ["ui_left", "p1_left", "p2_left"]
const RIGHT := ["ui_right", "p1_right", "p2_right"]
const ACCEPT := ["ui_accept", "p1_attack", "p2_attack", "p1_jump", "p2_jump"]
const CANCEL := ["ui_cancel", "p1_special", "p2_special"]

@export var font_size := 30
var selected := 0
## Ignore input until this process frame (avoids the opening keypress leaking in).
var ignore_until_frame := 0
var _items: Array[Dictionary] = []
var _labels: Array[Label] = []


func add_action(text: String) -> int:
	return _add({"text": text, "values": [], "index": 0})


func add_option(text: String, values: Array, index := 0) -> int:
	return _add({"text": text, "values": values, "index": index})


func value_index(i: int) -> int:
	return _items[i].index


func set_values(i: int, values: Array, index: int) -> void:
	_items[i].values = values
	_items[i].index = index
	_refresh()


func _add(item: Dictionary) -> int:
	_items.append(item)
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_constant_override("outline_size", 8)
	l.add_theme_color_override("font_outline_color", Palette.OUTLINE)
	add_child(l)
	_labels.append(l)
	_refresh()
	return _items.size() - 1


func _process(_delta: float) -> void:
	if not is_visible_in_tree() or _items.is_empty() or Engine.get_process_frames() < ignore_until_frame:
		return
	if _pressed(UP):
		_move(-1)
	elif _pressed(DOWN):
		_move(1)
	elif _pressed(LEFT):
		_change(-1)
	elif _pressed(RIGHT):
		_change(1)
	elif _pressed(ACCEPT):
		Sfx.play("menu_ok", 0.0)
		activated.emit(selected)
	elif _pressed(CANCEL):
		back.emit()


func _move(d: int) -> void:
	selected = wrapi(selected + d, 0, _items.size())
	Sfx.play("menu_move", 0.0)
	_refresh()


func _change(d: int) -> void:
	var item := _items[selected]
	if item.values.is_empty():
		return
	item.index = wrapi(item.index + d, 0, item.values.size())
	Sfx.play("menu_move", 0.0)
	_refresh()
	value_changed.emit(selected, item.index)


func _refresh() -> void:
	for i in _items.size():
		var item := _items[i]
		var text: String = item.text
		if not item.values.is_empty():
			text = "%s   <  %s  >" % [item.text, str(item.values[item.index])]
		var l := _labels[i]
		l.text = ("»  " + text + "  «") if i == selected else text
		l.add_theme_color_override("font_color", Palette.GOLD if i == selected else Palette.BONE)


static func _pressed(actions: Array) -> bool:
	for a in actions:
		if InputMap.has_action(a) and Input.is_action_just_pressed(a):
			return true
	return false

extends CanvasLayer
## Pause overlay. Runs while the tree is paused.

signal restart_requested

var _menu: MenuList
var _root: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	_root = ColorRect.new()
	(_root as ColorRect).color = Color(0, 0, 0, 0.6)
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var title := Label.new()
	title.text = "PAUSED"
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Palette.GOLD)
	title.add_theme_constant_override("outline_size", 10)
	title.add_theme_color_override("font_outline_color", Palette.OUTLINE)
	title.position = Vector2(0, 190)
	title.size = Vector2(1280, 80)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(title)
	_menu = MenuList.new()
	_menu.position = Vector2(440, 300)
	_menu.size = Vector2(400, 200)
	_menu.add_action("Resume")
	_menu.add_action("Restart Match")
	_menu.add_action("Quit to Title")
	_menu.activated.connect(_on_activated)
	_menu.back.connect(close)
	_root.add_child(_menu)
	_root.visible = false


func open() -> void:
	get_tree().paused = true
	_root.visible = true
	_menu.ignore_until_frame = Engine.get_process_frames() + 2


func close() -> void:
	get_tree().paused = false
	_root.visible = false


func _process(_delta: float) -> void:
	if _root.visible and Engine.get_process_frames() >= _menu.ignore_until_frame \
			and (Input.is_action_just_pressed("p1_pause") or Input.is_action_just_pressed("p2_pause")):
		close()


func _on_activated(i: int) -> void:
	match i:
		0:
			close()
		1:
			close()
			restart_requested.emit()
		2:
			close()
			Game.goto(Game.TITLE_SCREEN)

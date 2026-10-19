class_name ScreenBase
extends Control
## Shared look for menu screens: dark backdrop with a faint valknut emblem.

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), Palette.NIGHT)
	draw_rect(Rect2(0, 560, 1280, 160), Color(Palette.DARK_BLUE, 0.5))
	_draw_valknut(Vector2(640, 330), 260.0, Color(Palette.DARK_BLUE, 0.9))


## Three interlocked triangles.
func _draw_valknut(c: Vector2, r: float, color: Color) -> void:
	for k in 3:
		var offset := Vector2.from_angle(-PI / 2 + k * TAU / 3) * r * 0.28
		var pts := PackedVector2Array()
		for i in 4:
			pts.append(c + offset + Vector2.from_angle(-PI / 2 + i * TAU / 3) * r * 0.55)
		draw_polyline(pts, color, 14.0)


func make_label(text: String, font_size: int, color: Color, y: float) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", maxi(4, font_size / 7))
	l.add_theme_color_override("font_outline_color", Palette.OUTLINE)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = Vector2(0, y)
	l.size = Vector2(1280, font_size * 1.4)
	add_child(l)
	return l


func make_menu(y: float, font_size := 30) -> MenuList:
	var m := MenuList.new()
	m.font_size = font_size
	m.position = Vector2(240, y)
	m.size = Vector2(800, 10)
	m.ignore_until_frame = Engine.get_process_frames() + 2
	add_child(m)
	return m

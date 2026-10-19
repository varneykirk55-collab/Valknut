extends CanvasLayer
## Damage percents, stocks and round wins along the bottom, timer up top, center banner.

const PANEL_SIZE := Vector2(336, 104)
const TEXT_X := 116.0

var match_node: Node
var _panels := {}
var _timer: Label
var _banner: Label
var _sub: Label
var _banner_frames := 0
var _training: Label
var _combo_text := ""
var _combo_frames := 0


func setup(m: Node) -> void:
	match_node = m
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var view := Vector2(1280, 720)
	for i in m.fighters.size():
		var f: Fighter = m.fighters[i]
		var x := view.x * 0.5 + (-PANEL_SIZE.x - 40.0 if i == 0 else 40.0)
		_panels[f] = _make_panel(root, f, Vector2(x, view.y - PANEL_SIZE.y - 16))

	_timer = _label(root, 34, Palette.BONE)
	_timer.position = Vector2(view.x * 0.5 - 100, 12)
	_timer.size = Vector2(200, 40)
	_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_banner = _label(root, 84, Palette.GOLD)
	_banner.position = Vector2(0, view.y * 0.30)
	_banner.size = Vector2(view.x, 110)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub = _label(root, 28, Palette.BONE)
	_sub.position = Vector2(0, view.y * 0.30 + 110)
	_sub.size = Vector2(view.x, 40)
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_training = _label(root, 18, Palette.BONE)
	_training.position = Vector2(16, 12)
	_training.visible = m.training


func _make_panel(root: Control, f: Fighter, at: Vector2) -> Dictionary:
	var panel := Panel.new()
	panel.position = at
	panel.size = PANEL_SIZE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(Palette.NIGHT, 0.85)
	style.border_color = f.tag_color
	style.set_border_width_all(4)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)

	var bust_tex := Roster.portrait(_legend_id(f), "bust")
	if bust_tex:
		var bust := TextureRect.new()
		bust.texture = bust_tex
		bust.position = Vector2(6 + (102 - bust_tex.get_width()) * 0.5, PANEL_SIZE.y - bust_tex.get_height() - 6)
		bust.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(bust)
	var name_label := _label(panel, 18, f.tag_color)
	name_label.position = Vector2(TEXT_X, 6)
	name_label.text = "P%d  %s" % [f.player_index, f.stats.display_name.to_upper()]
	var pct := _label(panel, 52, Palette.BONE)
	pct.position = Vector2(TEXT_X, 26)
	pct.size = Vector2(150, 64)
	var pips := Pips.new()
	pips.position = Vector2(TEXT_X + 130, 34)
	pips.size = Vector2(70, 60)
	pips.fighter = f
	pips.match_node = match_node
	panel.add_child(pips)
	return {"percent": pct, "pips": pips, "shake": 0.0, "base": pct.position, "last": 0.0}


func _legend_id(f: Fighter) -> String:
	return Game.legends.get(f.player_index, "")


func _label(parent: Control, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", maxi(4, font_size / 6))
	l.add_theme_color_override("font_outline_color", Palette.OUTLINE)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


## frames < 0 keeps it up until replaced.
func banner(text: String, sub: String, frames: int) -> void:
	_banner.text = text
	_sub.text = sub
	_banner_frames = frames
	_banner.scale = Vector2.ONE * 1.3
	_banner.pivot_offset = _banner.size * 0.5
	create_tween().tween_property(_banner, "scale", Vector2.ONE, 0.15)


func on_hit(_attacker: Fighter, target: Fighter, dmg: float) -> void:
	var p: Dictionary = _panels[target]
	p.shake = minf(4.0 + dmg * 0.8, 16.0)
	if target.combo_count >= 2:
		_combo_text = "%d HIT COMBO" % target.combo_count
		_combo_frames = 90


func _process(_delta: float) -> void:
	if match_node == null:
		return
	for f in _panels:
		var p: Dictionary = _panels[f]
		var lbl: Label = p.percent
		lbl.text = "%d%%" % int(f.percent) if f.alive or f.stocks > 0 else "—"
		lbl.add_theme_color_override("font_color", percent_color(f.percent))
		p.shake = move_toward(p.shake, 0.0, 1.0)
		lbl.position = p.base + Vector2(randf_range(-p.shake, p.shake), randf_range(-p.shake, p.shake))
		(p.pips as Control).queue_redraw()

	if match_node.training or Game.time_minutes <= 0:
		_timer.text = ""
	elif match_node.sudden_death:
		_timer.text = "SUDDEN DEATH"
	else:
		var secs := ceili(match_node.time_left / 60.0)
		_timer.text = "%d:%02d" % [secs / 60, secs % 60]

	if _banner_frames > 0:
		_banner_frames -= 1
		if _banner_frames == 0:
			_banner.text = ""
			_sub.text = ""

	if match_node.training:
		var dummy: Fighter = match_node.fighters[1]
		if _combo_frames > 0:
			_combo_frames -= 1
		_training.text = "TRAINING   F3/F4 dummy %%: %d   F5 reset   F6 dummy DI: %s   F1 hitboxes\nDummy state: %s   %s" % [
			int(dummy.percent), match_node.dummy_di_name(), dummy.sm.current_name,
			_combo_text if _combo_frames > 0 else ""]


## White → yellow → orange → red → deep red as damage climbs.
static func percent_color(p: float) -> Color:
	var stops := [[0.0, Palette.BONE], [50.0, Color("f2d56b")], [100.0, Color("e8893a")],
		[150.0, Color("d4402f")], [220.0, Color("8e1a1a")]]
	for i in range(1, stops.size()):
		if p <= stops[i][0]:
			var t: float = (p - stops[i - 1][0]) / (stops[i][0] - stops[i - 1][0])
			return (stops[i - 1][1] as Color).lerp(stops[i][1], t)
	return stops[-1][1]


## Stock icons (circles) and round-win pips (diamonds).
class Pips extends Control:
	var fighter: Fighter
	var match_node: Node

	func _draw() -> void:
		if fighter == null:
			return
		var shown := 0 if match_node.training else fighter.stocks
		for i in mini(shown, 5):
			var c := Vector2(10 + i * 18, 10)
			draw_circle(c, 7, fighter.tag_color)
			draw_arc(c, 7, 0, TAU, 16, Palette.OUTLINE, 2.0)
		if match_node.training:
			return
		var wins: int = match_node.round_wins[fighter.player_index]
		for i in Game.rounds_to_win:
			var c := Vector2(10 + i * 20, 40)
			var pts := PackedVector2Array([c + Vector2(0, -8), c + Vector2(7, 0), c + Vector2(0, 8), c + Vector2(-7, 0)])
			draw_colored_polygon(pts, Palette.GOLD if i < wins else Color(Palette.IRON, 0.6))
			pts.append(pts[0])
			draw_polyline(pts, Palette.OUTLINE, 2.0)

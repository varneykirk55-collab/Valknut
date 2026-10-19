extends ScreenBase
## Match setup: legends, stage, rules and controller assignment.

const STOCK_OPTIONS := [1, 2, 3, 4, 5]
const TIME_OPTIONS := [0, 2, 3, 5, 8]
const ROUND_OPTIONS := [1, 2, 3]   ## rounds to win → best of 1 / 3 / 5

enum Row { P1_LEGEND, P2_LEGEND, STAGE, STOCKS, TIME, ROUNDS, TAP_JUMP, P1_PAD, P2_PAD, FIGHT, BACK }

var _menu: MenuList
var _legends: Array
var _stages: Array
var _pad_options: Array[int] = []
var _info: Label


func _ready() -> void:
	super()
	var training := Game.mode == Game.Mode.TRAINING
	make_label("TRAINING" if training else "VERSUS", 56, Palette.GOLD, 24)
	_legends = Roster.available(Roster.LEGENDS)
	_stages = Roster.available(Roster.STAGES)
	_pad_options = [-1]
	_pad_options.append_array(Input.get_connected_joypads())

	_menu = make_menu(110, 24)
	_menu.add_option("P1 Legend", _names(_legends), _index_of(_legends, Game.legends[1]))
	_menu.add_option("P2 Dummy" if training else "P2 Legend", _names(_legends), _index_of(_legends, Game.legends[2]))
	_menu.add_option("Stage", _names(_stages), _index_of(_stages, Game.stage_id))
	_menu.add_option("Stocks", STOCK_OPTIONS, maxi(STOCK_OPTIONS.find(Game.stocks), 0))
	_menu.add_option("Timer", TIME_OPTIONS.map(func(t): return "Off" if t == 0 else "%d:00" % t),
		maxi(TIME_OPTIONS.find(Game.time_minutes), 0))
	_menu.add_option("Rounds", ROUND_OPTIONS.map(func(r): return "Best of %d" % (r * 2 - 1)),
		maxi(ROUND_OPTIONS.find(Game.rounds_to_win), 0))
	_menu.add_option("Tap Jump (up = jump)", ["Off", "On"], 1 if Game.tap_jump else 0)
	_menu.add_option("P1 Controller", _pad_names(), maxi(_pad_options.find(InputSetup.pads[1]), 0))
	_menu.add_option("P2 Controller", _pad_names(), maxi(_pad_options.find(InputSetup.pads[2]), 0))
	_menu.add_action("FIGHT!")
	_menu.add_action("Back")
	_menu.selected = Row.FIGHT
	_menu.set_values(Row.FIGHT, [], 0)
	_menu.value_changed.connect(_on_changed)
	_menu.activated.connect(_on_activated)
	_menu.back.connect(func(): Game.goto(Game.TITLE_SCREEN))
	_info = make_label("", 18, Palette.BONE_SHADE, 560)
	_update_info()


func _draw() -> void:
	super()
	# Roster strip: every legend, locked ones dimmed.
	var w := 150.0
	var x0 := 640.0 - w * Roster.LEGENDS.size() * 0.5
	for i in Roster.LEGENDS.size():
		var l: Dictionary = Roster.LEGENDS[i]
		var r := Rect2(x0 + i * w + 6, 610, w - 12, 80)
		draw_rect(r, Palette.DARK_BLUE if l.available else Color(Palette.IRON, 0.25))
		draw_rect(r, Palette.GOLD if l.available else Palette.IRON, false, 3.0)
		var font := ThemeDB.fallback_font
		draw_string(font, r.position + Vector2(8, 30), l.name, HORIZONTAL_ALIGNMENT_LEFT, w - 24, 18,
			Palette.BONE if l.available else Palette.IRON_LIGHT)
		draw_string(font, r.position + Vector2(8, 56), l["class"] if l.available else "coming soon",
			HORIZONTAL_ALIGNMENT_LEFT, w - 24, 13, Palette.BONE_SHADE if l.available else Palette.IRON)


func _on_changed(row: int, idx: int) -> void:
	match row:
		Row.P1_LEGEND: Game.legends[1] = _legends[idx].id
		Row.P2_LEGEND: Game.legends[2] = _legends[idx].id
		Row.STAGE: Game.stage_id = _stages[idx].id
		Row.STOCKS: Game.stocks = STOCK_OPTIONS[idx]
		Row.TIME: Game.time_minutes = TIME_OPTIONS[idx]
		Row.ROUNDS: Game.rounds_to_win = ROUND_OPTIONS[idx]
		Row.TAP_JUMP: Game.tap_jump = idx == 1
		Row.P1_PAD: InputSetup.assign_pad(1, _pad_options[idx])
		Row.P2_PAD: InputSetup.assign_pad(2, _pad_options[idx])
	_update_info()


func _on_activated(row: int) -> void:
	if row == Row.FIGHT:
		Game.goto(Game.MATCH_SCENE)
	elif row == Row.BACK:
		Game.goto(Game.TITLE_SCREEN)


func _update_info() -> void:
	var l: Dictionary = Roster.legend(Game.legends[1])
	_info.text = "%s — %s" % [l.name, l.blurb]


func _pad_names() -> Array:
	return _pad_options.map(func(d): return InputSetup.pad_name(d))


static func _names(list: Array) -> Array:
	return list.map(func(e): return e.name)


static func _index_of(list: Array, id: String) -> int:
	for i in list.size():
		if list[i].id == id:
			return i
	return 0

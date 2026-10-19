extends ScreenBase
## Bindings and a crash course in the mechanics.


func _ready() -> void:
	super()
	make_label("CONTROLS", 56, Palette.GOLD, 20)
	var p1 := "\n".join(InputSetup.describe_keyboard(1))
	var p2 := "\n".join(InputSetup.describe_keyboard(2))
	_column("PLAYER 1 — KEYBOARD\n\n" + p1, 80)
	_column("PLAYER 2 — KEYBOARD\n\n" + p2, 470)
	_column("GAMEPAD\n\nMove     Left stick / D-pad\nJump     A / Y\nAttack   X\nSpecial  B\nStrong   LB / LT / right stick\nDodge    RB / RT\nPause    Start", 860)
	var tips := make_label(
		"Smash attack: flick a direction + Attack, or use Strong (hold to charge).   Up/neutral special = recovery.\n" +
		"Tech: press Dodge just before hitting the ground or a wall.   DI: hold a direction while getting hit.\n" +
		"Fast fall: tap down in the air.   Drop through platforms: tap down.   Dash: double-tap.   F1: show hitboxes.   F11: fullscreen.",
		16, Palette.BONE_SHADE, 520)
	tips.size.y = 90
	make_label("Press Special / Esc to go back", 20, Palette.IRON_LIGHT, 650)
	var menu := make_menu(700)
	menu.add_action("")
	menu.activated.connect(func(_i): Game.goto(Game.TITLE_SCREEN))
	menu.back.connect(func(): Game.goto(Game.TITLE_SCREEN))


func _column(text: String, x: float) -> void:
	var l := Label.new()
	l.text = text
	l.position = Vector2(x, 110)
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", Palette.BONE)
	add_child(l)

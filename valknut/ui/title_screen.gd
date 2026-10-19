extends ScreenBase
## Title: Versus / Training / Controls / Quit.


func _ready() -> void:
	super()
	make_label("VALKNUT", 120, Palette.GOLD, 110)
	make_label("A Norse Platform Fighter", 26, Palette.BONE_SHADE, 260)
	var menu := make_menu(360, 34)
	menu.add_action("Versus")
	menu.add_action("Training")
	menu.add_action("Controls")
	menu.add_action("Quit")
	menu.activated.connect(_on_activated)
	make_label("Move: WASD / Arrows / Stick    Confirm: J / Space / Enter / Pad A or X", 18, Palette.IRON_LIGHT, 660)


func _on_activated(i: int) -> void:
	match i:
		0:
			Game.mode = Game.Mode.VERSUS
			Game.goto(Game.VERSUS_SETUP)
		1:
			Game.mode = Game.Mode.TRAINING
			Game.goto(Game.VERSUS_SETUP)
		2:
			Game.goto(Game.CONTROLS_SCREEN)
		3:
			get_tree().quit()

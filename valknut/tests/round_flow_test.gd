extends Node
## Versus round flow: KOs → round win → next round → match win; timer → sudden death.
##   godot --headless --path . --fixed-fps 60 res://valknut/tests/round_flow_test.tscn

var failures := 0


func _ready() -> void:
	# Menus build without errors.
	for path in [Game.TITLE_SCREEN, Game.VERSUS_SETUP, Game.CONTROLS_SCREEN]:
		var screen: Node = load(path).instantiate()
		add_child(screen)
		await get_tree().process_frame
		screen.queue_free()
	check(true, "title / setup / controls screens instantiate")

	Game.mode = Game.Mode.VERSUS
	Game.stocks = 1
	Game.rounds_to_win = 2
	Game.time_minutes = 3
	var m: Node = load(Game.MATCH_SCENE).instantiate()
	add_child(m)
	await frames(m.INTRO_FRAMES + 5)
	check(m.phase == m.Phase.FIGHT, "intro countdown ends in FIGHT")

	m.fighters[1].global_position = Vector2(0, 2000)
	await frames(m.KO_FREEZE_FRAMES + 5)
	check(m.phase == m.Phase.ROUND_OVER and m.round_wins[1] == 1, "last-stock KO gives P1 the round")
	await frames(m.ROUND_OVER_FRAMES + 5)
	check(m.round_number == 2 and m.phase == m.Phase.INTRO, "round 2 starts")
	check(m.fighters[1].alive and m.fighters[1].stocks == 1, "stocks restored for round 2")

	await frames(m.INTRO_FRAMES + 5)
	m.time_left = 2
	await frames(5)
	check(m.sudden_death and is_equal_approx(m.fighters[0].percent, 300.0), "time out with equal stocks → sudden death at 300%%")
	await frames(m.SUDDEN_DEATH_INTRO + 5)
	m.fighters[0].global_position = Vector2(-3000, 0)
	await frames(m.KO_FREEZE_FRAMES + 5)
	check(m.round_wins[2] == 1 and m.phase == m.Phase.ROUND_OVER, "sudden death KO decides the round")
	await frames(m.ROUND_OVER_FRAMES + m.INTRO_FRAMES + 10)
	m.fighters[0].global_position = Vector2(0, 2000)
	await frames(m.KO_FREEZE_FRAMES + m.ROUND_OVER_FRAMES + 10)
	check(m.phase == m.Phase.MATCH_OVER and m._match_winner() == 2, "P2 wins the best-of-3 2-1")

	print("\n%s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	get_tree().quit(1 if failures > 0 else 0)


func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func check(ok: bool, what: String) -> void:
	print("   %s %s" % ["ok  " if ok else "FAIL", what])
	if not ok:
		failures += 1

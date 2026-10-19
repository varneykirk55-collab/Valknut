extends Node2D
## One local match. Drives the fixed-step simulation and the round flow:
##   best-of-N rounds · each round is a stock battle · when the timer runs out the
##   player with more stocks takes the round; equal stocks → SUDDEN DEATH (both at
##   300%, next KO wins).
## Training mode: P2 is a dummy, infinite stocks, no timer.

enum Phase { INTRO, FIGHT, ROUND_OVER, MATCH_OVER }

const INTRO_FRAMES := 160
const SUDDEN_DEATH_INTRO := 90
const KO_FREEZE_FRAMES := 22
const RESPAWN_DELAY := 50
const ROUND_OVER_FRAMES := 200
const SUDDEN_DEATH_PERCENT := 300.0

enum DummyDI { NONE, SURVIVAL, RANDOM }

@onready var stage_root: Node2D = $StageRoot
@onready var fighters_root: Node2D = $Fighters
@onready var effects: MatchEffects = $Effects
@onready var camera: Camera2D = $Camera
@onready var hud: CanvasLayer = $HUD
@onready var pause_menu: CanvasLayer = $PauseMenu

var fighters: Array[Fighter] = []
var stage: Stage
var resolver := CombatResolver.new()
var phase := Phase.INTRO
var phase_frame := 0
var intro_length := INTRO_FRAMES
var round_number := 1
var round_wins := {1: 0, 2: 0}
var time_left := 0
var sudden_death := false
var training := false
var dummy_di := DummyDI.NONE
var winner: Fighter = null

var _respawn_timers := {}
var _freeze := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	training = Game.mode == Game.Mode.TRAINING
	stage = load(Roster.stage(Game.stage_id).scene).instantiate()
	stage_root.add_child(stage)
	for i in [1, 2]:
		var f: Fighter = load(Roster.legend(Game.legends[i]).scene).instantiate()
		var inp := PlayerInput.new(i)
		inp.tap_jump = Game.tap_jump
		inp.enabled = not (training and i == 2)
		f.setup(i, inp, stage)
		fighters_root.add_child(f)
		fighters.append(f)
	camera.targets = fighters
	camera.bounds = stage.camera_bounds
	resolver.hit_landed.connect(_on_hit_landed)
	hud.setup(self)
	pause_menu.restart_requested.connect(_restart)
	start_round()


func start_round() -> void:
	sudden_death = false
	winner = null
	for i in fighters.size():
		var f := fighters[i]
		f.stocks = 99 if training else Game.stocks
		f.reset_for_round(stage.spawn_point(i), 1 if i == 0 else -1)
	_respawn_timers.clear()
	time_left = Game.time_minutes * 60 * 60
	intro_length = 1 if training else INTRO_FRAMES
	_set_phase(Phase.INTRO)
	camera.snap()


func _start_sudden_death() -> void:
	sudden_death = true
	for i in fighters.size():
		var f := fighters[i]
		f.stocks = 1
		f.reset_for_round(stage.spawn_point(i), 1 if i == 0 else -1)
		f.percent = SUDDEN_DEATH_PERCENT
	_respawn_timers.clear()
	intro_length = SUDDEN_DEATH_INTRO
	_set_phase(Phase.INTRO)
	hud.banner("SUDDEN DEATH", "", 80)


func _set_phase(p: Phase) -> void:
	phase = p
	phase_frame = 0


func _physics_process(_delta: float) -> void:
	if _freeze > 0:
		_freeze -= 1  # global hitstop on KO
		return
	phase_frame += 1
	match phase:
		Phase.INTRO:
			_tick_fighters(false)
			_intro_countdown()
			if phase_frame >= intro_length:
				_set_phase(Phase.FIGHT)
		Phase.FIGHT:
			_tick_fighters(true)
			_tick_respawns()
			_tick_timer()
			if training:
				_tick_training()
		Phase.ROUND_OVER:
			_tick_fighters(false)
			if phase_frame >= ROUND_OVER_FRAMES:
				if _match_winner() != 0:
					_set_phase(Phase.MATCH_OVER)
					hud.banner("PLAYER %d WINS!" % _match_winner(),
						"Attack: rematch   ·   Special: back to setup", -1)
				else:
					round_number += 1
					start_round()
		Phase.MATCH_OVER:
			if _any_pressed(["p1_attack", "p2_attack", "ui_accept"]):
				_restart()
			elif _any_pressed(["p1_special", "p2_special", "ui_cancel"]):
				Game.goto(Game.VERSUS_SETUP)


func _process(_delta: float) -> void:
	if phase != Phase.MATCH_OVER and _any_pressed(["p1_pause", "p2_pause"]):
		pause_menu.open()


func _tick_fighters(controls: bool) -> void:
	for f in fighters:
		var was_enabled := f.input.enabled
		if not controls:
			f.input.enabled = false
		if f.alive:
			f.tick()
		f.input.enabled = was_enabled
	resolver.resolve(_alive())
	_push_apart()
	_check_blast_zones()


func _alive() -> Array[Fighter]:
	var out: Array[Fighter] = []
	for f in fighters:
		if f.alive:
			out.append(f)
	return out


func _intro_countdown() -> void:
	if training or intro_length != INTRO_FRAMES:
		return
	match phase_frame:
		1:
			hud.banner("ROUND %d" % round_number, "First to %d" % Game.rounds_to_win, 40)
		40, 80, 120:
			hud.banner(str(3 - (phase_frame - 40) / 40), "", 38)
			Sfx.play("beep", 0.0)
		159:
			hud.banner("FIGHT!", "", 40)
			Sfx.play("go", 0.0)


## Fighters standing on top of each other get nudged apart.
func _push_apart() -> void:
	if fighters.size() < 2 or not (fighters[0].alive and fighters[1].alive):
		return
	var a := fighters[0]
	var b := fighters[1]
	if not (a.is_on_floor() and b.is_on_floor()):
		return
	var dx := b.global_position.x - a.global_position.x
	var min_dist := (a.stats.half_width + b.stats.half_width) * 0.8
	if absf(dx) < min_dist and absf(b.global_position.y - a.global_position.y) < 30.0:
		var push := signf(dx) if dx != 0.0 else 1.0
		a.global_position.x -= push * 2.0
		b.global_position.x += push * 2.0


func _check_blast_zones() -> void:
	var kos: Array[Fighter] = []
	for f in fighters:
		if f.alive and stage.is_outside_blast_zone(f.global_position):
			kos.append(f)
	for f in kos:
		var bz := stage.blast_zone
		var at := Vector2(clampf(f.global_position.x, bz.position.x, bz.end.x),
			clampf(f.global_position.y, bz.position.y, bz.end.y))
		effects.ko_blast(at, Vector2.ZERO, f.tag_color)
		camera.add_shake(26.0)
		Sfx.play("ko", 0.05)
		f.die()
		if not training:
			f.stocks -= 1
		_freeze = KO_FREEZE_FRAMES
		if f.stocks > 0 and not sudden_death:
			_respawn_timers[f] = RESPAWN_DELAY
	if kos.is_empty() or training or phase != Phase.FIGHT:
		return
	var standing := fighters.filter(func(f): return f.stocks > 0)
	if standing.size() == 1:
		_end_round(standing[0])
	elif standing.is_empty():
		_start_sudden_death()  # simultaneous last-stock KO


func _tick_respawns() -> void:
	for f in _respawn_timers.keys():
		_respawn_timers[f] -= 1
		if _respawn_timers[f] <= 0:
			_respawn_timers.erase(f)
			f.respawn(stage.respawn_point(fighters.find(f)))


func _tick_timer() -> void:
	if training or sudden_death or Game.time_minutes <= 0:
		return
	time_left -= 1
	if time_left > 0:
		return
	time_left = 0
	var a := fighters[0]
	var b := fighters[1]
	if a.stocks != b.stocks:
		hud.banner("TIME!", "", 60)
		_end_round(a if a.stocks > b.stocks else b)
	else:
		_start_sudden_death()


func _end_round(round_winner: Fighter) -> void:
	winner = round_winner
	round_wins[round_winner.player_index] += 1
	_set_phase(Phase.ROUND_OVER)
	hud.banner("PLAYER %d TAKES ROUND %d" % [round_winner.player_index, round_number],
		"%d – %d" % [round_wins[1], round_wins[2]], ROUND_OVER_FRAMES)


func _match_winner() -> int:
	for p in round_wins:
		if round_wins[p] >= Game.rounds_to_win:
			return p
	return 0


func _restart() -> void:
	Game.goto(Game.MATCH_SCENE)


func _on_hit_landed(attacker: Fighter, target: Fighter, data: HitboxData, point: Vector2) -> void:
	var dmg := data.damage * attacker.charge_mult
	effects.hit_spark(point, dmg, attacker.tag_color)
	Sfx.play_hit(dmg)
	if dmg >= 9.0:
		camera.add_shake(dmg * 0.7)
	hud.on_hit(attacker, target, dmg)


# --- Training ----------------------------------------------------------------------

func _tick_training() -> void:
	var dummy := fighters[1]
	var player := fighters[0]
	match dummy_di:
		DummyDI.NONE:
			dummy.input.forced_stick = Vector2.ZERO
		DummyDI.SURVIVAL:
			# Up and away from the attacker: the usual "live longer" DI.
			var away := signf(dummy.global_position.x - player.global_position.x)
			dummy.input.forced_stick = Vector2(away, -1.0).normalized()
		DummyDI.RANDOM:
			if dummy.frame % 20 == 0:
				dummy.input.forced_stick = Vector2.from_angle(randf() * TAU)


func _unhandled_input(event: InputEvent) -> void:
	if not training or not (event is InputEventKey and event.pressed and not event.echo):
		return
	var dummy := fighters[1]
	match event.physical_keycode:
		KEY_F3:
			dummy.percent = maxf(dummy.percent - 10.0, 0.0)
		KEY_F4:
			dummy.percent = minf(dummy.percent + 10.0, 999.0)
		KEY_F5:
			for i in fighters.size():
				fighters[i].reset_for_round(stage.spawn_point(i), 1 if i == 0 else -1)
		KEY_F6:
			dummy_di = ((dummy_di + 1) % DummyDI.size()) as DummyDI


func dummy_di_name() -> String:
	return ["None", "Survival (up + away)", "Random"][dummy_di]


static func _any_pressed(actions: Array) -> bool:
	for a in actions:
		if InputMap.has_action(a) and Input.is_action_just_pressed(a):
			return true
	return false

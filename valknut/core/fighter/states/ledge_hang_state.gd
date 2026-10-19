extends FighterState
## Hanging from a ledge. Grabbing restores jumps, air dodge and specials. The first grab
## after touching the stage gives brief invulnerability; regrabs without landing don't.
##   toward stage / up -> climb        jump   -> ledge jump
##   attack / strong   -> ledge attack  dodge  -> ledge roll
##   away / down       -> let go        (auto let-go after 5 seconds)

const ACT_DELAY := 6
const MAX_HANG := 300

var ledge: Ledge
var invuln := 0


func enter(data: Dictionary) -> void:
	ledge = data.ledge
	ledge.occupant = f
	f.vel = Vector2.ZERO
	f.kb_velocity = Vector2.ZERO
	f.fast_falling = false
	f.facing = ledge.dir
	f.global_position = f.ledge_hang_position(ledge)
	invuln = Fighter.LEDGE_INVULN_FRAMES if f.ledge_invuln_available else 0
	f.refresh_air_options()
	f.ledge_invuln_available = false
	f.play_anim("ledge_hang", true)


func exit() -> void:
	if ledge and ledge.occupant == f:
		ledge.occupant = null


func tick() -> void:
	f.global_position = f.ledge_hang_position(ledge)
	if frame < ACT_DELAY:
		return
	var inp := f.input
	var toward := inp.dir_x() * ledge.dir
	if inp.consume("jump"):
		f.global_position.y -= 20.0
		f.vel = Vector2(ledge.dir * 60.0, -f.stats.jump_velocity)
		f.ledge_cooldown = Fighter.LEDGE_REGRAB_FRAMES
		Sfx.play("jump", 0.05, -4.0)
		sm.change(&"air")
	elif inp.consume("attack") or inp.consume("strong"):
		sm.change(&"ledge_action", {"ledge": ledge, "kind": "attack"})
	elif inp.consume("dodge"):
		sm.change(&"ledge_action", {"ledge": ledge, "kind": "roll"})
	elif toward > 0 or inp.dir_y() < 0:
		sm.change(&"ledge_action", {"ledge": ledge, "kind": "climb"})
	elif toward < 0 or inp.dir_y() > 0 or frame >= MAX_HANG:
		f.global_position.x -= ledge.dir * 6.0
		f.ledge_cooldown = Fighter.LEDGE_REGRAB_FRAMES
		sm.change(&"air")


func is_intangible() -> bool:
	return frame <= invuln

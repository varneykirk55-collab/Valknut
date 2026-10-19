class_name MoveData
extends RefCounted
## Frame data for one attack or special. Frames are 1-based physics ticks at 60 Hz.
## Characters build these in code (see characters/*/<name>_moves.gd) so the numbers sit
## next to each other and are easy to tune.

var id := ""
var anim := ""
var total_frames := 30
var hitboxes: Array[HitboxData] = []

## --- Aerial behaviour -------------------------------------------------------
## Touching the ground ends the move (aerials, dives). Grounded moves set this false.
var land_cancels := true
## Landing lag when the move is interrupted by landing.
var landing_lag := 8
## Landing outside [autocancel_from, autocancel_to] only costs normal landing lag.
var autocancel_from := 0
var autocancel_to := 9999
var gravity_scale := 1.0
var drift := 1.0           ## air drift multiplier while the move is out
var allow_fast_fall := true

## --- Grounded behaviour -----------------------------------------------------
## Walking off a ledge mid-move cancels it into a fall.
var grounded := false
## Turn to face the held direction when the move starts.
var turn_on_start := false

## --- Flow -------------------------------------------------------------------
## Combo strings: an attack press made any time from `chain_queue_from` to `chain_until`
## is remembered (one press, never more) and continues into `chain_to` once the move
## reaches `chain_from`. No press → the move plays out and returns to neutral.
var chain_to := ""
var chain_from := 9999
var chain_queue_from := 1
var chain_until := -1      ## -1 = until the move ends
## First frame the fighter may act again (IASA). Defaults to total_frames.
var interrupt_from := -1
## Smash charge: the move pauses on this frame while the button is held.
var charge_frame := -1
var max_charge := 60
var ends_helpless := false
var helpless_landing_lag := 18
## Can only be used once until the fighter lands, grabs a ledge or gets hit.
var once_per_air := false
var can_grab_ledge_from := -1   ## recovery moves snap to ledges from this frame
## Intangible frames [from, to], e.g. ledge attacks.
var intangible_from := -1
var intangible_to := -1

## --- Scripted motion ----------------------------------------------------------
## frame -> Vector2 velocity set on that frame. x is relative to facing.
var velocity_keys := {}
## Called every frame as on_frame.call(fighter, frame) for specials with custom logic.
var on_frame: Callable
## Called when a hitbox connects: on_hit.call(fighter, target).
var on_hit: Callable
## Whoosh played when the move starts ("" = silent).
var swing_sfx := "swing"


static func make(p_id: String, p_total: int, p_anim := "") -> MoveData:
	var m := MoveData.new()
	m.id = p_id
	m.total_frames = p_total
	m.anim = p_anim if p_anim != "" else p_id
	return m


func hit(h: HitboxData) -> MoveData:
	hitboxes.append(h)
	return self


func chain_window_end() -> int:
	return total_frames if chain_until < 0 else chain_until


func iasa() -> int:
	return total_frames if interrupt_from < 0 else interrupt_from


func is_intangible_at(frame: int) -> bool:
	return frame >= intangible_from and frame <= intangible_to

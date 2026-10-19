class_name HitboxData
extends RefCounted
## One hitbox of a move: when it's out, where it is, and what it does.
## Offsets are for a fighter facing right, relative to the fighter's feet.
## Angles: 0 = forward, 90 = straight up, 270 = straight down (spike), 361 = Sakurai angle.

enum Direction {
	FORWARD,   ## launches in the attacker's facing direction
	AWAY,      ## launches away from the attacker's center (good for spins/both-sides moves)
}

var start := 1
var end := 1
var offset := Vector2.ZERO
var size := Vector2(20, 20)
var damage := 5.0
var angle := 45.0
var base_kb := 30.0
var growth := 80.0
var set_kb := -1.0
var hitlag_mult := 1.0
var direction := Direction.FORWARD
## Frames before the same move can hit the same target again (0 = once per move).
var rehit := 0
## Link hits (the early hits of a multi-hit move) don't advance combo decay, so the
## whole move stays connected; only the move's finisher counts as a new combo hit.
var link := false
## Hitboxes of a move share one hit per target per group. Put a multi-hit's finisher
## in its own group so the earlier hits don't block it.
var group := 0


static func make(p_start: int, p_end: int, p_offset: Vector2, p_size: Vector2,
		p_damage: float, p_angle: float, p_base_kb: float, p_growth: float) -> HitboxData:
	var h := HitboxData.new()
	h.start = p_start
	h.end = p_end
	h.offset = p_offset
	h.size = p_size
	h.damage = p_damage
	h.angle = p_angle
	h.base_kb = p_base_kb
	h.growth = p_growth
	return h


func away() -> HitboxData:
	direction = Direction.AWAY
	return self


func with_set_kb(value: float) -> HitboxData:
	set_kb = value
	return self


func with_hitlag(mult: float) -> HitboxData:
	hitlag_mult = mult
	return self


func with_rehit(frames: int) -> HitboxData:
	rehit = frames
	return self


func in_group(g: int) -> HitboxData:
	group = g
	return self


func as_link() -> HitboxData:
	link = true
	return self

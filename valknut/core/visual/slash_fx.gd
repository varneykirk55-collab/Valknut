class_name SlashFX
extends Node2D
## Attack motion effects drawn in code and driven by AnimationPlayer: sweeping arcs
## for swings, speed lines for thrusts and lunges, rings for spins. Lives under
## Visual/Rig so it flips with the fighter's facing. Coordinates are relative to the
## fighter's feet, facing right; angles are degrees with 0 = forward, -90 = up.
##
## Animations key `t` (0 → 1 progress of the sweep) and `alpha`; the static helpers
## below build those keys so an attack's effect is one line in <legend>_anims.gd.

enum Mode { NONE, ARC, STREAK, RING }

const PATH := "Rig/SlashFX:"

var mode := Mode.NONE:
	set(v): mode = v; queue_redraw()
var t := 0.0:
	set(v): t = v; queue_redraw()
var alpha := 0.0:
	set(v): alpha = v; queue_redraw()
var center := Vector2.ZERO
var radius := 40.0
var angle_from := -90.0
var angle_to := 60.0
var width := 14.0
var color := Color(1.0, 0.84, 0.4)
## Vertical squash for rings (0.3 = flat ground sweep, 1 = full circle).
var squash := 1.0


func _draw() -> void:
	if mode == Mode.NONE or alpha <= 0.01:
		return
	match mode:
		Mode.ARC:
			_crescent(angle_from, lerpf(angle_from, angle_to, t), 1.0)
		Mode.STREAK:
			_streak()
		Mode.RING:
			# Three crescents chasing each other around the body.
			var turn := t * 360.0
			for k in 3:
				var a0 := turn + k * 120.0
				_crescent(a0, a0 + 85.0, squash)


## A tapered crescent from a0 (thin, transparent tail) to a1 (thick, bright head).
func _crescent(a0: float, a1: float, sy: float) -> void:
	var steps := 18
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	var cols_o := PackedColorArray()
	var cols_i := PackedColorArray()
	var core := PackedVector2Array()
	for i in steps + 1:
		var s := float(i) / steps
		var dir := Vector2.from_angle(deg_to_rad(lerpf(a0, a1, s)))
		dir.y *= sy
		var half := width * 0.5 * s
		outer.append(center + dir * (radius + half))
		inner.append(center + dir * (radius - half))
		core.append(center + dir * radius)
		var c := Color(color, alpha * pow(s, 1.4))
		cols_o.append(c)
		cols_i.append(c)
	inner.reverse()
	cols_i.reverse()
	var pts := outer + inner
	var cols := cols_o + cols_i
	draw_polygon(pts, cols)
	# Bright edge on the leading half.
	draw_polyline(core.slice(steps / 2), Color(1, 1, 1, alpha * 0.7), 2.0)


## Speed lines trailing behind `center`, opposite to the motion direction angle_from.
func _streak() -> void:
	var dir := Vector2.from_angle(deg_to_rad(angle_from))
	var perp := Vector2(-dir.y, dir.x)
	for i in 5:
		var off := (i - 2) / 2.0 * width
		var length := radius * (0.55 + 0.45 * fmod(i * 0.618, 1.0)) * t
		var start := center + perp * off - dir * radius * 0.08 * absf(i - 2)
		var c := Color(color, alpha * (1.0 - absf(i - 2) * 0.22))
		draw_line(start, start - dir * length, c, 3.0 if i == 2 else 2.0)


# --- Key builders for AnimBuilder ---------------------------------------------------

## Defaults every animation gets, so effects never leak between animations.
static func default_tracks() -> Dictionary:
	return {PATH + "mode": Mode.NONE, PATH + "t": 0.0, PATH + "alpha": 0.0}


## Sweeping arc from a0 to a1, drawn over `dur` frames starting at `start`, then held
## for `hold` frames and faded out.
static func arc(c: Vector2, r: float, a0: float, a1: float, w: float, col: Color,
		start: int, dur: int, hold := 5) -> Dictionary:
	return _keys(Mode.ARC, c, r, a0, a1, w, col, 1.0, start, dur, hold)


## Speed lines of `length` px behind `c`, for motion toward `angle`.
static func streak(c: Vector2, length: float, angle: float, spread: float, col: Color,
		start: int, dur: int, hold := 5) -> Dictionary:
	return _keys(Mode.STREAK, c, length, angle, angle, spread, col, 1.0, start, dur, hold)


## Spinning ring of crescents from `start` to `end`, making `turns` revolutions.
static func ring(c: Vector2, r: float, w: float, col: Color, start: int, end: int,
		turns: float, sy := 1.0) -> Dictionary:
	var k := _keys(Mode.RING, c, r, 0.0, 0.0, w, col, sy, start, end - start, 0)
	k[PATH + "t"] = [[0, 0.0], [start, 0.0], [end, turns]]
	return k


static func _keys(m: Mode, c: Vector2, r: float, a0: float, a1: float, w: float, col: Color,
		sy: float, start: int, dur: int, hold: int) -> Dictionary:
	var appear := maxi(start - 1, 0)
	return {
		PATH + "mode": m, PATH + "center": c, PATH + "radius": r,
		PATH + "angle_from": a0, PATH + "angle_to": a1, PATH + "width": w,
		PATH + "color": col, PATH + "squash": sy,
		PATH + "t": [[0, 0.0], [appear, 0.0], [start + dur, 1.0]],
		PATH + "alpha": [[0, 0.0], [appear, 0.0], [start, 1.0], [start + dur + hold, 1.0],
			[start + dur + hold + 5, 0.0]],
	}


## a + b (b wins). Lets an animation combine pose tracks with one effect.
static func with(a: Dictionary, b: Dictionary) -> Dictionary:
	var out := a.duplicate()
	out.merge(b, true)
	return out

@tool
class_name ShapePart
extends Node2D
## A flat-colored placeholder body part with a bold outline. Rigs are built from these
## so AnimationPlayer can pose them (rotation/position/scale) before real art exists.
## Set palette_slot ("primary", "secondary", "accent") to let the player color tint it.

enum Kind { RECT, CIRCLE, POLYGON }

@export var kind := Kind.RECT:
	set(v): kind = v; queue_redraw()
## RECT: top-left corner relative to this node's origin (the pivot).
@export var rect_position := Vector2(-10, 0):
	set(v): rect_position = v; queue_redraw()
@export var size := Vector2(20, 20):
	set(v): size = v; queue_redraw()
## CIRCLE: centered on center.
@export var center := Vector2.ZERO:
	set(v): center = v; queue_redraw()
@export var radius := 10.0:
	set(v): radius = v; queue_redraw()
@export var points := PackedVector2Array():
	set(v): points = v; queue_redraw()
@export var fill := Color.WHITE:
	set(v): fill = v; queue_redraw()
@export var outline := Color("141018"):
	set(v): outline = v; queue_redraw()
@export var outline_width := 3.0:
	set(v): outline_width = v; queue_redraw()
@export var palette_slot := ""


func _draw() -> void:
	match kind:
		Kind.RECT:
			var r := Rect2(rect_position, size)
			draw_rect(r, fill)
			if outline_width > 0.0:
				draw_rect(r, outline, false, outline_width)
		Kind.CIRCLE:
			draw_circle(center, radius, fill)
			if outline_width > 0.0:
				draw_arc(center, radius, 0.0, TAU, 28, outline, outline_width)
		Kind.POLYGON:
			if points.size() < 3:
				return
			draw_colored_polygon(points, fill)
			if outline_width > 0.0:
				var loop := points.duplicate()
				loop.append(points[0])
				draw_polyline(loop, outline, outline_width)

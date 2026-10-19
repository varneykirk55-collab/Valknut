class_name Stage
extends Node2D
## Base stage: geometry lives in child nodes, this script exposes what the match needs.
##
## Expected children:
##   Spawns/   Marker2D per player start (P1, P2 in order)
##   Respawns/ Marker2D per respawn point
##   Ledges/   Ledge nodes
## Solid ground goes on physics layer 1; soft platforms on layer 2, in group "platform",
## with one-way collision.

@export var stage_name := "Stage"
## Leaving this rectangle is a KO (ring-out on all four sides).
@export var blast_zone := Rect2(-1250, -1050, 2500, 1850)
## The camera never shows anything outside this rectangle.
@export var camera_bounds := Rect2(-1000, -760, 2000, 1260)
## Constant air push applied to airborne fighters (px/s). Jotunheim overrides get_wind().
@export var wind := Vector2.ZERO

var ledges: Array[Ledge] = []


func _ready() -> void:
	for n in get_node("Ledges").get_children():
		if n is Ledge:
			ledges.append(n)
	Game.debug_toggled.connect(func(_on): queue_redraw())


func get_wind(_at: Vector2) -> Vector2:
	return wind


func spawn_point(i: int) -> Vector2:
	var spawns := get_node("Spawns").get_children()
	return (spawns[i % spawns.size()] as Node2D).global_position


func respawn_point(i: int) -> Vector2:
	var points := get_node("Respawns").get_children()
	return (points[i % points.size()] as Node2D).global_position


func is_outside_blast_zone(p: Vector2) -> bool:
	return not blast_zone.has_point(p)


func _draw() -> void:
	if not Game.debug_draw:
		return
	draw_rect(blast_zone, Color(1, 0.2, 0.2, 0.8), false, 4.0)
	draw_rect(camera_bounds, Color(0.3, 0.7, 1.0, 0.6), false, 2.0)
	for l in ledges:
		draw_circle(to_local(l.global_position), 6, Color.YELLOW)

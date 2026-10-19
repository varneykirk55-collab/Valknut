extends Node2D
## Painted-by-code backdrop for Midgard Arena: dusk sky, mountains, the World Tree.
## Parallax: follows the camera at a fraction of its movement so it feels far away.

const PARALLAX := 0.75

var _base_position := Vector2.ZERO


func _ready() -> void:
	_base_position = position
	z_index = -50


func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam:
		position = _base_position + cam.get_screen_center_position() * PARALLAX


func _draw() -> void:
	# Sky bands (night blue → fjord blue → ember horizon).
	var bands := [Palette.NIGHT, Color("162238"), Palette.DARK_BLUE, Color("2c3c5c"), Color("4a3a48"), Color("6a3a32")]
	var top := -900.0
	for i in bands.size():
		draw_rect(Rect2(-2200, top + i * 180.0, 4400, 182), bands[i])
	draw_rect(Rect2(-2200, top + bands.size() * 180.0, 4400, 900), Color("2a1e22"))
	# Moon.
	draw_circle(Vector2(520, -560), 70, Palette.BONE_SHADE)
	draw_circle(Vector2(545, -575), 64, Color("2c3c5c"))
	# Yggdrasil silhouette: trunk + canopy blobs.
	var tree := Color("101824")
	draw_rect(Rect2(-90, -420, 180, 700), tree)
	for c in [Vector2(-260, -460), Vector2(0, -560), Vector2(260, -470), Vector2(-140, -620), Vector2(150, -640)]:
		draw_circle(c, 190, tree)
	# Distant mountains.
	var far := PackedVector2Array([Vector2(-2200, 260), Vector2(-1500, -120), Vector2(-1100, 120),
		Vector2(-700, -200), Vector2(-250, 140), Vector2(300, -160), Vector2(800, 120),
		Vector2(1300, -220), Vector2(1800, 100), Vector2(2200, -60), Vector2(2200, 600), Vector2(-2200, 600)])
	draw_colored_polygon(far, Color("1b2436"))
	var near := PackedVector2Array([Vector2(-2200, 380), Vector2(-1400, 160), Vector2(-900, 330),
		Vector2(-400, 200), Vector2(200, 360), Vector2(900, 180), Vector2(1500, 340),
		Vector2(2200, 220), Vector2(2200, 900), Vector2(-2200, 900)])
	draw_colored_polygon(near, Color("141b29"))

extends Node2D
## Draws the arena's stonework over the collision shapes (kept separate from physics so
## art can be replaced without touching geometry).

const STONE := Color("4a4f58")
const STONE_DARK := Color("33373f")
const GRASS := Color("2f5233")


func _draw() -> void:
	var outline := Palette.OUTLINE
	var main := PackedVector2Array([Vector2(-450, 0), Vector2(450, 0), Vector2(430, 40),
		Vector2(300, 110), Vector2(-300, 110), Vector2(-430, 40)])
	draw_colored_polygon(main, STONE)
	# Lower shadow band.
	draw_colored_polygon(PackedVector2Array([Vector2(-430, 40), Vector2(430, 40),
		Vector2(300, 110), Vector2(-300, 110)]), STONE_DARK)
	# Grass lip and rune carvings.
	draw_rect(Rect2(-450, -2, 900, 10), GRASS)
	for i in 7:
		var x := -300.0 + i * 100.0
		draw_line(Vector2(x, 30), Vector2(x + 14, 62), Palette.GOLD.darkened(0.3), 3.0)
		draw_line(Vector2(x + 14, 30), Vector2(x, 62), Palette.GOLD.darkened(0.3), 3.0)
	var loop := main.duplicate()
	loop.append(main[0])
	draw_polyline(loop, outline, 4.0)
	# Soft platforms: wooden planks.
	for px in [-230.0, 230.0]:
		var r := Rect2(px - 100, -162, 200, 14)
		draw_rect(r, Palette.WOOD)
		draw_rect(r, outline, false, 3.0)
		draw_line(Vector2(px - 70, -148), Vector2(px - 70, -120), outline, 3.0)
		draw_line(Vector2(px + 70, -148), Vector2(px + 70, -120), outline, 3.0)

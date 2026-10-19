class_name MatchEffects
extends Node2D
## Short-lived drawn effects: hit sparks and KO blasts. Each entry fades on its own.

var _fx: Array[Dictionary] = []


func hit_spark(at: Vector2, strength: float, color: Color) -> void:
	_fx.append({"kind": "spark", "pos": at, "size": 14.0 + strength * 2.2, "life": 12,
		"max": 12, "color": color, "rot": randf() * TAU})


## Beam shooting back into the stage from where the fighter crossed the blast zone.
func ko_blast(at: Vector2, toward: Vector2, color: Color) -> void:
	_fx.append({"kind": "ko", "pos": at, "dir": (toward - at).normalized(), "life": 45,
		"max": 45, "color": color})


func _physics_process(_delta: float) -> void:
	for e in _fx:
		e.life -= 1
	_fx = _fx.filter(func(e): return e.life > 0)
	queue_redraw()


func _draw() -> void:
	for e in _fx:
		var t: float = float(e.life) / e.max
		var c: Color = e.color
		match e.kind:
			"spark":
				var r: float = e.size * (1.6 - t * 0.6)
				var pts := PackedVector2Array()
				for i in 16:
					var a: float = e.rot + i * TAU / 16.0
					pts.append(e.pos + Vector2.from_angle(a) * (r if i % 2 == 0 else r * 0.4))
				draw_colored_polygon(pts, Color(c, t))
				draw_circle(e.pos, r * 0.3, Color(1, 1, 1, t))
			"ko":
				var length := 1400.0 * (1.0 - t * 0.5)
				var width := 120.0 * t
				var side: Vector2 = Vector2(-e.dir.y, e.dir.x) * width * 0.5
				var tip: Vector2 = e.pos + e.dir * length
				draw_colored_polygon(PackedVector2Array([e.pos - side * 1.6, tip - side * 0.2,
					tip + side * 0.2, e.pos + side * 1.6]), Color(c, t * 0.9))
				draw_colored_polygon(PackedVector2Array([e.pos - side * 0.6, tip,
					e.pos + side * 0.6]), Color(1, 1, 1, t))

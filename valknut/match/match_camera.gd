extends Camera2D
## Frames every living fighter, zooming out as they spread apart, never showing
## anything outside the stage's camera bounds. Also does screen shake.

const MARGIN := Vector2(220, 170)
const MIN_ZOOM := 0.55
const MAX_ZOOM := 1.4
const FOLLOW := 6.0

var targets: Array[Fighter] = []
var bounds := Rect2(-1000, -760, 2000, 1260)
var _shake := 0.0


func add_shake(amount: float) -> void:
	_shake = minf(_shake + amount, 28.0)


func snap() -> void:
	_update(1.0)


func _process(delta: float) -> void:
	_update(1.0 - exp(-FOLLOW * delta))
	_shake = move_toward(_shake, 0.0, 60.0 * delta)
	offset = Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake))


func _update(t: float) -> void:
	var box := Rect2()
	var any := false
	for f in targets:
		if not f.alive:
			continue
		var p := f.global_position + Vector2(0, -f.stats.height * 0.5)
		if not any:
			box = Rect2(p, Vector2.ZERO)
			any = true
		else:
			box = box.expand(p)
	if not any:
		box = Rect2(bounds.get_center(), Vector2.ZERO)
	box = box.grow_individual(MARGIN.x, MARGIN.y, MARGIN.x, MARGIN.y)

	var view := get_viewport_rect().size
	var z := clampf(minf(view.x / box.size.x, view.y / box.size.y), MIN_ZOOM, MAX_ZOOM)
	# Never zoom out past what the bounds can fill.
	z = maxf(z, maxf(view.x / bounds.size.x, view.y / bounds.size.y))
	zoom = zoom.lerp(Vector2(z, z), t)

	var half := view / zoom / 2.0
	var center := box.get_center()
	center.x = clampf(center.x, bounds.position.x + half.x, bounds.end.x - half.x)
	center.y = clampf(center.y, bounds.position.y + half.y, bounds.end.y - half.y)
	global_position = global_position.lerp(center, t)

class_name Hitbox
extends Area2D
## A live hitbox. Fighters keep a small pool of these and position one per active
## HitboxData each frame. Overlaps are resolved by CombatResolver with an exact
## rectangle test on the same tick (Area2D signals arrive a physics frame late, which
## would make frame data lie), but the Area2D/shape is kept so hitboxes show up with
## Debug ▸ Visible Collision Shapes and can be queried by stage hazards later.

var data: HitboxData
var owner_fighter: Node
var _shape := RectangleShape2D.new()


func _init() -> void:
	collision_layer = 1 << 3  # "hitbox"
	collision_mask = 0
	monitoring = false
	monitorable = false
	var cs := CollisionShape2D.new()
	cs.shape = _shape
	add_child(cs)


func activate(p_data: HitboxData, facing: int) -> void:
	data = p_data
	position = Vector2(p_data.offset.x * facing, p_data.offset.y)
	_shape.size = p_data.size
	visible = true


func deactivate() -> void:
	data = null
	visible = false


func is_active() -> bool:
	return data != null


func world_rect() -> Rect2:
	return Rect2(global_position - _shape.size * 0.5, _shape.size)

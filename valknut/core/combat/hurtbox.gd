class_name Hurtbox
extends Area2D
## The fighter's vulnerable area. One rectangle, resized by states (crouching shrinks it).

@onready var _shape_node: CollisionShape2D = $CollisionShape2D
var _standing_size := Vector2.ZERO


func _ready() -> void:
	collision_layer = 1 << 4  # "hurtbox"
	collision_mask = 0
	monitoring = false
	_shape_node.shape = _shape_node.shape.duplicate()  # instances must not share the resource
	_standing_size = (_shape_node.shape as RectangleShape2D).size


## Height grows upward from the feet.
func set_height(height: float) -> void:
	var rect := _shape_node.shape as RectangleShape2D
	rect.size = Vector2(_standing_size.x, height)
	_shape_node.position = Vector2(0, -height * 0.5)


func reset_size() -> void:
	set_height(_standing_size.y)


func world_rect() -> Rect2:
	var size := (_shape_node.shape as RectangleShape2D).size
	return Rect2(_shape_node.global_position - size * 0.5, size)

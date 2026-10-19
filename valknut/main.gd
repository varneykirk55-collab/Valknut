extends Node
## Root of the game. Swaps screens (title, setup, match) on Game.goto().

@onready var _screen_root: Node = $Screen


func _ready() -> void:
	Game.screen_requested.connect(_show)
	_show(Game.TITLE_SCREEN)


func _show(path: String) -> void:
	get_tree().paused = false
	for c in _screen_root.get_children():
		c.queue_free()
	# Deferred so the old screen finishes its frame before the new one appears.
	_screen_root.add_child.call_deferred(load(path).instantiate())

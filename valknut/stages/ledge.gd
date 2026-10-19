class_name Ledge
extends Marker2D
## A grabbable stage corner. Place it exactly on the corner of the solid ground.
## dir points from the ledge toward the stage: +1 for a left edge, -1 for a right edge.

@export_enum("Stage to the right:1", "Stage to the left:-1") var dir := 1

var occupant: Node = null

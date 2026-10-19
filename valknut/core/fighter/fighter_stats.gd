class_name FighterStats
extends Resource
## Movement and physical stats. Speeds in px/s, accelerations in px/s².

@export var display_name := "Fighter"
@export_group("Weight")
@export var weight := 100.0          ## heavier = less knockback (see Knockback.compute)
@export_group("Ground")
@export var walk_speed := 300.0
@export var dash_speed := 600.0
@export var run_speed := 520.0
@export var ground_accel := 2800.0
@export var ground_friction := 2400.0
@export var dash_frames := 10
@export var roll_distance := 150.0
@export_group("Air")
@export var air_speed := 300.0
@export var air_accel := 1600.0
@export var air_friction := 350.0
@export var gravity := 2400.0
@export var max_fall_speed := 850.0
@export var fast_fall_speed := 1350.0
@export var jump_velocity := 900.0
@export var short_hop_velocity := 560.0
@export var air_jump_velocity := 820.0
@export var air_jumps := 1
@export var jump_squat_frames := 4
@export var air_dodge_speed := 950.0
@export_group("Body")
@export var height := 84.0
@export var crouch_height := 54.0
@export var half_width := 18.0

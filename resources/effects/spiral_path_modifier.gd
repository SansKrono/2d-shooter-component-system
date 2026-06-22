extends "res://resources/effects/bullet_path_modifier.gd"

@export var rotation_speed: float = 8.0
@export var expansion_speed: float = 200.0

var spawn_pos: Vector2 = Vector2.ZERO
var base_angle: float = 0.0
var elapsed_time: float = 0.0
var original_speed: float = 0.0

const C_LOCOMOTION = preload("res://components/character/c_locomotion.gd")

func initialize_path(bullet: Entity) -> void:
	elapsed_time = 0.0
	spawn_pos = bullet.global_position if "global_position" in bullet else Vector2.ZERO
	var c_vel = bullet.get_component(C_Velocity) as C_Velocity
	var c_loco = bullet.get_component(C_LOCOMOTION) as C_Locomotion
	if c_vel:
		base_angle = c_vel.direction.angle()
		c_vel.direction = Vector2.ZERO
	if c_loco:
		original_speed = c_loco.base_speed
		c_loco.base_speed = 0.0
	else:
		original_speed = 400.0

func _tick_path(bullet: Entity, delta: float) -> void:
	elapsed_time += delta
	var angle = base_angle + elapsed_time * rotation_speed
	var radius = elapsed_time * expansion_speed
	
	if "global_position" in bullet:
		var current_pos = spawn_pos + Vector2.RIGHT.rotated(angle) * radius
		bullet.global_position = current_pos
		
		# Compute next position to determine instantaneous heading direction
		var next_angle = base_angle + (elapsed_time + delta) * rotation_speed
		var next_radius = (elapsed_time + delta) * expansion_speed
		var next_pos = spawn_pos + Vector2.RIGHT.rotated(next_angle) * next_radius
		
		var c_vel = bullet.get_component(C_Velocity) as C_Velocity
		if c_vel and next_pos != current_pos:
			c_vel.direction = (next_pos - current_pos).normalized()
	
	# Manually update distance traveled so range limits still work
	var c_traj = bullet.get_component(C_Trajectory) as C_Trajectory
	if c_traj:
		c_traj.distance_traveled += original_speed * delta

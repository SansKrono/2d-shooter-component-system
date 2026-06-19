extends "res://resources/effects/bullet_path_modifier.gd"

@export var orbit_radius: float = 75.0
@export var angular_speed: float = 5.0

var elapsed_time: float = 0.0
var initial_angle: float = 0.0
var spawn_pos: Vector2 = Vector2.ZERO
var original_speed: float = 0.0

func initialize_path(bullet: Entity) -> void:
	elapsed_time = 0.0
	spawn_pos = bullet.global_position if "global_position" in bullet else Vector2.ZERO
	var c_vel = bullet.get_component(C_Velocity) as C_Velocity
	if c_vel:
		original_speed = c_vel.speed
		initial_angle = c_vel.direction.angle()
		# Zero out velocity speed to disable standard MovementSystem updates
		c_vel.speed = 0.0
		c_vel.direction = Vector2.ZERO

func _tick_path(bullet: Entity, delta: float) -> void:
	elapsed_time += delta
	var angle = initial_angle + elapsed_time * angular_speed
	
	# Orbit around shooter if valid, otherwise orbit spawn position
	var center = spawn_pos
	if is_instance_valid(bullet.shooter) and "global_position" in bullet.shooter:
		center = bullet.shooter.global_position
		
	if "global_position" in bullet:
		var current_pos = center + Vector2.RIGHT.rotated(angle) * orbit_radius
		bullet.global_position = current_pos
		
		# Compute next position to determine instantaneous heading direction
		var next_angle = initial_angle + (elapsed_time + delta) * angular_speed
		var next_center = center
		if is_instance_valid(bullet.shooter) and "global_position" in bullet.shooter:
			next_center = bullet.shooter.global_position
		var next_pos = next_center + Vector2.RIGHT.rotated(next_angle) * orbit_radius
		
		var c_vel = bullet.get_component(C_Velocity) as C_Velocity
		if c_vel and next_pos != current_pos:
			c_vel.direction = (next_pos - current_pos).normalized()
		
	# Manually update distance traveled so range limits still work
	var c_traj = bullet.get_component(C_Trajectory) as C_Trajectory
	if c_traj:
		c_traj.distance_traveled += original_speed * delta

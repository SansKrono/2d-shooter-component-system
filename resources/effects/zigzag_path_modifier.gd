extends "res://resources/effects/bullet_path_modifier.gd"

@export var frequency: float = 15.0
@export var amplitude: float = 20.0 # Deviation offset in pixels

var last_offset: Vector2 = Vector2.ZERO
var elapsed_time: float = 0.0

func initialize_path(_bullet: Entity) -> void:
	last_offset = Vector2.ZERO
	elapsed_time = 0.0

func _tick_path(bullet: Entity, delta: float) -> void:
	elapsed_time += delta
	var c_vel = bullet.get_component(C_Velocity) as C_Velocity
	if c_vel and "global_position" in bullet:
		# 1. Revert previous offset
		bullet.global_position -= last_offset
		
		# 2. Get perpendicular vector to heading direction
		var forward = c_vel.direction
		if forward == Vector2.ZERO:
			forward = Vector2.RIGHT
		var perpendicular = Vector2(-forward.y, forward.x).normalized()
		
		# 3. Calculate new offset
		var offset_dist = sin(elapsed_time * frequency) * amplitude
		var offset = perpendicular * offset_dist
		
		# 4. Apply new offset
		bullet.global_position += offset
		last_offset = offset

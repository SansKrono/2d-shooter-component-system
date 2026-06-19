class_name TrajectorySystem
extends System

const C_BulletPath = preload("res://components/character/c_bullet_path.gd")

func query() -> QueryBuilder:
	return q.with_all([C_Velocity, C_Trajectory]).with_none([C_Input])

func process(entities: Array[Entity], _components: Array, delta: float) -> void:
	for entity in entities:
		var c_vel = entity.get_component(C_Velocity) as C_Velocity
		var c_traj = entity.get_component(C_Trajectory) as C_Trajectory
		if not c_vel or not c_traj:
			continue

		# 1. Update distance traveled and check range limit
		c_traj.distance_traveled += c_vel.speed * delta
		if c_traj.distance_traveled >= c_traj.max_range:
			cmd.remove_entity(entity)
			continue

		# 2. Homing logic toward the nearest living enemy
		if c_traj.homing_strength > 0.0 and entity.is_inside_tree():
			var tree = entity.get_tree()
			if not tree:
				continue
			var enemies = tree.get_nodes_in_group("enemies")
			var closest_enemy: Node2D = null
			var min_dist := INF

			for enemy in enemies:
				if is_instance_valid(enemy) and enemy is Node2D:
					# Verify enemy has health and is alive
					var health = enemy.get_component(C_Health) as C_Health
					if health and health.current <= 0.0:
						continue

					var dist = entity.global_position.distance_to(enemy.global_position)
					if dist < min_dist:
						min_dist = dist
						closest_enemy = enemy

			if closest_enemy:
				var target_dir = (closest_enemy.global_position - entity.global_position).normalized()
				# Interpolate direction toward target and normalize
				c_vel.direction = c_vel.direction.lerp(target_dir, c_traj.homing_strength * delta).normalized()

		# 3. Path modifier logic
		var c_path = entity.get_component(C_BulletPath) as C_BulletPath
		if c_path and not c_path.path_modifiers.is_empty():
			for modifier in c_path.path_modifiers:
				modifier.update_path(entity, delta)

		# 4. Orient bullet rotation to match velocity direction
		if c_vel.direction != Vector2.ZERO:
			entity.rotation = c_vel.direction.angle()

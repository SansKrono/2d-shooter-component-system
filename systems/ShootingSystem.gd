class_name ShootingSystem
extends System

const BULLET_PREFAB = preload("res://entities/projectiles/e_bullet.tscn")
const C_BulletPath = preload("res://components/character/c_bullet_path.gd")
const C_LOCOMOTION = preload("res://components/character/c_locomotion.gd")

func query() -> QueryBuilder:
	return q.with_all([C_Input, C_Shooter])

func process(entities: Array[Entity], _components: Array, delta: float) -> void:
	for entity in entities:
		var c_input = entity.get_component(C_Input) as C_Input
		var c_shooter = entity.get_component(C_Shooter) as C_Shooter
		if not c_input or not c_shooter:
			continue

		if c_shooter.cooldown_timer > 0.0:
			c_shooter.cooldown_timer -= delta

		if c_input.shoot_vector != Vector2.ZERO and c_shooter.cooldown_timer <= 0.0:
			# Reset cooldown
			c_shooter.cooldown_timer = c_shooter.fire_rate

			# Fetch player stats components
			var c_pay = entity.get_component(C_Payload) as C_Payload
			var c_traj = entity.get_component(C_Trajectory) as C_Trajectory
			var c_vol = entity.get_component(C_Volatility) as C_Volatility

			# 1. Accuracy spread calculation
			var shoot_dir = c_input.shoot_vector
			if c_traj:
				var dev = c_traj.accuracy_deviation
				var angle_offset = randf_range(-dev, dev)
				shoot_dir = shoot_dir.rotated(deg_to_rad(angle_offset))

			# 2. Critical hit calculation
			var is_crit = false
			var bullet_damage = c_pay.damage if c_pay else 10.0
			var knockback = c_pay.knockback_force if c_pay else 150.0
			var aoe = c_pay.area_of_effect if c_pay else 0.0

			if c_vol:
				is_crit = randf() < c_vol.crit_chance
				if is_crit:
					bullet_damage *= c_vol.crit_multiplier

			# Instantiate bullet prefab
			var bullet = BULLET_PREFAB.instantiate() as Entity
			bullet.shooter = entity

			# Set starting position to parent's position
			if "global_position" in entity:
				bullet.position = entity.global_position

			# Apply visual feedback for crits (turn sprite red)
			if is_crit:
				var sprite = bullet.get_node_or_null("Sprite2D") as Sprite2D
				if sprite:
					sprite.self_modulate = Color.RED

			# Scale bullet visually and physically
			bullet.scale = Vector2.ONE * c_shooter.bullet_size

			# Attach bullet path modifiers if the shooter has any
			var c_path = entity.get_component(C_BulletPath) as C_BulletPath
			if c_path and not c_path.path_modifiers.is_empty():
				bullet.add_component(C_BulletPath.new(c_path.path_modifiers))

			# Compose components for the bullet
			bullet.add_component(C_Velocity.new(shoot_dir))
			# Projectile uses C_Locomotion with instant acceleration and no decay
			# to travel at constant speed in the given direction
			bullet.add_component(C_LOCOMOTION.new(c_shooter.bullet_speed, 99999.0, 99999.0))
			bullet.add_component(C_Payload.new(bullet_damage, knockback, aoe))

			var bullet_range = c_traj.max_range if c_traj else 500.0
			var bullet_homing = c_traj.homing_strength if c_traj else 0.0
			bullet.add_component(C_Trajectory.new(bullet_range, 0.0, bullet_homing))

			var bullet_vol = C_Volatility.new()
			bullet_vol.is_critical = is_crit
			bullet.add_component(bullet_vol)

			# Queue addition to world via CommandBuffer
			cmd.add_entity(bullet)

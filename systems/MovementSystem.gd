class_name MovementSystem
extends System

const C_LOCOMOTION = preload("res://components/character/c_locomotion.gd")
const C_VELOCITY_MODIFIER = preload("res://components/character/c_velocity_modifier.gd")
const C_PROJECTILE = preload("res://entities/projectiles/e_bullet.gd")

func query() -> QueryBuilder:
	return q.with_all([C_Velocity])

func process(entities: Array[Entity], _components: Array, delta: float) -> void:
	for entity in entities:
		var c_vel     = entity.get_component(C_Velocity) as C_Velocity
		var c_loco    = entity.get_component(C_LOCOMOTION) as C_Locomotion
		var c_vel_mod = entity.get_component(C_VELOCITY_MODIFIER)

		if not c_vel:
			continue

		# ── 1. Resolve modifier velocity (knockback, dashes, etc.) ──────────
		var modifier_vel := Vector2.ZERO
		if c_vel_mod:
			modifier_vel = c_vel_mod.velocity
			var mod_friction : float = c_loco.friction if c_loco else 800.0
			c_vel_mod.velocity = c_vel_mod.velocity.move_toward(
				Vector2.ZERO, mod_friction * delta
			)
			if c_vel_mod.velocity == Vector2.ZERO:
				cmd.remove_component(entity, C_VELOCITY_MODIFIER)

		# ── 2. Knockback decay ───────────────────────────────────────────────
		var knockback_friction : float = c_loco.friction if c_loco else 800.0
		if c_vel.knockback != Vector2.ZERO:
			c_vel.knockback = c_vel.knockback.move_toward(
				Vector2.ZERO, knockback_friction * delta
			)

		# Only the changed section of MovementSystem is shown.
		# Replace Step 3 and Step 5 from the previous version.

		# ── Step 3. Smooth locomotion ────────────────────────────────────────────
		if c_loco:
			var top_speed : float = c_loco.base_speed * c_loco.speed_multiplier
			var target_vel : Vector2 = c_vel.direction.normalized() * top_speed

			if c_vel.direction != Vector2.ZERO:
				c_loco.current_velocity = c_loco.current_velocity.move_toward(
					target_vel, c_loco.acceleration * delta
				)
			else:
				c_loco.current_velocity = c_loco.current_velocity.move_toward(
					Vector2.ZERO, c_loco.friction * delta
				)

		# ── Step 4. Compose final velocity ───────────────────────────────────────
		var loco_vel  : Vector2 = c_loco.current_velocity if c_loco else Vector2.ZERO
		var final_vel : Vector2 = loco_vel + c_vel.knockback + modifier_vel


		# ── Step 5. Apply via PhysicsBody child ─────────────────────────────
		var c_phys = entity.get_component(C_Physics)

		if c_phys and c_phys.body:
			c_phys.body.velocity = final_vel
			c_phys.body.move_and_slide()
			# Sync Entity position from physics result so other systems
			# reading entity.global_position stay accurate.
			entity.global_position = c_phys.body.global_position

		elif "global_position" in entity:
			# Non-physics fallback: projectiles, floating pickups
			if c_loco and c_loco.current_velocity != Vector2.ZERO:
				entity.global_position += c_loco.current_velocity * delta
			else:
				entity.global_position += c_vel.direction * 200.0 * delta

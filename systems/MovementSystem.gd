class_name MovementSystem
extends System

const C_LOCOMOTION = preload("res://components/character/c_locomotion.gd")
const C_VELOCITY_MODIFIER = preload("res://components/character/c_velocity_modifier.gd")

func query() -> QueryBuilder:
	return q.with_all([C_Velocity])

func process(entities: Array[Entity], _components: Array, delta: float) -> void:
	for entity in entities:
		var c_vel = entity.get_component(C_Velocity) as C_Velocity
		var c_loco = entity.get_component(C_LOCOMOTION)
		var c_vel_mod = entity.get_component(C_VELOCITY_MODIFIER)
		
		if not c_vel:
			continue
			
		var speed = c_vel.speed
		var friction = 800.0
		
		if c_loco:
			speed *= c_loco.current_speed
			friction = c_loco.friction
			
		var modifier_vel = Vector2.ZERO
		if c_vel_mod:
			modifier_vel = c_vel_mod.velocity
			# Interpolate/decay external force against base friction
			c_vel_mod.velocity = c_vel_mod.velocity.move_toward(Vector2.ZERO, friction * delta)
			if c_vel_mod.velocity == Vector2.ZERO:
				cmd.remove_component(entity, C_VELOCITY_MODIFIER)
		
		if c_vel.direction != Vector2.ZERO or c_vel.knockback != Vector2.ZERO or modifier_vel != Vector2.ZERO:
			var velocity = c_vel.direction * speed + c_vel.knockback + modifier_vel
			if c_vel.knockback != Vector2.ZERO:
				c_vel.knockback = c_vel.knockback.move_toward(Vector2.ZERO, friction * delta)
			if "global_position" in entity:
				entity.global_position += velocity * delta

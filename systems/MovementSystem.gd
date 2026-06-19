class_name MovementSystem
extends System

func query() -> QueryBuilder:
	return q.with_all([C_Velocity])

func process(entities: Array[Entity], _components: Array, delta: float) -> void:
	for entity in entities:
		var c_vel = entity.get_component(C_Velocity) as C_Velocity
		if c_vel and (c_vel.direction != Vector2.ZERO or c_vel.knockback != Vector2.ZERO):
			var velocity = c_vel.direction * c_vel.speed + c_vel.knockback
			if c_vel.knockback != Vector2.ZERO:
				c_vel.knockback = c_vel.knockback.move_toward(Vector2.ZERO, 800.0 * delta)
			if "global_position" in entity:
				entity.global_position += velocity * delta

class_name KnockbackSystem
extends System

const C_PENDING_DAMAGE = preload("res://components/character/c_pending_damage.gd")
const C_VELOCITY_MODIFIER = preload("res://components/character/c_velocity_modifier.gd")

func query() -> QueryBuilder:
	return q.with_all([C_PENDING_DAMAGE])

func process(entities: Array[Entity], _components: Array, _delta: float) -> void:
	for entity in entities:
		var pending = entity.get_component(C_PENDING_DAMAGE)
		if pending and pending.knockback_vector != Vector2.ZERO:
			var c_vel_mod = entity.get_component(C_VELOCITY_MODIFIER)
			if c_vel_mod:
				c_vel_mod.velocity += pending.knockback_vector
			else:
				entity.add_component(C_VELOCITY_MODIFIER.new(pending.knockback_vector))

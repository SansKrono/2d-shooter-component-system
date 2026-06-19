class_name LifetimeSystem
extends System

func query() -> QueryBuilder:
	return q.with_all([C_Lifetime])

func process(entities: Array[Entity], _components: Array, delta: float) -> void:
	for entity in entities:
		var c_lifetime = entity.get_component(C_Lifetime) as C_Lifetime
		if c_lifetime:
			c_lifetime.time_left -= delta
			if c_lifetime.time_left <= 0.0:
				cmd.remove_entity(entity)

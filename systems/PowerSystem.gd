class_name PowerSystem
extends System

func query() -> QueryBuilder:
	return q.with_all([C_Power])

func process(entities: Array[Entity], _components: Array, delta: float) -> void:
	for entity in entities:
		var c_power = entity.get_component(C_Power) as C_Power
		if c_power and c_power.current < c_power.maximum:
			c_power.current = min(c_power.current + c_power.regen_rate * delta, c_power.maximum)

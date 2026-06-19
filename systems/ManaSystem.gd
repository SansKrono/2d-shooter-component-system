class_name ManaSystem
extends System

func query() -> QueryBuilder:
	return q.with_all([C_Mana])

func process(entities: Array[Entity], _components: Array, delta: float) -> void:
	for entity in entities:
		var c_mana = entity.get_component(C_Mana) as C_Mana
		if c_mana and c_mana.current < c_mana.maximum:
			c_mana.current = min(c_mana.current + c_mana.regen_rate * delta, c_mana.maximum)

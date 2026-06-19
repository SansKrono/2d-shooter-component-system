class_name HealthSystem
extends System

func query() -> QueryBuilder:
	return q.with_all([C_Health])

func process(entities: Array[Entity], _components: Array, _delta: float) -> void:
	for entity in entities:
		var health = entity.get_component(C_Health) as C_Health
		if health.current <= 0.0:
			print("Entity died: ", entity.name)
			cmd.remove_entity(entity)

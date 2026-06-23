class_name HealthSystem
extends System

const C_DEAD = preload("res://components/combat/c_dead.gd")

func query() -> QueryBuilder:
	return q.with_all([C_Health])

func process(entities: Array[Entity], _components: Array, _delta: float) -> void:
	for entity in entities:
		var health = entity.get_component(C_Health) as C_Health
		if health.current <= 0.0:
			if not entity.has_component(C_DEAD):
				print("[HealthSystem] Entity health hit <= 0, adding C_Dead to: ", entity.name)
				cmd.add_component(entity, C_DEAD.new(Time.get_ticks_msec() / 1000.0))

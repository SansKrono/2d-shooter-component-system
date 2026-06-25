class_name TrajectorySystem
extends System

func query() -> QueryBuilder:
	process_empty = false
	return q.with_all([])

func process(_entities: Array[Entity], _components: Array, _delta: float) -> void:
	pass

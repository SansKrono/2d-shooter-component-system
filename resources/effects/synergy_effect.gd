class_name SynergyEffect
extends Resource

@export var description: String = ""

func apply(_entity: Entity) -> void:
	pass

func unapply(_entity: Entity) -> void:
	pass

func get_stat_multiplier(_stat_name: String) -> float:
	return 1.0

func get_stat_additive(_stat_name: String) -> float:
	return 0.0

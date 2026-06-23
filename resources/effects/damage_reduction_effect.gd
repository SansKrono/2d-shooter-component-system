class_name DamageReductionEffect
extends SynergyEffect

@export var reduction: float = 0.3

func get_stat_multiplier(stat_name: String) -> float:
	if stat_name == "damage_taken":
		return 1.0 - reduction
	return 1.0

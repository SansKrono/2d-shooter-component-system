class_name DamageMultiplierEffect
extends SynergyEffect

@export var multiplier: float = 1.0

func get_stat_multiplier(stat_name: String) -> float:
	if stat_name == "damage":
		return multiplier
	return 1.0

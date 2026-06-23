class_name FireRateEffect
extends SynergyEffect

@export var fire_rate_multiplier: float = 1.2

func get_stat_multiplier(stat_name: String) -> float:
	if stat_name == "fire_rate":
		return fire_rate_multiplier
	return 1.0

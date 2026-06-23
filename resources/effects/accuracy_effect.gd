class_name AccuracyEffect
extends SynergyEffect

@export var accuracy_bonus: float = 0.25

func get_stat_additive(stat_name: String) -> float:
	if stat_name == "accuracy":
		return accuracy_bonus
	return 0.0

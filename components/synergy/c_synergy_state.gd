class_name C_SynergyState
extends Component

var active_synergies: Array[ItemSynergy] = []

signal synergy_activated(synergy: ItemSynergy)
signal synergy_deactivated(synergy: ItemSynergy)

func add_synergy(synergy: ItemSynergy) -> void:
	if synergy not in active_synergies:
		active_synergies.append(synergy)
		synergy_activated.emit(synergy)

func remove_synergy(synergy: ItemSynergy) -> void:
	if synergy in active_synergies:
		active_synergies.erase(synergy)
		synergy_deactivated.emit(synergy)

func get_active_synergies() -> Array[ItemSynergy]:
	return active_synergies.duplicate()

func clear_synergies() -> void:
	active_synergies.clear()

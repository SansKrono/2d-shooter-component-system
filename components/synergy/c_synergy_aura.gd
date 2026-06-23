class_name C_SynergyAura
extends Component

@export var aura_color: Color = Color.CYAN
@export var aura_intensity: float = 1.0

var active_synergy_effects: Dictionary = {}

func get_combined_color() -> Color:
	if active_synergy_effects.is_empty():
		return Color.WHITE

	var tech_count = 0
	var magic_count = 0
	var defensive_count = 0

	for synergy in active_synergy_effects.keys():
		if synergy.build_identity == "hacker":
			tech_count += 1
		elif synergy.build_identity == "mage":
			magic_count += 1
		if "defensive" in synergy.required_tags:
			defensive_count += 1

	if tech_count > 0 and magic_count > 0:
		return Color.MAGENTA
	elif tech_count > 0:
		return Color.CYAN
	elif magic_count > 0:
		return Color.MAGENTA
	elif defensive_count > 0:
		return Color.BLUE

	return Color.WHITE

func add_synergy_visual(synergy: ItemSynergy) -> void:
	active_synergy_effects[synergy] = true

func remove_synergy_visual(synergy: ItemSynergy) -> void:
	active_synergy_effects.erase(synergy)

func has_active_synergies() -> bool:
	return not active_synergy_effects.is_empty()

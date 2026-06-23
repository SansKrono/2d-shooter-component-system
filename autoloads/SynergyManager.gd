extends Node

const C_SYNERGY_STATE = preload("res://components/synergy/c_synergy_state.gd")

var all_synergies: Array[ItemSynergy] = []
var active_synergies: Array[ItemSynergy] = []
var tracked_entity: Entity = null

signal synergy_activated(synergy: ItemSynergy)
signal synergy_deactivated(synergy: ItemSynergy)

func _ready() -> void:
	all_synergies = _load_all_synergies()

func set_tracked_entity(entity: Entity) -> void:
	tracked_entity = entity
	if not entity.has_component(C_SYNERGY_STATE):
		entity.add_component(C_SYNERGY_STATE.new())

func update_synergies(player_items: Array[Relic]) -> void:
	var newly_active: Array[ItemSynergy] = []
	var newly_inactive: Array[ItemSynergy] = []

	for synergy in all_synergies:
		var should_be_active = synergy.matches_inventory(player_items)
		var is_active = synergy in active_synergies

		if should_be_active and not is_active:
			newly_active.append(synergy)
		elif not should_be_active and is_active:
			newly_inactive.append(synergy)

	for synergy in newly_active:
		active_synergies.append(synergy)
		_apply_synergy(synergy)
		synergy_activated.emit(synergy)

	for synergy in newly_inactive:
		active_synergies.erase(synergy)
		_unapply_synergy(synergy)
		synergy_deactivated.emit(synergy)

func get_active_synergies() -> Array[ItemSynergy]:
	return active_synergies.duplicate()

func _apply_synergy(synergy: ItemSynergy) -> void:
	if tracked_entity:
		var c_synergy_state = tracked_entity.get_component(C_SYNERGY_STATE) as C_SynergyState
		if c_synergy_state:
			c_synergy_state.add_synergy(synergy)

		for effect in synergy.synergy_effects:
			if effect:
				effect.apply(tracked_entity)

func _unapply_synergy(synergy: ItemSynergy) -> void:
	if tracked_entity:
		var c_synergy_state = tracked_entity.get_component(C_SYNERGY_STATE) as C_SynergyState
		if c_synergy_state:
			c_synergy_state.remove_synergy(synergy)

		for effect in synergy.synergy_effects:
			if effect:
				effect.unapply(tracked_entity)

func _load_all_synergies() -> Array[ItemSynergy]:
	var synergies: Array[ItemSynergy] = []
	var dir = DirAccess.open("res://resources/synergies/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var path = "res://resources/synergies/" + file_name
				var synergy = load(path) as ItemSynergy
				if synergy:
					synergies.append(synergy)
			file_name = dir.get_next()
	return synergies

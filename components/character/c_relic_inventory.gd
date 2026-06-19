class_name C_RelicInventory
extends Component

@export var relics: Array[Relic] = []

signal relic_added(relic: Relic)

func add_relic(entity: Entity, relic: Relic) -> void:
	relics.append(relic)
	
	# Apply all effects from the relic to the entity
	for effect in relic.effects:
		if effect:
			effect.apply(entity)
	
	relic_added.emit(relic)

func get_effects_of_type(type: Variant) -> Array:
	var results = []
	for relic in relics:
		for effect in relic.effects:
			if is_instance_of(effect, type):
				results.append(effect)
	return results

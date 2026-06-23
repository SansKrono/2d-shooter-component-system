class_name SynergyDetectionSystem
extends System

const C_RELIC_INVENTORY = preload("res://components/economy/c_relic_inventory.gd")

var synergy_manager = null
var tracked_entities: Array[Entity] = []

func query() -> QueryBuilder:
	return q.with_all([C_RELIC_INVENTORY])

func process(entities: Array[Entity], _components: Array, _delta: float) -> void:
	if not synergy_manager:
		synergy_manager = get_tree().root.get_node_or_null("SynergyManager")
		if synergy_manager and not entities.is_empty():
			synergy_manager.set_tracked_entity(entities[0])
			_setup_tracking(entities)

	if synergy_manager:
		_update_synergies(entities)

func _setup_tracking(entities: Array[Entity]) -> void:
	for entity in entities:
		var c_inv = entity.get_component(C_RELIC_INVENTORY) as C_RelicInventory
		if c_inv and not entity in tracked_entities:
			c_inv.relic_added.connect(_on_relic_added.bindv([entity]))
			tracked_entities.append(entity)

func _on_relic_added(_relic: Relic, entity: Entity) -> void:
	if synergy_manager:
		var c_inv = entity.get_component(C_RELIC_INVENTORY) as C_RelicInventory
		if c_inv:
			synergy_manager.update_synergies(c_inv.relics)

func _update_synergies(entities: Array[Entity]) -> void:
	for entity in entities:
		var c_inv = entity.get_component(C_RELIC_INVENTORY) as C_RelicInventory
		if c_inv:
			synergy_manager.update_synergies(c_inv.relics)

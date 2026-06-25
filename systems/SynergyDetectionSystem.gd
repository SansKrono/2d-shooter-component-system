class_name SynergyDetectionSystem
extends System

const C_RELIC_INVENTORY = preload("res://components/economy/c_relic_inventory.gd")

var synergy_manager = null
var _setup_done := false
var tracked_entities: Array[Entity] = []

func query() -> QueryBuilder:
	return q.with_all([C_RELIC_INVENTORY])

func process(entities: Array[Entity], _components: Array, _delta: float) -> void:
	if _setup_done:
		return
	if not synergy_manager:
		synergy_manager = get_tree().root.get_node_or_null("SynergyManager")
	if not synergy_manager or entities.is_empty():
		return
	synergy_manager.set_tracked_entity(entities[0])
	_setup_tracking(entities)
	_setup_done = true

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

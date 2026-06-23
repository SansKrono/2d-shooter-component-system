class_name SynergyAuraSystem
extends System

const C_SYNERGY_STATE = preload("res://components/synergy/c_synergy_state.gd")
const C_SYNERGY_AURA = preload("res://components/synergy/c_synergy_aura.gd")

var aura_nodes: Dictionary = {}

func query() -> QueryBuilder:
	return q.with_all([C_SYNERGY_STATE])

func process(entities: Array[Entity], _components: Array, _delta: float) -> void:
	for entity in entities:
		var c_synergy_state = entity.get_component(C_SYNERGY_STATE) as C_SYNERGY_STATE
		if not c_synergy_state:
			continue

		if not entity in aura_nodes:
			_setup_aura(entity)

		var aura_node = aura_nodes.get(entity)
		if aura_node:
			var synergies = c_synergy_state.get_active_synergies()
			if synergies.is_empty():
				aura_node.visible = false
			else:
				aura_node.visible = true
				_update_aura_color(aura_node, synergies)

func _setup_aura(entity: Entity) -> void:
	if not entity.has_component(C_SYNERGY_AURA):
		entity.add_component(C_SYNERGY_AURA.new())

	var aura_node = Node2D.new()
	aura_node.name = "SynergyAura"

	if "add_child" in entity:
		entity.add_child(aura_node)
		aura_nodes[entity] = aura_node

func _update_aura_color(aura_node: Node2D, synergies: Array[ItemSynergy]) -> void:
	var c_aura = aura_node.get_parent().get_component(C_SYNERGY_AURA) as C_SYNERGY_AURA

	for synergy in synergies:
		c_aura.add_synergy_visual(synergy)

	var color = c_aura.get_combined_color()
	if "modulate" in aura_node:
		aura_node.modulate = color

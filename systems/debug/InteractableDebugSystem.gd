class_name InteractableDebugSystem
extends System

const C_INTERACTABLE_SCRIPT = preload("res://components/world/c_interactable.gd")
const C_INTERACTABLE_DEBUG_SCRIPT = preload("res://components/debug/c_interactable_debug.gd")
const C_TRIGGER_SCRIPT = preload("res://components/world/c_trigger.gd")
const C_COLLECTIBLE_SCRIPT = preload("res://components/economy/c_collectible.gd")


func query() -> QueryBuilder:
	return q.with_all([C_INTERACTABLE_DEBUG_SCRIPT])

func process(entities: Array[Entity], _components: Array, _delta: float) -> void:
	for entity in entities:
		var c_debug = entity.get_component(C_INTERACTABLE_DEBUG_SCRIPT) as C_INTERACTABLE_DEBUG_SCRIPT
		if not c_debug:
			continue

		if not "global_position" in entity:
			continue

		var radius: float = 80.0
		if entity.has_component(C_INTERACTABLE_SCRIPT):
			var c_inter = entity.get_component(C_INTERACTABLE_SCRIPT) as C_INTERACTABLE_SCRIPT
			radius = c_inter.interaction_range
		elif entity.has_component(C_TRIGGER_SCRIPT):
			var c_trig = entity.get_component(C_TRIGGER_SCRIPT) as C_TRIGGER_SCRIPT
			radius = c_trig.trigger_range
		elif entity.has_component(C_COLLECTIBLE_SCRIPT):
			var c_coll = entity.get_component(C_COLLECTIBLE_SCRIPT) as C_COLLECTIBLE_SCRIPT
			radius = c_coll.collection_range

		var debug_node = entity.get_node_or_null("InteractionRangeDebug")
		if not debug_node:
			debug_node = Node2D.new()
			debug_node.name = "InteractionRangeDebug"
			
			var script = GDScript.new()
			script.source_code = "extends Node2D\n" + \
				"var radius: float = 80.0\n" + \
				"var color: Color = Color(0, 1, 0, 0.3)\n" + \
				"var line_width: float = 2.0\n" + \
				"func _draw() -> void:\n" + \
				"    draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, color, line_width, true)\n"
			script.reload()
			debug_node.set_script(script)
			entity.add_child(debug_node)

		debug_node.radius = radius
		debug_node.color = c_debug.color
		debug_node.line_width = c_debug.line_width
		debug_node.queue_redraw()

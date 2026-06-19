class_name InteractableDebugSystem
extends System

func query() -> QueryBuilder:
	return q.with_all([C_Interactable, C_InteractableDebug])

func process(entities: Array[Entity], _components: Array, _delta: float) -> void:
	for entity in entities:
		var c_inter = entity.get_component(C_Interactable) as C_Interactable
		var c_debug = entity.get_component(C_InteractableDebug) as C_InteractableDebug
		if not c_inter or not c_debug:
			continue

		if not "global_position" in entity:
			continue

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

		debug_node.radius = c_inter.interaction_range
		debug_node.color = c_debug.color
		debug_node.line_width = c_debug.line_width
		debug_node.queue_redraw()

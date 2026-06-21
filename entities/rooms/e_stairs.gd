@tool
class_name StairsEntity
extends Entity

func define_components() -> Array:
	return []

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return

	var area = get_node_or_null("Area2D") as Area2D
	if not area:
		return

	for overlapping_area in area.get_overlapping_areas():
		var target = overlapping_area.owner as Entity
		if not target:
			target = overlapping_area.get_parent() as Entity
		if target and target is Player:
			_descend_floor()
			break

func _descend_floor() -> void:
	print("[Stairs] Player stepped on stairs. Descending floor...")
	var systems_root = ECS.world.get_node(ECS.world.system_nodes_root)
	var gen_sys = systems_root.get_node_or_null("RoomGenerationSystem")
	if gen_sys:
		gen_sys.descend_floor()

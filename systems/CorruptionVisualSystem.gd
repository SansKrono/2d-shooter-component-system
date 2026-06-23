class_name CorruptionVisualSystem
extends System

const C_VELOCITY = preload("res://components/movement/c_velocity.gd")
const C_INPUT = preload("res://components/player/c_input.gd")
const CORRUPTION_COLOR: Color = Color(0.7, 0.1, 1.0)

var corruption_system: CorruptionSpreadingSystem = null

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_find_corruption_system()

func query() -> QueryBuilder:
	return q.with_all([C_VELOCITY])

func process(entities: Array[Entity], _components: Array, _delta: float) -> void:
	if not corruption_system:
		_find_corruption_system()
		if not corruption_system:
			return

	for entity in entities:
		if entity is Player:
			continue

		var sprite = entity.get_node_or_null("Sprite2D") as Sprite2D
		if not sprite:
			continue

		var corruption_level = corruption_system.get_point_corruption_level(entity.global_position)
		if corruption_level < 0.02:
			continue

		var base_color = sprite.modulate
		var new_color = base_color.lerp(CORRUPTION_COLOR, corruption_level * 0.8)
		sprite.modulate = new_color

func _find_corruption_system() -> void:
	if not _world:
		return

	var systems_node = _world.get_node_or_null(_world.system_nodes_root)
	if systems_node:
		corruption_system = systems_node.get_node_or_null("CorruptionSpreadingSystem")

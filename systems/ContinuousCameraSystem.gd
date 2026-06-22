class_name ContinuousCameraSystem
extends System

const C_INPUT = preload("res://components/character/c_input.gd")

@export var camera_smoothing: float = 8.0
@export var camera_bounds_enabled: bool = true

var camera_2d: Camera2D = null
var player: Entity = null

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_find_camera()

func query() -> QueryBuilder:
	return q.with_all([C_INPUT])

func process(entities: Array[Entity], _components: Array, delta: float) -> void:
	if not camera_2d or entities.is_empty():
		return

	var player_entity = entities[0] if entities.size() > 0 else null
	if player_entity:
		_update_camera_position(player_entity, delta)

func _find_camera() -> void:
	camera_2d = get_tree().root.get_node_or_null("DungeonCamera") as Camera2D
	if not camera_2d:
		print("[ContinuousCameraSystem] Warning: Camera2D not found in scene")

func _update_camera_position(player: Entity, delta: float) -> void:
	if not camera_2d:
		return

	var target_pos = player.global_position
	var current_pos = camera_2d.global_position

	camera_2d.global_position = current_pos.lerp(target_pos, camera_smoothing * delta)

	if camera_bounds_enabled:
		_apply_camera_bounds()

func _apply_camera_bounds() -> void:
	if not camera_2d:
		return

	var gen_sys = _world.get_node_or_null("Systems/DungeonGenerationSystem") as DungeonGenerationSystem
	if not gen_sys:
		return

	var dungeon_graph = gen_sys.get_dungeon_graph()
	if not dungeon_graph:
		return

	var bounds = dungeon_graph.dungeon_bounds
	var viewport_size = camera_2d.get_viewport_rect().size / camera_2d.zoom

	var min_x = bounds.position.x + viewport_size.x / 2
	var max_x = bounds.position.x + bounds.size.x - viewport_size.x / 2
	var min_y = bounds.position.y + viewport_size.y / 2
	var max_y = bounds.position.y + bounds.size.y - viewport_size.y / 2

	camera_2d.global_position.x = clamp(camera_2d.global_position.x, min_x, max_x)
	camera_2d.global_position.y = clamp(camera_2d.global_position.y, min_y, max_y)

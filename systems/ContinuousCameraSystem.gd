class_name ContinuousCameraSystem
extends System

const C_INPUT = preload("res://components/player/c_input.gd")

@export var camera_smoothing: float = 8.0
@export var camera_bounds_enabled: bool = true

var camera_2d: Camera2D = null
var player: Entity = null
var _camera_snapped: bool = false
var _first_valid_update: bool = true

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_find_camera()

func query() -> QueryBuilder:
	return q.with_all([C_INPUT])

func process(entities: Array[Entity], _components: Array, delta: float) -> void:
	# Camera now attached to player entity, no longer needed
	return

func _find_camera() -> void:
	camera_2d = get_tree().root.find_child("DungeonCamera", true, false) as Camera2D
	if not camera_2d:
		camera_2d = Camera2D.new()
		camera_2d.name = "DungeonCamera"
		# Must attach to 2D scene, not the root Window — Camera2D global_position
		# only affects the viewport when parented inside the 2D scene tree.
		get_tree().current_scene.add_child(camera_2d)
		camera_2d.make_current()
		print("[ContinuousCameraSystem] Created DungeonCamera")

func _update_camera_position(player_entity: Entity, delta: float) -> void:
	if not camera_2d:
		return

	var target_pos: Vector2 = player_entity.global_position

	# Force immediate snap on first meaningful update (after player is placed at non-origin)
	if _first_valid_update:
		_first_valid_update = false
		camera_2d.global_position = target_pos
		_camera_snapped = true
		return

	if not _camera_snapped:
		_camera_snapped = true

	camera_2d.global_position = camera_2d.global_position.lerp(target_pos, camera_smoothing * delta)

	if camera_bounds_enabled:
		_apply_camera_bounds()

func _apply_camera_bounds() -> void:
	if not camera_2d:
		return

	var gen_sys = get_node_or_null("../DungeonGenerationSystem") as DungeonGenerationSystem
	if not gen_sys:
		return

	var dungeon_graph = gen_sys.get_dungeon_graph()
	if not dungeon_graph:
		return

	var bounds = dungeon_graph.dungeon_bounds
	var viewport_size = camera_2d.get_viewport_rect().size / camera_2d.zoom

	if bounds.size.x < viewport_size.x:
		camera_2d.global_position.x = bounds.position.x + bounds.size.x / 2.0
	else:
		var min_x = bounds.position.x + viewport_size.x / 2.0
		var max_x = bounds.position.x + bounds.size.x - viewport_size.x / 2.0
		camera_2d.global_position.x = clamp(camera_2d.global_position.x, min_x, max_x)

	if bounds.size.y < viewport_size.y:
		camera_2d.global_position.y = bounds.position.y + bounds.size.y / 2.0
	else:
		var min_y = bounds.position.y + viewport_size.y / 2.0
		var max_y = bounds.position.y + bounds.size.y - viewport_size.y / 2.0
		camera_2d.global_position.y = clamp(camera_2d.global_position.y, min_y, max_y)

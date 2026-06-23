class_name DungeonGenerationSystem
extends System

const C_DUNGEON_GRAPH  = preload("res://components/world/c_dungeon_graph.gd")
const C_INPUT          = preload("res://components/player/c_input.gd")
const C_TRANSFORM      = preload("res://components/movement/c_transform.gd")
const ROOM_GRAPH_GEN   = preload("res://components/procedural/RoomGraphGenerator.gd")
const ROOM_PLACER      = preload("res://components/procedural/RoomPlacer.gd")
const TILE_CARVER      = preload("res://components/procedural/TileMapCarver.gd")
const DUNGEON_SCRIPT   = preload("res://entities/environmental/e_continuous_dungeon.gd")
const DEBUG_SCRIPT     = preload("res://systems/debug/DungeonDebugDraw.gd")

@export var run_seed: int = 12345
@export var floor_number: int = 1
@export var enable_debug_draw: bool = true

var _dungeon_graph: C_DungeonGraph = null
var _generated: bool = false

func query() -> QueryBuilder:
	process_empty = true
	return q.with_all([])

func process(_entities: Array[Entity], _components: Array, _delta: float) -> void:
	if not _generated:
		_generated = true
		_run_generation()

func _run_generation() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _floor_seed(run_seed, floor_number)

	# 1. Build room graph
	var graph_gen := ROOM_GRAPH_GEN.new(rng)
	var rooms: Array = graph_gen.generate(floor_number)
	var edges: Array = graph_gen.edges

	# 2. Assign world positions
	var placer := ROOM_PLACER.new()
	placer.place(rooms)

	# 3. Obtain or create dungeon entity with four-layer TileMap
	var dungeon_entity: Node = _get_or_create_dungeon_entity()

	# Wait a frame so _ready() on the new entity has run
	await get_tree().process_frame

	# 4. Resolve TileMapLayer references
	var floor_layers: Dictionary = {}
	var wall_layer: Object = null
	var tm_root: Node = dungeon_entity.get_node_or_null("DungeonTileMap")
	if tm_root:
		floor_layers = {
			"tech":       tm_root.get_node_or_null("FloorTech"),
			"hybrid":     tm_root.get_node_or_null("FloorHybrid"),
			"corruption": tm_root.get_node_or_null("FloorCorruption"),
		}
		wall_layer = tm_root.get_node_or_null("Walls")

	# 5. Carve TileMap
	var carver := TILE_CARVER.new(floor_layers, wall_layer, rng)
	carver.carve(rooms, edges)

	# 6. Store graph component on dungeon entity (pre-declared in define_components)
	var graph: C_DungeonGraph = dungeon_entity.get_component(C_DUNGEON_GRAPH)
	if not graph:
		push_error("[DungeonGen] dungeon entity missing C_DungeonGraph component")
		return
	graph.rooms = rooms
	graph.edges = edges
	graph.floor_number = floor_number
	graph.run_seed = run_seed
	for r in rooms:
		match r.room_type:
			"start": graph.start_room_id = r.id
			"boss":  graph.boss_room_id  = r.id
	graph.current_room_id = graph.start_room_id

	# Calculate dungeon bounds in pixels
	var min_x: float = INF
	var max_x: float = -INF
	var min_y: float = INF
	var max_y: float = -INF
	var size_tiles: Dictionary = {"small": 12, "medium": 16, "large": 20}
	for r in rooms:
		var tile_count: int = size_tiles.get(r.size, 16)
		var room_pixel_size: float = tile_count * 32.0
		var half_size: float = room_pixel_size / 2.0
		var r_min_x: float = r.world_pos.x - half_size
		var r_max_x: float = r.world_pos.x + half_size
		var r_min_y: float = r.world_pos.y - half_size
		var r_max_y: float = r.world_pos.y + half_size
		if r_min_x < min_x: min_x = r_min_x
		if r_max_x > max_x: max_x = r_max_x
		if r_min_y < min_y: min_y = r_min_y
		if r_max_y > max_y: max_y = r_max_y
	var margin: float = 64.0
	graph.dungeon_bounds = Rect2(
		min_x - margin,
		min_y - margin,
		(max_x - min_x) + margin * 2.0,
		(max_y - min_y) + margin * 2.0
	)

	_dungeon_graph = graph


	# 7. Spawn doors at corridor mouths
	_spawn_doors(edges, dungeon_entity)

	# 8. Place player at start room centre
	_place_player(graph)

	# 9. Debug visualisation
	if enable_debug_draw:
		_create_debug_draw(graph)

	print("[DungeonGen] Floor %d: %d rooms, %d edges, seed=%d" % [
		floor_number, rooms.size(), edges.size(), run_seed
	])

func _floor_seed(p_seed: int, p_floor: int) -> int:
	# FNV-style mix: same seed + floor always produces identical dungeon
	return p_seed ^ (p_floor * 2654435761)

func _get_or_create_dungeon_entity() -> Node:
	# Look for existing dungeon entity first
	var entities_root: Node = _get_entities_root()
	for child in entities_root.get_children():
		if child.get_script() == DUNGEON_SCRIPT:
			return child

	var entity = DUNGEON_SCRIPT.new()
	entities_root.add_child(entity)
	return entity

func _get_entities_root() -> Node:
	if _world:
		var root_path = _world.entity_nodes_root
		var n: Node = get_node_or_null(root_path)
		if n:
			return n
	return get_tree().root

func _spawn_doors(edges: Array, dungeon_entity: Node) -> void:
	var DOOR_SCENE_PATH := "res://entities/rooms/e_door.tscn"
	if not ResourceLoader.exists(DOOR_SCENE_PATH):
		return
	var DOOR_SCENE: PackedScene = load(DOOR_SCENE_PATH)
	var C_DOOR_SCRIPT = preload("res://components/world/c_door.gd")

	for edge in edges:
		for door_tile_pos in edge.door_positions:
			var door: Node = DOOR_SCENE.instantiate()
			dungeon_entity.add_child(door)
			door.global_position = Vector2(door_tile_pos) * 32.0
			if door.has_method("get_component"):
				var c_door = door.get_component(C_DOOR_SCRIPT)
				if c_door:
					c_door.is_locked = false

func _place_player(graph: C_DungeonGraph) -> void:
	if not _world:
		return
	var players: Array = _world.query.with_all([C_INPUT]).execute()
	var start = graph.get_room(graph.start_room_id)
	if not start or players.is_empty():
		return
	var player = players[0]
	player.global_position = start.world_pos

	var phys_body = player.get_node_or_null("PhysicsBody")
	if phys_body:
		phys_body.global_position = start.world_pos
		phys_body.position = Vector2.ZERO

	var trans = player.get_component(C_TRANSFORM)
	if trans:
		trans.position = start.world_pos
	print("[DungeonGen] Player placed at %s" % str(start.world_pos))

func _create_debug_draw(graph: C_DungeonGraph) -> void:
	var node := Node2D.new()
	node.name = "DungeonDebugDraw"
	node.set_script(DEBUG_SCRIPT)
	get_tree().root.add_child(node)
	call_deferred("_assign_debug", node, graph)

func _assign_debug(node: Node2D, graph: C_DungeonGraph) -> void:
	if is_instance_valid(node):
		node.set_meta("dungeon_graph", graph)
		node.queue_redraw()

func get_dungeon_graph() -> C_DungeonGraph:
	return _dungeon_graph

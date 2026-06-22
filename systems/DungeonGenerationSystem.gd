class_name DungeonGenerationSystem
extends System

const C_DUNGEON_GRAPH = preload("res://components/character/c_dungeon_graph.gd")
const C_TRANSFORM = preload("res://components/character/c_transform.gd")
const C_INPUT = preload("res://components/character/c_input.gd")
const DUNGEON_BSP_GENERATOR = preload("res://components/procedural/DungeonBSPGenerator.gd")
const CORRIDOR_GENERATOR = preload("res://components/procedural/CorridorGenerator.gd")
const CONTINUOUS_DUNGEON = preload("res://entities/environmental/e_continuous_dungeon.gd")

@export var dungeon_bounds: Rect2i = Rect2i(0, 0, 2000, 2000)
@export var target_chamber_count: int = 8
@export var map_seed: int = 12345
@export var enable_debug_draw: bool = true
@export var enable_tilemap: bool = true

var dungeon_graph: C_DUNGEON_GRAPH = null
var continuous_dungeon: Node2D = null
var debug_draw_node: Node2D = null
var generated: bool = false
var camera_2d: Camera2D = null

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	generate_dungeon()
	_setup_camera()
	_setup_continuous_world()

func query() -> QueryBuilder:
	process_empty = true
	return q.with_all([])

func process(_entities: Array[Entity], _components: Array, _delta: float) -> void:
	pass

func generate_dungeon() -> void:
	if generated:
		return
	generated = true

	dungeon_graph = C_DUNGEON_GRAPH.new()
	dungeon_graph.dungeon_bounds = dungeon_bounds

	var bsp_gen = DUNGEON_BSP_GENERATOR.new(map_seed)
	var bsp_chambers = bsp_gen.generate(dungeon_bounds, target_chamber_count)

	for chamber in bsp_chambers:
		var graph_chamber = C_DUNGEON_GRAPH.Chamber.new(
			chamber.id,
			chamber.rect,
			chamber.chamber_type,
			0.0
		)
		dungeon_graph.chambers.append(graph_chamber)

	var corridor_gen = CORRIDOR_GENERATOR.new(map_seed)
	var corridors = corridor_gen.generate_connections(bsp_chambers)

	for corridor in corridors:
		var graph_corridor = C_DUNGEON_GRAPH.Corridor.new(
			corridor.id,
			corridor.from_chamber,
			corridor.to_chamber,
			corridor.path,
			corridor.width,
			0.0
		)
		dungeon_graph.corridors.append(graph_corridor)

		var from_chamber = dungeon_graph.get_chamber(corridor.from_chamber)
		var to_chamber = dungeon_graph.get_chamber(corridor.to_chamber)
		if from_chamber:
			from_chamber.connected_corridors.append(corridor.id)
		if to_chamber:
			to_chamber.connected_corridors.append(corridor.id)

	_init_corruption_zones()
	_create_debug_visualization()

	print("[DungeonGen] Dungeon generated: %d chambers, %d corridors" % [
		dungeon_graph.chambers.size(),
		dungeon_graph.corridors.size()
	])

func _init_corruption_zones() -> void:
	for chamber in dungeon_graph.chambers:
		if chamber.chamber_type == "boss":
			var zone = C_DUNGEON_GRAPH.CorruptionZone.new(
				chamber.rect.get_center(),
				300.0,
				1.0
			)
			dungeon_graph.corruption_zones.append(zone)

			for other_chamber in dungeon_graph.chambers:
				if other_chamber.chamber_type == "normal":
					var dist = chamber.rect.get_center().distance_to(other_chamber.rect.get_center())
					if dist < 600.0:
						other_chamber.corruption_level = 1.0 - (dist / 600.0)

func _create_debug_visualization() -> void:
	if not enable_debug_draw:
		return

	if debug_draw_node:
		debug_draw_node.queue_free()

	debug_draw_node = Node2D.new()
	debug_draw_node.name = "DungeonDebugDraw"
	debug_draw_node.set_script(preload("res://systems/DungeonDebugDraw.gd"))
	get_tree().root.add_child(debug_draw_node)

	call_deferred("_assign_debug_graph", debug_draw_node)

func _assign_debug_graph(draw_node: Node2D) -> void:
	if draw_node and draw_node.is_node_ready():
		draw_node.dungeon_graph = dungeon_graph

func get_dungeon_graph() -> C_DUNGEON_GRAPH:
	if not generated:
		generate_dungeon()
	return dungeon_graph

func get_chamber_at_position(pos: Vector2) -> C_DUNGEON_GRAPH.Chamber:
	if dungeon_graph:
		return dungeon_graph.find_chamber_at_position(pos)
	return null

func _setup_continuous_world() -> void:
	if not enable_tilemap or not dungeon_graph:
		return

	if continuous_dungeon:
		continuous_dungeon.queue_free()

	continuous_dungeon = CONTINUOUS_DUNGEON.new()
	var entities_root = _world.get_node(_world.entity_nodes_root)
	entities_root.add_child(continuous_dungeon)
	continuous_dungeon.setup_from_graph(dungeon_graph)

	_position_player_in_dungeon()

	print("[DungeonGen] Continuous world created")

func _position_player_in_dungeon() -> void:
	if not _world or not continuous_dungeon:
		return

	var player: Entity = null
	var players = _world.query.with_all([C_INPUT]).execute()
	for p in players:
		if p is Player:
			player = p
			break

	if not player:
		return

	var start_chamber = dungeon_graph.chambers[0] if dungeon_graph.chambers.size() > 0 else null
	if start_chamber:
		var spawn_pos = start_chamber.rect.get_center()
		player.global_position = spawn_pos
		var trans = player.get_component(C_TRANSFORM)
		if trans:
			trans.position = spawn_pos
		print("[DungeonGen] Player positioned at dungeon start: %s" % str(spawn_pos))

func _setup_camera() -> void:
	if camera_2d:
		camera_2d.queue_free()

	camera_2d = Camera2D.new()
	camera_2d.name = "DungeonCamera"
	camera_2d.zoom = Vector2(1.0, 1.0)
	get_tree().root.add_child(camera_2d)

	var player: Entity = null
	if _world:
		var players = _world.query.with_all([C_INPUT]).execute()
		for p in players:
			if p is Player:
				player = p
				break

	if player:
		camera_2d.global_position = player.global_position
		camera_2d.set_physics_process(true)

	print("[DungeonGen] Camera2D created and positioned")

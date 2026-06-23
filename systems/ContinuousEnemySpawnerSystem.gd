class_name ContinuousEnemySpawnerSystem
extends System

const ENEMY_SCENE = preload("res://entities/enemies/e_enemy.tscn")
const RELIC_PICKUP_SCENE = preload("res://entities/environmental/e_relic.tscn")
const AMPLIFICATION_ARRAY = preload("res://resources/relics/amplification_array.tres")
const C_TRANSFORM = preload("res://components/movement/c_transform.gd")
const CORRUPTED_SERVER = preload("res://entities/environmental/e_corrupted_server.gd")

@export var enemy_spawn_enabled: bool = true
@export var base_enemy_count: int = 2

var spawned_enemies: Dictionary = {}
var dungeon_graph: Resource = null
var generation_complete: bool = false

func query() -> QueryBuilder:
	process_empty = true
	return q.with_all([])

func process(_entities: Array[Entity], _components: Array, _delta: float) -> void:
	if not enemy_spawn_enabled or generation_complete:
		return

	if not generation_complete:
		if _spawn_initial_enemies():
			generation_complete = true

func _spawn_initial_enemies() -> bool:
	if not _world:
		print("[ContinuousEnemySpawner] No world reference")
		return false

	var system_path = str(_world.system_nodes_root) + "/DungeonGenerationSystem"
	var gen_sys = _world.get_node_or_null(system_path)
	if not gen_sys:
		print("[ContinuousEnemySpawner] DungeonGenerationSystem not found at %s" % system_path)
		return false

	if not gen_sys.has_method("get_dungeon_graph"):
		print("[ContinuousEnemySpawner] DungeonGenerationSystem doesn't have get_dungeon_graph")
		return false

	dungeon_graph = gen_sys.get_dungeon_graph()
	if not dungeon_graph:
		return false # DungeonGenerationSystem has not finished generating the graph yet

	print("[ContinuousEnemySpawner] Spawning entities across %d rooms..." % dungeon_graph.rooms.size())

	for chamber in dungeon_graph.rooms:
		if chamber.room_type == "boss":
			_spawn_boss_in_chamber(chamber)
		elif chamber.room_type == "treasure":
			_spawn_relic_in_chamber(chamber)
		elif chamber.room_type == "shop":
			_spawn_shop_in_chamber(chamber)
		elif chamber.room_type == "normal":
			_spawn_enemies_in_chamber(chamber)

	return true

func _spawn_enemies_in_chamber(chamber: Object) -> void:
	var size_tiles := {"small": 12, "medium": 16, "large": 20}
	var tile_count: int = size_tiles.get(chamber.size, 16)
	var room_pixel_size: float = tile_count * 32.0
	var half_size: float = room_pixel_size / 2.0
	var rect := Rect2(chamber.world_pos - Vector2(half_size, half_size), Vector2(room_pixel_size, room_pixel_size))

	var count = base_enemy_count
	var corruption = chamber.corruption_level
	count = int(count * (1.0 + corruption))

	print("[EnemySpawner] Spawning %d enemies in normal chamber %d at %s (corruption: %.1f)" % [count, chamber.id, str(chamber.world_pos), corruption])

	for _i in range(count):
		var spawn_pos = _random_pos_in_rect(rect)
		_spawn_enemy_at(spawn_pos)

	if corruption > 0.5:
		var server_pos = _random_pos_in_rect(rect)
		_spawn_corrupted_server(server_pos)

func _spawn_boss_in_chamber(chamber: Object) -> void:
	var spawn_pos = chamber.world_pos
	var boss = ENEMY_SCENE.instantiate() as Entity

	if boss:
		boss.position = spawn_pos
		var trans = boss.get_component(C_TRANSFORM)
		if trans:
			trans.position = spawn_pos

		var entities_root = _world.get_node(_world.entity_nodes_root)
		entities_root.add_child(boss)
		_world.add_entity(boss)

		spawned_enemies[chamber.id] = boss
		print("[EnemySpawner] Boss spawned at chamber %d: %s" % [chamber.id, str(spawn_pos)])

func _spawn_relic_in_chamber(chamber: Object) -> void:
	var spawn_pos = chamber.world_pos
	var relic = RELIC_PICKUP_SCENE.instantiate() as Entity

	if relic:
		relic.name = "TreasureRelic"
		relic.position = spawn_pos
		relic.relic_resource = AMPLIFICATION_ARRAY

		var entities_root = _world.get_node(_world.entity_nodes_root)
		entities_root.add_child(relic)
		_world.add_entity(relic)
		print("[EnemySpawner] Treasure spawned at chamber %d: %s" % [chamber.id, str(spawn_pos)])

func _spawn_shop_in_chamber(chamber: Object) -> void:
	var spawn_pos = chamber.world_pos
	var relic = RELIC_PICKUP_SCENE.instantiate() as Entity

	if relic:
		relic.name = "ShopRelic"
		relic.position = spawn_pos
		relic.relic_resource = AMPLIFICATION_ARRAY

		var entities_root = _world.get_node(_world.entity_nodes_root)
		entities_root.add_child(relic)
		_world.add_entity(relic)
		print("[EnemySpawner] Shop item spawned at chamber %d: %s" % [chamber.id, str(spawn_pos)])

func _spawn_enemy_at(pos: Vector2) -> void:
	var enemy = ENEMY_SCENE.instantiate() as Entity
	if enemy:
		enemy.position = pos
		var trans = enemy.get_component(C_TRANSFORM)
		if trans:
			trans.position = pos

		var entities_root = _world.get_node(_world.entity_nodes_root)
		entities_root.add_child(enemy)
		_world.add_entity(enemy)

func _spawn_corrupted_server(pos: Vector2) -> void:
	var server = CORRUPTED_SERVER.new()
	if server:
		var trans = C_TRANSFORM.new()
		trans.position = pos
		server.add_component(trans)

		var entities_root = _world.get_node(_world.entity_nodes_root)
		entities_root.add_child(server)
		_world.add_entity(server)
		print("[EnemySpawner] Corrupted server spawned at %s" % str(pos))

func _random_pos_in_rect(rect: Rect2) -> Vector2:
	var rng = RandomNumberGenerator.new()
	var x = rng.randf_range(rect.position.x + 20.0, rect.position.x + rect.size.x - 20.0)
	var y = rng.randf_range(rect.position.y + 20.0, rect.position.y + rect.size.y - 20.0)
	return Vector2(x, y)

class_name CorruptionSpreadingSystem
extends System

@export var spreading_enabled: bool = true
@export var spread_radius: float = 300.0
@export var spread_rate: float = 0.1
@export var max_corruption: float = 1.0

var dungeon_graph: Resource = null
var spread_timer: float = 0.0
var spread_interval: float = 1.0

func query() -> QueryBuilder:
	process_empty = true
	return q.with_all([])

func process(_entities: Array[Entity], _components: Array, delta: float) -> void:
	if not spreading_enabled:
		return

	if not dungeon_graph:
		_fetch_dungeon_graph()

	if dungeon_graph:
		spread_timer += delta
		if spread_timer >= spread_interval:
			_spread_corruption()
			spread_timer = 0.0

func _fetch_dungeon_graph() -> void:
	var gen_sys = _world.get_node_or_null("Systems/DungeonGenerationSystem") as DungeonGenerationSystem
	if gen_sys:
		dungeon_graph = gen_sys.get_dungeon_graph()

func _spread_corruption() -> void:
	if not dungeon_graph or dungeon_graph.corruption_zones.is_empty():
		return

	for zone in dungeon_graph.corruption_zones:
		_spread_from_zone(zone)

func _spread_from_zone(zone: Object) -> void:
	if not dungeon_graph:
		return

	for chamber in dungeon_graph.chambers:
		var chamber_center = chamber.rect.get_center()
		var dist = zone.center.distance_to(chamber_center)

		if dist <= zone.radius:
			var intensity = 1.0 - (dist / zone.radius)
			chamber.corruption_level = minf(
				chamber.corruption_level + (spread_rate * intensity),
				max_corruption
			)

func get_chamber_corruption_level(chamber_id: int) -> float:
	if not dungeon_graph:
		return 0.0

	for chamber in dungeon_graph.chambers:
		if chamber.id == chamber_id:
			return chamber.corruption_level

	return 0.0

func get_point_corruption_level(pos: Vector2) -> float:
	if not dungeon_graph:
		return 0.0

	var chamber = dungeon_graph.find_chamber_at_position(pos)
	if chamber:
		return chamber.corruption_level

	return 0.0

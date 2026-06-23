class_name MinimapSystem
extends System

const C_DUNGEON_GRAPH = preload("res://components/world/c_dungeon_graph.gd")
const MINIMAP_DRAW    = preload("res://systems/MinimapDrawNode.gd")

var _graph: C_DungeonGraph = null
var _draw_node: Node2D = null

func query() -> QueryBuilder:
	process_empty = true
	return q.with_all([])

func process(_entities: Array[Entity], _components: Array, _delta: float) -> void:
	if _graph:
		return
	if not _world:
		return
	# Search all entities that have C_DungeonGraph
	var candidates: Array = _world.query.with_all([C_DUNGEON_GRAPH]).execute()
	for entity in candidates:
		var g = entity.get_component(C_DUNGEON_GRAPH)
		if g and g.rooms.size() > 0:
			_graph = g
			_setup_canvas()
			reveal_room(g.start_room_id)
			break

func reveal_room(room_id: int) -> void:
	if not _graph:
		return
	var room = _graph.get_room(room_id)
	if room:
		room.is_visited = true
	_graph.current_room_id = room_id
	if _draw_node:
		_draw_node.dungeon_graph = _graph
		_draw_node.queue_redraw()

func _setup_canvas() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 10
	get_tree().root.add_child(canvas)

	_draw_node = Node2D.new()
	_draw_node.set_script(MINIMAP_DRAW)
	_draw_node.dungeon_graph = _graph
	canvas.add_child(_draw_node)

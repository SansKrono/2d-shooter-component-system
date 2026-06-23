class_name C_DungeonGraph
extends Component

class RoomEdge:
	var from_id: int
	var to_id: int
	var jog_offset: int = 0
	var jog_axis: String = "horizontal"
	var door_positions: Array[Vector2i] = []

	func _init(f: int, t: int, jog: int = 0, axis: String = "horizontal") -> void:
		from_id = f
		to_id = t
		jog_offset = jog
		jog_axis = axis

var rooms: Array = []   # Array of C_RoomNode
var edges: Array = []   # Array of RoomEdge
var start_room_id: int = -1
var boss_room_id: int = -1
var current_room_id: int = -1
var floor_number: int = 1
var run_seed: int = 0
var dungeon_bounds: Rect2 = Rect2()
var corruption_zones: Array = []


func get_room(id: int) -> C_RoomNode:
	for r in rooms:
		if r.id == id:
			return r
	return null

func get_connected_rooms(id: int) -> Array:
	var room = get_room(id)
	if not room:
		return []
	var result = []
	for cid in room.connections:
		var cr = get_room(cid)
		if cr:
			result.append(cr)
	return result

func get_edge(from_id: int, to_id: int) -> RoomEdge:
	for e in edges:
		if (e.from_id == from_id and e.to_id == to_id) or \
		   (e.from_id == to_id and e.to_id == from_id):
			return e
	return null

func get_room_at_grid(pos: Vector2i) -> C_RoomNode:
	for r in rooms:
		if r.grid_pos == pos:
			return r
	return null

func find_room_at_position(pos: Vector2) -> C_RoomNode:
	var size_tiles := {"small": 12, "medium": 16, "large": 20}
	for r in rooms:
		var tile_count: int = size_tiles.get(r.size, 16)
		var room_pixel_size: float = tile_count * 32.0
		var half_size: float = room_pixel_size / 2.0
		var rect := Rect2(r.world_pos - Vector2(half_size, half_size), Vector2(room_pixel_size, room_pixel_size))
		if rect.has_point(pos):
			return r
	return null

func find_chamber_at_position(pos: Vector2) -> C_RoomNode:
	return find_room_at_position(pos)

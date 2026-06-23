class_name TileMapCarver
extends RefCounted

const TILESET_SOURCE: int = 0
const TILE_SIZE: int = 32

# Floor tile
const FLOOR           := Vector2i(2, 4)

# Wall tiles (top-down orthographic) — 8×10 atlas
# WALL_TOP    = floor is BELOW this tile (north wall, facing player)
# WALL_BOTTOM = floor is ABOVE this tile (south wall)
# WALL_LEFT   = floor is to the RIGHT of this tile
# WALL_RIGHT  = floor is to the LEFT of this tile
const WALL_TOP        := Vector2i(0, 8)
const WALL_BOTTOM     := Vector2i(2, 8)
const WALL_LEFT       := Vector2i(3, 8)
const WALL_RIGHT      := Vector2i(1, 8)
const WALL_CORNER_TL  := Vector2i(0, 0)
const WALL_CORNER_TR  := Vector2i(7, 0)
const WALL_CORNER_BL  := Vector2i(0, 7)
const WALL_CORNER_BR  := Vector2i(7, 7)
const WALL_INNER_TL   := Vector2i(5, 8)
const WALL_INNER_TR   := Vector2i(4, 8)
const WALL_INNER_BL   := Vector2i(5, 9)
const WALL_INNER_BR   := Vector2i(4, 9)
const WALL_STONE      := Vector2i(1, 1)   # solid fill — complex adjacency or isolated

const SIZE_TILES: Dictionary = {
	"small":  12,
	"medium": 16,
	"large":  20,
}

const ZONE_CORRUPTION_RANK: Dictionary = {
	"tech": 0,
	"hybrid": 1,
	"corruption": 2,
}

const PREFAB_ROOT: String = "res://entities/rooms/prefabs/"

var floor_layers: Dictionary = {}  # {"tech": TileMapLayer, "hybrid": ..., "corruption": ...}
var wall_layer: Object = null      # TileMapLayer
var rng: RandomNumberGenerator = null

func _init(p_floor_layers: Dictionary, p_wall_layer: Object, p_rng: RandomNumberGenerator) -> void:
	floor_layers = p_floor_layers
	wall_layer = p_wall_layer
	rng = p_rng

func carve(rooms: Array, edges: Array) -> void:
	var all_floor_positions: Array[Vector2i] = []

	for room in rooms:
		var positions = _stamp_room(room)
		all_floor_positions.append_array(positions)

	for edge in edges:
		var positions = _carve_corridor(edge, rooms)
		all_floor_positions.append_array(positions)

	if wall_layer:
		_generate_walls(all_floor_positions)

func _stamp_room(room) -> Array[Vector2i]:
	var tile_count: int = SIZE_TILES.get(room.size, 16)
	var shape: Array = _get_room_shape(room, tile_count)
	var layer = _get_floor_layer(room.zone)
	if not layer:
		return []

	@warning_ignore("integer_division")
	var origin: Vector2i = Vector2i(
		int(room.world_pos.x) / TILE_SIZE - tile_count / 2,
		int(room.world_pos.y) / TILE_SIZE - tile_count / 2
	)

	var result: Array[Vector2i] = []
	for local_pos in shape:
		var world_tile: Vector2i = origin + local_pos
		layer.set_cell(world_tile, TILESET_SOURCE, FLOOR)
		result.append(world_tile)

	return result

func _get_room_shape(room, tile_count: int) -> Array:
	# L-shape for normal_medium_c prefab key
	if room.prefab_key.ends_with("_c") and room.room_type == "normal" and room.size == "medium":
		return _shape_l(tile_count, tile_count, 5, 5)
	return _shape_rect(tile_count, tile_count)

func _shape_rect(w: int, h: int) -> Array:
	var result: Array = []
	for x in range(w):
		for y in range(h):
			result.append(Vector2i(x, y))
	return result

func _shape_l(w: int, h: int, cut_x: int, cut_y: int) -> Array:
	var result: Array = []
	for x in range(w):
		for y in range(h):
			if x >= (w - cut_x) and y >= (h - cut_y):
				continue
			result.append(Vector2i(x, y))
	return result

func _carve_corridor(edge, rooms: Array) -> Array[Vector2i]:
	var from_room = _find_room(rooms, edge.from_id)
	var to_room   = _find_room(rooms, edge.to_id)
	if not from_room or not to_room:
		return []

	# Choose floor layer by more-corrupted zone
	var zone: String
	if ZONE_CORRUPTION_RANK.get(from_room.zone, 0) >= ZONE_CORRUPTION_RANK.get(to_room.zone, 0):
		zone = from_room.zone
	else:
		zone = to_room.zone
	var layer = _get_floor_layer(zone)
	if not layer:
		return []

	var from_tiles: int = SIZE_TILES.get(from_room.size, 16)
	var to_tiles: int   = SIZE_TILES.get(to_room.size, 16)

	@warning_ignore("integer_division")
	var from_centre: Vector2i = Vector2i(
		int(from_room.world_pos.x) / TILE_SIZE,
		int(from_room.world_pos.y) / TILE_SIZE
	)
	@warning_ignore("integer_division")
	var to_centre: Vector2i = Vector2i(
		int(to_room.world_pos.x) / TILE_SIZE,
		int(to_room.world_pos.y) / TILE_SIZE
	)

	var delta: Vector2i = to_room.grid_pos - from_room.grid_pos
	var primary_horiz: bool = abs(delta.x) >= abs(delta.y)

	var result: Array[Vector2i] = []
	var jog: int = edge.jog_offset

	if primary_horiz:
		# Horizontal primary: from exits right/left, to enters left/right
		@warning_ignore("integer_division")
		var from_edge_x: int = from_centre.x + (from_tiles / 2) * sign(delta.x)
		@warning_ignore("integer_division")
		var to_edge_x: int   = to_centre.x   - (to_tiles   / 2) * sign(delta.x)
		var from_y: int = from_centre.y
		var to_y:   int = to_centre.y

		# Door position at from-room mouth
		var from_door := Vector2i(from_edge_x, from_y)
		# Travel along x with jog applied as y offset
		var jog_y: int = from_y + jog * (1 if to_y >= from_y else -1)
		@warning_ignore("integer_division")
		var mid_x: int = from_edge_x + (to_edge_x - from_edge_x) / 2

		# Segment 1: from_edge_x → mid_x at from_y
		for x in range(min(from_edge_x, mid_x), max(from_edge_x, mid_x) + 1):
			result.append_array(_paint_horiz_segment(layer, x, from_y))

		# Jog: vertical segment from_y → jog_y at mid_x
		if jog > 0:
			for y in range(min(from_y, jog_y), max(from_y, jog_y) + 1):
				result.append_array(_paint_vert_segment(layer, mid_x, y))

		# Segment 2: mid_x → to_edge_x at jog_y
		for x in range(min(mid_x, to_edge_x), max(mid_x, to_edge_x) + 1):
			result.append_array(_paint_horiz_segment(layer, x, jog_y))

		# Final vertical to align to to_y
		if jog_y != to_y:
			for y in range(min(jog_y, to_y), max(jog_y, to_y) + 1):
				result.append_array(_paint_vert_segment(layer, to_edge_x, y))

		# Door positions: centre tile of 3-tile opening at each room mouth
		edge.door_positions.assign([from_door, Vector2i(to_edge_x, to_y)])

	else:
		# Vertical primary
		@warning_ignore("integer_division")
		var from_edge_y: int = from_centre.y + (from_tiles / 2) * sign(delta.y)
		@warning_ignore("integer_division")
		var to_edge_y: int   = to_centre.y   - (to_tiles   / 2) * sign(delta.y)
		var from_x: int = from_centre.x
		var to_x:   int = to_centre.x

		var from_door := Vector2i(from_x, from_edge_y)
		var jog_x: int = from_x + jog * (1 if to_x >= from_x else -1)
		@warning_ignore("integer_division")
		var mid_y: int = from_edge_y + (to_edge_y - from_edge_y) / 2

		for y in range(min(from_edge_y, mid_y), max(from_edge_y, mid_y) + 1):
			result.append_array(_paint_vert_segment(layer, from_x, y))

		if jog > 0:
			for x in range(min(from_x, jog_x), max(from_x, jog_x) + 1):
				result.append_array(_paint_horiz_segment(layer, x, mid_y))

		for y in range(min(mid_y, to_edge_y), max(mid_y, to_edge_y) + 1):
			result.append_array(_paint_vert_segment(layer, jog_x, y))

		if jog_x != to_x:
			for x in range(min(jog_x, to_x), max(jog_x, to_x) + 1):
				result.append_array(_paint_horiz_segment(layer, x, to_edge_y))

		edge.door_positions.assign([from_door, Vector2i(to_x, to_edge_y)])

	return result

# Paint 3 tiles wide perpendicular to horizontal travel (vertical width)
func _paint_horiz_segment(layer: Object, x: int, y: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for w in [-1, 0, 1]:
		var pos := Vector2i(x, y + w)
		layer.set_cell(pos, TILESET_SOURCE, FLOOR)
		result.append(pos)
	return result

# Paint 3 tiles wide perpendicular to vertical travel (horizontal width)
func _paint_vert_segment(layer: Object, x: int, y: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for w in [-1, 0, 1]:
		var pos := Vector2i(x + w, y)
		layer.set_cell(pos, TILESET_SOURCE, FLOOR)
		result.append(pos)
	return result

func _generate_walls(all_floor_positions: Array[Vector2i]) -> void:
	var floor_set: Dictionary = {}
	for pos in all_floor_positions:
		floor_set[pos] = true

	var wall_candidates: Dictionary = {}
	var offsets: Array[Vector2i] = [
		Vector2i(0,-1), Vector2i(0,1), Vector2i(-1,0), Vector2i(1,0),
		Vector2i(-1,-1), Vector2i(1,-1), Vector2i(-1,1), Vector2i(1,1)
	]
	for pos in all_floor_positions:
		for offset in offsets:
			var neighbour: Vector2i = pos + offset
			if not floor_set.has(neighbour):
				wall_candidates[neighbour] = true

	for pos in wall_candidates.keys():
		var atlas_coord: Vector2i = _pick_wall_tile(pos, floor_set)
		wall_layer.set_cell(pos, TILESET_SOURCE, atlas_coord)

func _pick_wall_tile(pos: Vector2i, floor_set: Dictionary) -> Vector2i:
	var above: bool = floor_set.has(pos + Vector2i( 0, -1))
	var below: bool = floor_set.has(pos + Vector2i( 0,  1))
	var left:  bool = floor_set.has(pos + Vector2i(-1,  0))
	var right: bool = floor_set.has(pos + Vector2i( 1,  0))
	var above_left:  bool = floor_set.has(pos + Vector2i(-1, -1))
	var above_right: bool = floor_set.has(pos + Vector2i( 1, -1))
	var below_left:  bool = floor_set.has(pos + Vector2i(-1,  1))
	var below_right: bool = floor_set.has(pos + Vector2i( 1,  1))

	# Outer corners — floor on two perpendicular cardinals, not the others
	if below and right and not above and not left:  return WALL_CORNER_TL
	if below and left  and not above and not right: return WALL_CORNER_TR
	if above and right and not below and not left:  return WALL_CORNER_BL
	if above and left  and not below and not right: return WALL_CORNER_BR

	# Cardinal walls — floor on exactly one cardinal direction
	if below and not above and not left and not right:  return WALL_TOP
	if above and not below and not left and not right:  return WALL_BOTTOM
	if right and not left  and not above and not below: return WALL_LEFT
	if left  and not right and not above and not below: return WALL_RIGHT

	# Inner concave corners — floor diagonally only, no cardinal adjacency
	if below_right and not above and not below and not left and not right: return WALL_INNER_TL
	if below_left  and not above and not below and not left and not right: return WALL_INNER_TR
	if above_right and not above and not below and not left and not right: return WALL_INNER_BL
	if above_left  and not above and not below and not left and not right: return WALL_INNER_BR

	# Complex adjacency or isolated diagonal — solid stone fill
	return WALL_STONE

func _get_floor_layer(zone: String) -> Object:
	return floor_layers.get(zone, floor_layers.get("hybrid", null))

func _find_room(rooms: Array, id: int):
	for r in rooms:
		if r.id == id:
			return r
	return null

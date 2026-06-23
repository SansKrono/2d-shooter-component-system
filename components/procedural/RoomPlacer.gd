class_name RoomPlacer
extends RefCounted

const ROOM_STRIDE_TILES: int = 22
const TILE_SIZE_PX: int = 32
const STRIDE_PX: int = ROOM_STRIDE_TILES * TILE_SIZE_PX  # 704 px

const SIZE_TILES: Dictionary = {
	"small":  12,
	"medium": 16,
	"large":  20,
}

func place(rooms: Array) -> void:
	for r in rooms:
		r.world_pos = Vector2(
			r.grid_pos.x * STRIDE_PX,
			r.grid_pos.y * STRIDE_PX
		)

	_resolve_overlaps(rooms)

func _resolve_overlaps(rooms: Array) -> void:
	var max_iters: int = 20
	for _iter in range(max_iters):
		var found: bool = false
		for i in range(rooms.size()):
			for j in range(i + 1, rooms.size()):
				var ra = rooms[i]
				var rb = rooms[j]
				if _rooms_overlap_tile(ra, rb):
					found = true
					# Shift rb away from ra along its branch direction
					var delta: Vector2i = rb.grid_pos - ra.grid_pos
					var shift: Vector2i
					if delta == Vector2i.ZERO:
						shift = Vector2i(1, 0)
					elif abs(delta.x) >= abs(delta.y):
						shift = Vector2i(sign(delta.x), 0)
					else:
						shift = Vector2i(0, sign(delta.y))
					rb.grid_pos = rb.grid_pos + shift
					rb.world_pos = Vector2(rb.grid_pos.x * STRIDE_PX, rb.grid_pos.y * STRIDE_PX)
		if not found:
			break

func _rooms_overlap_tile(ra, rb) -> bool:
	var ta: int = SIZE_TILES.get(ra.size, 16)
	var tb: int = SIZE_TILES.get(rb.size, 16)
	@warning_ignore("integer_division")
	var ha: int = ta / 2
	@warning_ignore("integer_division")
	var hb: int = tb / 2

	# Convert world_pos (centre) to tile coords
	@warning_ignore("integer_division")
	var ax: int = int(ra.world_pos.x) / TILE_SIZE_PX
	@warning_ignore("integer_division")
	var ay: int = int(ra.world_pos.y) / TILE_SIZE_PX
	@warning_ignore("integer_division")
	var bx: int = int(rb.world_pos.x) / TILE_SIZE_PX
	@warning_ignore("integer_division")
	var by: int = int(rb.world_pos.y) / TILE_SIZE_PX

	var a_min_x: int = ax - ha
	var a_max_x: int = ax + ha
	var a_min_y: int = ay - ha
	var a_max_y: int = ay + ha
	var b_min_x: int = bx - hb
	var b_max_x: int = bx + hb
	var b_min_y: int = by - hb
	var b_max_y: int = by + hb

	return a_min_x < b_max_x and a_max_x > b_min_x and \
	       a_min_y < b_max_y and a_max_y > b_min_y

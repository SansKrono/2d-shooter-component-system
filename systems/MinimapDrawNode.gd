extends Node2D

const CELL_SIZE:  float   = 8.0
const CELL_GAP:   float   = 4.0
const MARGIN:     Vector2 = Vector2(16.0, 16.0)

const ROOM_COLORS: Dictionary = {
	"start":    Color(0.2, 0.9, 0.2),
	"normal":   Color(0.6, 0.6, 0.6),
	"shop":     Color(0.2, 0.8, 1.0),
	"treasure": Color(1.0, 0.85, 0.1),
	"boss":     Color(0.9, 0.1, 0.1),
}

var dungeon_graph = null  # C_DungeonGraph

func _draw() -> void:
	if not dungeon_graph:
		return

	var visited: Array = []
	for r in dungeon_graph.rooms:
		if r.is_visited:
			visited.append(r)

	if visited.is_empty():
		return

	var min_gx: int = visited[0].grid_pos.x
	var min_gy: int = visited[0].grid_pos.y
	for r in visited:
		min_gx = min(min_gx, r.grid_pos.x)
		min_gy = min(min_gy, r.grid_pos.y)

	var stride: float = CELL_SIZE + CELL_GAP

	# Edges between visited rooms
	for edge in dungeon_graph.edges:
		var ra = dungeon_graph.get_room(edge.from_id)
		var rb = dungeon_graph.get_room(edge.to_id)
		if ra and rb and ra.is_visited and rb.is_visited:
			draw_line(
				_screen_pos(ra, min_gx, min_gy, stride),
				_screen_pos(rb, min_gx, min_gy, stride),
				Color(0.4, 0.4, 0.4),
				1.0
			)

	# Room cells
	var half: float = CELL_SIZE * 0.5
	for r in visited:
		var pos: Vector2 = _screen_pos(r, min_gx, min_gy, stride)
		var color: Color = ROOM_COLORS.get(r.room_type, Color.GRAY)
		draw_rect(Rect2(pos - Vector2(half, half), Vector2(CELL_SIZE, CELL_SIZE)), color)
		if r.id == dungeon_graph.current_room_id:
			draw_rect(Rect2(pos - Vector2(half, half), Vector2(CELL_SIZE, CELL_SIZE)), Color.WHITE, false, 1.0)

func _screen_pos(room, min_gx: int, min_gy: int, stride: float) -> Vector2:
	return MARGIN + Vector2(
		(room.grid_pos.x - min_gx) * stride,
		(room.grid_pos.y - min_gy) * stride
	)

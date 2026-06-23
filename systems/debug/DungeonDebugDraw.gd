extends Node2D

const ROOM_COLORS: Dictionary = {
	"start":    Color(0.2, 0.9, 0.2, 0.5),
	"normal":   Color(0.5, 0.5, 0.5, 0.3),
	"shop":     Color(0.2, 0.8, 1.0,  0.5),
	"treasure": Color(1.0, 0.85, 0.1, 0.5),
	"boss":     Color(0.9, 0.1, 0.1,  0.5),
}

const ZONE_COLORS: Dictionary = {
	"tech":       Color.CYAN,
	"hybrid":     Color.WHITE,
	"corruption": Color.MAGENTA,
}

const TILE: int = 32

var _graph = null  # C_DungeonGraph

func _ready() -> void:
	z_index = 100
	if has_meta("dungeon_graph"):
		_graph = get_meta("dungeon_graph")
		queue_redraw()

func _draw() -> void:
	if not _graph:
		if has_meta("dungeon_graph"):
			_graph = get_meta("dungeon_graph")
		if not _graph:
			return

	# Draw edges first (under rooms)
	for edge in _graph.edges:
		var ra = _graph.get_room(edge.from_id)
		var rb = _graph.get_room(edge.to_id)
		if ra and rb:
			var line_color := Color(1, 1, 1, 0.35)
			if ra.is_on_main_path and rb.is_on_main_path:
				line_color = Color(1.0, 0.8, 0.2, 0.6)
			draw_line(ra.world_pos, rb.world_pos, line_color, 1.5)

	# Draw rooms
	for room in _graph.rooms:
		var size_tiles: int = 12 if room.size == "small" else (16 if room.size == "medium" else 20)
		var half: float = size_tiles * TILE * 0.5
		var color: Color = ROOM_COLORS.get(room.room_type, Color.GRAY)
		if room.is_on_main_path:
			color = color.lightened(0.25)

		var rect := Rect2(room.world_pos - Vector2(half, half), Vector2(size_tiles * TILE, size_tiles * TILE))
		draw_rect(rect, color)
		draw_rect(rect, color.lightened(0.3), false, 2.0)

		# Centre dot
		draw_circle(room.world_pos, 5.0, Color.WHITE)

		# Zone indicator dot
		var zone_c: Color = ZONE_COLORS.get(room.zone, Color.GRAY)
		draw_circle(room.world_pos + Vector2(8, 0), 3.5, zone_c)

		# Main-path indicator
		if room.is_on_main_path:
			draw_circle(room.world_pos + Vector2(0, 8), 3.0, Color(1.0, 0.8, 0.2))

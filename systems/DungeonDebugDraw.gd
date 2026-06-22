extends Node2D

var dungeon_graph: Resource = null

func _ready() -> void:
	if Engine.is_editor_hint():
		return

func _draw() -> void:
	if not dungeon_graph:
		return

	_draw_chambers()
	_draw_corridors()
	_draw_corruption_zones()

func _draw_chambers() -> void:
	var colors = {
		"normal": Color.GRAY,
		"boss": Color.RED,
		"treasure": Color.YELLOW,
		"shop": Color.CYAN
	}

	for chamber in dungeon_graph.chambers:
		var color = colors.get(chamber.chamber_type, Color.GRAY)
		color.a = 0.3

		draw_rect(
			Rect2(chamber.rect),
			color
		)

		var border_color = color.lightened(0.3)
		border_color.a = 0.8
		draw_rect(
			Rect2(chamber.rect),
			border_color,
			false,
			2.0
		)

		var label_pos = chamber.rect.get_center()
		draw_circle(label_pos, 3.0, Color.WHITE)

func _draw_corridors() -> void:
	for corridor in dungeon_graph.corridors:
		var color = Color.WHITE
		color.a = 0.5

		if corridor.path.size() > 1:
			for i in range(corridor.path.size() - 1):
				draw_line(
					corridor.path[i],
					corridor.path[i + 1],
					color,
					corridor.width * 0.1
				)

		for waypoint in corridor.path:
			draw_circle(waypoint, 4.0, Color.WHITE)

func _draw_corruption_zones() -> void:
	for zone in dungeon_graph.corruption_zones:
		var color = Color.MAGENTA
		color.a = 0.2

		draw_circle(zone.center, zone.radius, color)

		var border_color = Color.MAGENTA
		border_color.a = 0.6
		for i in range(32):
			var angle = float(i) / 32.0 * TAU
			var next_angle = float(i + 1) / 32.0 * TAU
			var p1 = zone.center + Vector2.from_angle(angle) * zone.radius
			var p2 = zone.center + Vector2.from_angle(next_angle) * zone.radius
			draw_line(p1, p2, border_color, 2.0)

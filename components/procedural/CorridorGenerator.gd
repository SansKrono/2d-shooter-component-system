class_name CorridorGenerator

class Corridor:
	var id: int
	var from_chamber: int
	var to_chamber: int
	var path: PackedVector2Array
	var width: float
	var corruption_level: float = 0.0

	func _init(p_id: int, p_from: int, p_to: int, p_path: PackedVector2Array, p_width: float) -> void:
		id = p_id
		from_chamber = p_from
		to_chamber = p_to
		path = p_path
		width = p_width

var rng: RandomNumberGenerator
var corridors: Array[Corridor] = []
var next_corridor_id: int = 0

func _init(seed_val: int = 12345) -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = seed_val

func connect_chambers(
	from_rect: Rect2i,
	to_rect: Rect2i,
	from_chamber_id: int,
	to_chamber_id: int
) -> Corridor:
	var start = from_rect.get_center()
	var end = to_rect.get_center()

	var path = PackedVector2Array()
	path.append(start)

	if rng.randf() > 0.5:
		var mid_x = (start.x + end.x) / 2.0
		path.append(Vector2(mid_x, start.y))
		path.append(end)
	else:
		var mid_y = (start.y + end.y) / 2.0
		path.append(Vector2(start.x, mid_y))
		path.append(end)

	var width = rng.randf_range(60.0, 120.0)
	var corridor = Corridor.new(next_corridor_id, from_chamber_id, to_chamber_id, path, width)
	next_corridor_id += 1
	corridors.append(corridor)

	return corridor

func generate_connections(chambers: Array) -> Array[Corridor]:
	corridors.clear()
	next_corridor_id = 0

	if chambers.size() < 2:
		return corridors

	var chamber_list: Array[Rect2i] = []
	var chamber_ids: Array[int] = []

	for chamber in chambers:
		if chamber is Dictionary:
			if chamber.has("rect") and chamber.has("id"):
				chamber_list.append(chamber["rect"])
				chamber_ids.append(chamber["id"])
		elif chamber != null:
			chamber_list.append(chamber.rect)
			chamber_ids.append(chamber.id)

	for i in range(chamber_list.size() - 1):
		var corridor = connect_chambers(
			chamber_list[i],
			chamber_list[i + 1],
			chamber_ids[i],
			chamber_ids[i + 1]
		)

	var loop_count = rng.randi_range(1, 3)
	for _i in range(loop_count):
		if chamber_list.size() >= 2:
			var a = rng.randi() % chamber_list.size()
			var b = rng.randi() % chamber_list.size()
			if a != b:
				var corridor = connect_chambers(
					chamber_list[a],
					chamber_list[b],
					chamber_ids[a],
					chamber_ids[b]
				)

	print("[CorridorGen] Generated %d corridors" % corridors.size())
	return corridors

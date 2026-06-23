class_name RoomGraphGenerator
extends RefCounted

const C_ROOM_NODE = preload("res://components/world/c_room_node.gd")
const C_DUNGEON_GRAPH = preload("res://components/world/c_dungeon_graph.gd")

var edges: Array = []  # Array of C_DungeonGraph.RoomEdge

var _rng: RandomNumberGenerator
var _next_id: int = 0

func _init(p_rng: RandomNumberGenerator) -> void:
	_rng = p_rng

func generate(floor_number: int) -> Array:
	_next_id = 0
	edges = []

	var total_rooms: int = _rng.randi_range(
		8 + (floor_number - 1) * 2,
		12 + (floor_number - 1) * 2
	)
	var main_path_length: int = ceili(total_rooms * 0.6)
	var branch_budget: int = total_rooms - main_path_length

	var rooms: Array = []

	# --- Build main path ---
	var start_room = _make_room("start", Vector2i(0, 0), true)
	rooms.append(start_room)

	var prev_id: int = start_room.id
	for i in range(1, main_path_length - 1):
		var room = _make_room("normal", Vector2i(i, 0), true)
		rooms.append(room)
		_connect(rooms, prev_id, room.id, Vector2i(1, 0))
		prev_id = room.id

	var boss_room = _make_room("boss", Vector2i(main_path_length - 1, 0), true)
	rooms.append(boss_room)
	_connect(rooms, prev_id, boss_room.id, Vector2i(1, 0))

	# --- Build branches ---
	# Eligible: main-path nodes except start (id=0) and boss
	var eligible: Array = []
	for r in rooms:
		if r.is_on_main_path and r.room_type != "start" and r.room_type != "boss":
			eligible.append(r)

	_shuffle(eligible)

	var rooms_remaining: int = branch_budget

	for parent_room in eligible:
		if rooms_remaining <= 0:
			break
		if _rng.randf() > 0.7:
			continue

		var branch_len: int = _rng.randi_range(1, min(2, rooms_remaining))
		var direction: Vector2i = Vector2i(0, 1) if _rng.randf() < 0.5 else Vector2i(0, -1)

		var cur_pos: Vector2i = parent_room.grid_pos
		var prev_branch_id: int = parent_room.id

		for _b in range(branch_len):
			cur_pos = cur_pos + direction
			# Avoid collision with existing grid positions
			while _grid_pos_taken(rooms, cur_pos):
				cur_pos = cur_pos + direction

			var branch_room = _make_room("normal", cur_pos, false)
			rooms.append(branch_room)
			_connect(rooms, prev_branch_id, branch_room.id, direction)
			prev_branch_id = branch_room.id
			rooms_remaining -= 1
			if rooms_remaining <= 0:
				break

	# --- Assign special room types ---
	var dead_ends: Array = []
	for r in rooms:
		if r.connections.size() == 1 and r.room_type != "start" and r.room_type != "boss":
			dead_ends.append(r)

	_shuffle(dead_ends)

	if dead_ends.size() >= 1:
		dead_ends[0].room_type = "shop"
	if dead_ends.size() >= 2:
		dead_ends[1].room_type = "treasure"

	# --- Assign sizes ---
	for r in rooms:
		match r.room_type:
			"boss":
				r.size = "large"
			"shop", "treasure", "start":
				r.size = "medium"
			"normal":
				r.size = "medium" if r.is_on_main_path else "small"

	# Override: if long main path, last two normals before boss get large
	if main_path_length >= 6:
		var normals_before_boss: Array = []
		for r in rooms:
			if r.is_on_main_path and r.room_type == "normal":
				normals_before_boss.append(r)
		normals_before_boss.sort_custom(func(a, b): return a.grid_pos.x > b.grid_pos.x)
		for i in range(min(2, normals_before_boss.size())):
			normals_before_boss[i].size = "large"

	# --- Assign zones via BFS depth ---
	var depths: Dictionary = _bfs_depths(start_room.id, rooms)
	var max_depth: int = 0
	for d in depths.values():
		if d > max_depth:
			max_depth = d

	for r in rooms:
		var depth: int = depths.get(r.id, 0)
		var ratio: float = 0.0 if max_depth == 0 else float(depth) / float(max_depth)
		if ratio < 0.35:
			r.zone = "tech"
			r.corruption_level = 0.0
		elif ratio < 0.65:
			r.zone = "hybrid"
			r.corruption_level = 0.4
		else:
			r.zone = "corruption"
			r.corruption_level = 0.8

	# --- Assign prefab keys ---
	var vcount: int = 0
	for r in rooms:
		r.prefab_key = _pick_prefab_key(r.room_type, r.size, vcount)
		vcount += 1

	# --- Assign edge jogs ---
	for edge in edges:
		var ra = _find_room(rooms, edge.from_id)
		var rb = _find_room(rooms, edge.to_id)
		if ra and rb:
			var delta: Vector2i = rb.grid_pos - ra.grid_pos
			edge.jog_offset = _rng.randi_range(0, 2)
			edge.jog_axis = "vertical" if abs(delta.x) > abs(delta.y) else "horizontal"

	# --- Debug print ---
	print("[RoomGraphGen] Floor %d: %d rooms" % [floor_number, rooms.size()])
	for r in rooms:
		print("  Room id=%d type=%s size=%s zone=%s grid=%s main=%s" % [
			r.id, r.room_type, r.size, r.zone,
			str(r.grid_pos), str(r.is_on_main_path)
		])

	return rooms

func _make_room(room_type: String, grid_pos: Vector2i, on_main_path: bool) -> C_RoomNode:
	var r = C_RoomNode.new(_next_id, room_type)
	r.grid_pos = grid_pos
	r.is_on_main_path = on_main_path
	_next_id += 1
	return r

func _connect(rooms: Array, id_a: int, id_b: int, direction: Vector2i) -> void:
	var ra = _find_room(rooms, id_a)
	var rb = _find_room(rooms, id_b)
	if ra and not ra.connections.has(id_b):
		ra.connections.append(id_b)
	if rb and not rb.connections.has(id_a):
		rb.connections.append(id_a)

	var axis: String = "horizontal" if abs(direction.x) > 0 else "vertical"
	var edge = C_DungeonGraph.RoomEdge.new(id_a, id_b, 0, axis)
	edges.append(edge)

func _find_room(rooms: Array, id: int) -> C_RoomNode:
	for r in rooms:
		if r.id == id:
			return r
	return null

func _grid_pos_taken(rooms: Array, pos: Vector2i) -> bool:
	for r in rooms:
		if r.grid_pos == pos:
			return true
	return false

func _bfs_depths(start_id: int, rooms: Array) -> Dictionary:
	var depths: Dictionary = {}
	var queue: Array = [start_id]
	depths[start_id] = 0

	while queue.size() > 0:
		var current_id: int = queue.pop_front()
		var current = _find_room(rooms, current_id)
		if not current:
			continue
		for neighbour_id in current.connections:
			if not depths.has(neighbour_id):
				depths[neighbour_id] = depths[current_id] + 1
				queue.append(neighbour_id)

	return depths

func _shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j: int = _rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp

func _pick_prefab_key(room_type: String, size: String, variant_idx: int) -> String:
	var variants: Dictionary = {
		"normal_small": 3, "normal_medium": 3, "boss_large": 2,
		"shop_medium": 2, "treasure_medium": 2, "start_medium": 1
	}
	var key: String = "%s_%s" % [room_type, size]
	var count: int = variants.get(key, 1)
	var letters: Array = ["a", "b", "c"]
	var idx: int = variant_idx % count
	return "%s_%s" % [key, letters[idx]]

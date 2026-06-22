class_name DungeonBSPGenerator

class Chamber:
	var id: int
	var rect: Rect2i
	var chamber_type: String
	var corruption_level: float = 0.0
	var connected_corridors: Array[int] = []

	func _init(p_id: int, p_rect: Rect2i, p_type: String = "normal") -> void:
		id = p_id
		rect = p_rect
		chamber_type = p_type

class BSPNode:
	var rect: Rect2i
	var left: BSPNode = null
	var right: BSPNode = null
	var chamber: Chamber = null

var rng: RandomNumberGenerator
var chambers: Array[Chamber] = []
var next_chamber_id: int = 0

func _init(seed_val: int = 12345) -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = seed_val

func generate(bounds: Rect2i, target_count: int = 8) -> Array[Chamber]:
	chambers.clear()
	next_chamber_id = 0

	var root = _bsp_partition(bounds, 0, 4)
	_collect_chambers(root)
	_assign_room_types()

	print("[BSP] Generated %d chambers" % chambers.size())
	return chambers

func _bsp_partition(rect: Rect2i, depth: int, max_depth: int) -> BSPNode:
	var node = BSPNode.new()
	node.rect = rect

	if depth >= max_depth or rect.get_area() < 40000:
		node.chamber = _create_chamber(rect)
		return node

	var horizontal = rng.randf() > 0.5
	var min_size = 200

	if horizontal:
		var split_y = rect.position.y + int(rng.randf_range(
			rect.size.y * 0.4,
			rect.size.y * 0.6
		))
		var top_rect = Rect2i(rect.position, Vector2i(rect.size.x, split_y - rect.position.y))
		var bottom_rect = Rect2i(
			Vector2i(rect.position.x, split_y),
			Vector2i(rect.size.x, rect.position.y + rect.size.y - split_y)
		)

		if top_rect.size.y >= min_size and bottom_rect.size.y >= min_size:
			node.left = _bsp_partition(top_rect, depth + 1, max_depth)
			node.right = _bsp_partition(bottom_rect, depth + 1, max_depth)
		else:
			node.chamber = _create_chamber(rect)
	else:
		var split_x = rect.position.x + int(rng.randf_range(
			rect.size.x * 0.4,
			rect.size.x * 0.6
		))
		var left_rect = Rect2i(rect.position, Vector2i(split_x - rect.position.x, rect.size.y))
		var right_rect = Rect2i(
			Vector2i(split_x, rect.position.y),
			Vector2i(rect.position.x + rect.size.x - split_x, rect.size.y)
		)

		if left_rect.size.x >= min_size and right_rect.size.x >= min_size:
			node.left = _bsp_partition(left_rect, depth + 1, max_depth)
			node.right = _bsp_partition(right_rect, depth + 1, max_depth)
		else:
			node.chamber = _create_chamber(rect)

	return node

func _create_chamber(bounds: Rect2i) -> Chamber:
	var padding = int(rng.randf_range(20, 50))
	var chamber_rect = Rect2i(
		bounds.position + Vector2i(padding, padding),
		bounds.size - Vector2i(padding * 2, padding * 2)
	)

	chamber_rect.size = Vector2i.MAX.min(chamber_rect.size, Vector2i(1000, 1000))
	if chamber_rect.size.x < 60 or chamber_rect.size.y < 60:
		chamber_rect = bounds

	var chamber = Chamber.new(next_chamber_id, chamber_rect, "normal")
	next_chamber_id += 1
	chambers.append(chamber)
	return chamber

func _collect_chambers(node: BSPNode) -> void:
	if node.chamber:
		return
	if node.left:
		_collect_chambers(node.left)
	if node.right:
		_collect_chambers(node.right)

func _assign_room_types() -> void:
	if chambers.is_empty():
		return

	for chamber in chambers:
		chamber.chamber_type = "normal"

	var boss_idx = -1
	var treasure_idx = -1
	var shop_idx = -1

	if chambers.size() >= 1:
		boss_idx = rng.randi() % chambers.size()
		chambers[boss_idx].chamber_type = "boss"

	if chambers.size() >= 2:
		treasure_idx = rng.randi() % chambers.size()
		while treasure_idx == boss_idx:
			treasure_idx = rng.randi() % chambers.size()
		chambers[treasure_idx].chamber_type = "treasure"

	if chambers.size() >= 3:
		shop_idx = rng.randi() % chambers.size()
		while shop_idx == boss_idx or shop_idx == treasure_idx:
			shop_idx = rng.randi() % chambers.size()
		chambers[shop_idx].chamber_type = "shop"

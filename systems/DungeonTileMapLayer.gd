class_name DungeonTileMapLayer
extends TileMap

const TILE_SIZE: int = 16
const WALKABLE_TILE: Vector2i = Vector2i(0, 0)
const WALL_TILE: Vector2i = Vector2i(1, 0)

var dungeon_graph: Resource = null

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	tile_set = _create_tileset()

func paint_dungeon(graph: Resource) -> void:
	dungeon_graph = graph
	clear()

	_paint_chambers()
	_paint_corridors()
	_paint_borders()

	print("[DungeonTileMap] Painted: chambers + corridors")

func _paint_chambers() -> void:
	if not dungeon_graph or not dungeon_graph.chambers:
		return

	for chamber in dungeon_graph.chambers:
		var rect = chamber.rect
		var tile_id = WALKABLE_TILE

		if chamber.chamber_type == "boss":
			tile_id = Vector2i(2, 0)
		elif chamber.chamber_type == "treasure":
			tile_id = Vector2i(3, 0)
		elif chamber.chamber_type == "shop":
			tile_id = Vector2i(4, 0)

		_fill_rect_with_tile(rect, tile_id)

func _paint_corridors() -> void:
	if not dungeon_graph or not dungeon_graph.corridors:
		return

	for corridor in dungeon_graph.corridors:
		_paint_corridor_path(corridor)

func _paint_corridor_path(corridor: Object) -> void:
	var path = corridor.path
	var width = int(corridor.width)

	if path.size() < 2:
		return

	for i in range(path.size() - 1):
		var start = path[i]
		var end = path[i + 1]
		_paint_line_segment(start, end, width, Vector2i(1, 0))

func _paint_line_segment(start: Vector2, end: Vector2, width: int, tile_id: Vector2i) -> void:
	var dist = start.distance_to(end)
	if dist == 0:
		return

	var direction = (end - start).normalized()
	var perp = Vector2(-direction.y, direction.x)
	var half_width = width / 2

	var steps = int(dist) + 1
	for step in range(steps):
		var progress = float(step) / float(steps)
		var center = start.lerp(end, progress)

		for offset in range(-half_width, half_width + 1):
			var pos = center + perp * offset
			var tile_pos = Vector2i(int(pos.x / TILE_SIZE), int(pos.y / TILE_SIZE))
			set_cell(0, tile_pos, 0, tile_id)

func _paint_borders() -> void:
	if not dungeon_graph:
		return

	var bounds = dungeon_graph.dungeon_bounds
	var left = bounds.position.x / TILE_SIZE
	var right = (bounds.position.x + bounds.size.x) / TILE_SIZE
	var top = bounds.position.y / TILE_SIZE
	var bottom = (bounds.position.y + bounds.size.y) / TILE_SIZE

	for x in range(left - 2, right + 2):
		for y in range(top - 2, bottom + 2):
			var is_border = (x < left or x >= right or y < top or y >= bottom)
			if is_border:
				set_cell(0, Vector2i(x, y), 0, WALL_TILE)

func _fill_rect_with_tile(rect: Rect2i, tile_id: Vector2i) -> void:
	var start_tile = rect.position / TILE_SIZE
	var end_tile = (rect.position + rect.size) / TILE_SIZE

	for x in range(start_tile.x, end_tile.x + 1):
		for y in range(start_tile.y, end_tile.y + 1):
			set_cell(0, Vector2i(x, y), 0, tile_id)

func _create_tileset() -> TileSet:
	var tileset = TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	var source = TileSetAtlasSource.new()
	source.texture = _create_dummy_texture()
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)

	tileset.add_source(source)

	_setup_tile_physics(tileset, source)

	return tileset

func _create_dummy_texture() -> Texture2D:
	var image = Image.create(80, 16, false, Image.FORMAT_RGB8)

	image.fill(Color.GRAY)
	for x in range(0, 16):
		for y in range(0, 16):
			image.set_pixel(x, y, Color.WHITE)

	for x in range(16, 32):
		for y in range(0, 16):
			image.set_pixel(x, y, Color.BLACK)

	for x in range(32, 48):
		for y in range(0, 16):
			image.set_pixel(x, y, Color.RED)

	for x in range(48, 64):
		for y in range(0, 16):
			image.set_pixel(x, y, Color.YELLOW)

	for x in range(64, 80):
		for y in range(0, 16):
			image.set_pixel(x, y, Color.CYAN)

	var texture = ImageTexture.create_from_image(image)
	return texture

func _setup_tile_physics(tileset: TileSet, source: TileSetAtlasSource) -> void:
	var walkable_tiles = [WALKABLE_TILE, Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0)]
	var wall_tiles = [WALL_TILE]

	for tile_id in walkable_tiles:
		source.create_tile(tile_id)

	for tile_id in wall_tiles:
		source.create_tile(tile_id)
		var data = source.get_tile_data(tile_id, 0)
		data.set_collision_polygons_count(0, 1)

		var polygon = PackedVector2Array([
			Vector2(0, 0),
			Vector2(TILE_SIZE, 0),
			Vector2(TILE_SIZE, TILE_SIZE),
			Vector2(0, TILE_SIZE)
		])
		data.set_collision_polygon(0, 0, polygon)

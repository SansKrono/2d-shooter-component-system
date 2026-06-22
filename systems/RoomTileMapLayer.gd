class_name RoomTileMapLayer
extends TileMap

const TILE_SIZE: int = 64
const ROOM_WIDTH: int = 15
const ROOM_HEIGHT: int = 9

var _source_id: int = -1

func _ready() -> void:
	z_index = -100
	_setup_tileset()
	# Bind all TileMap layers to physics layer 0
	for layer_idx in range(get_layers_count()):
		set_layer_enabled(layer_idx, 1)

func _setup_tileset() -> void:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)
	ts.set_physics_layer_collision_mask(0, 1)

	# Build 6-column atlas image
	var img := Image.create(6 * TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	var colors: Array[Color] = [
		Color(0.5, 0.5, 0.5),          # 0 floor
		Color(0.25, 0.15, 0.05),       # 1 wall
		Color(0.2, 0.7, 0.7),          # 2 door marker
		Color(0.2, 0.55, 0.25),        # 3 decoration
		Color(0.2, 0.2, 0.2),          # 4 indestructible
		Color(0.85, 0.45, 0.1),        # 5 destructible marker
	]
	for col in range(6):
		for x in range(col * TILE_SIZE, (col + 1) * TILE_SIZE):
			for y in range(TILE_SIZE):
				img.set_pixel(x, y, colors[col])

	var source := TileSetAtlasSource.new()
	source.texture = ImageTexture.create_from_image(img)
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)

	for i in range(6):
		source.create_tile(Vector2i(i, 0))

	_source_id = ts.add_source(source)

	# Physics polygons on wall (col 1) and indestructible (col 4)
	var half := TILE_SIZE / 2.0
	var poly := PackedVector2Array([
		Vector2(-half, -half), Vector2(half, -half),
		Vector2(half, half), Vector2(-half, half)
	])
	for blocking in [Vector2i(1, 0), Vector2i(4, 0)]:
		var td: TileData = source.get_tile_data(blocking, 0)
		td.add_collision_polygon(0)
		td.set_collision_polygon_points(0, 0, poly)

	tile_set = ts

	# Create 6 TileMap layers
	for i in range(1, 6):
		add_layer(i)
	set_layer_name(0, "Floor")
	set_layer_name(1, "Walls")
	set_layer_name(2, "Doors")
	set_layer_name(3, "Decorations")
	set_layer_name(4, "Indestructible")
	set_layer_name(5, "Destructible")

func paint_room(room_type: String, active_doors: Array[String], layout_config: Resource = null) -> Array[Vector2]:
	if _source_id == -1:
		push_error("[RoomTileMapLayer] _setup_tileset not yet called")
		return []
	clear()
	_paint_floor()
	_paint_walls(active_doors)
	_paint_doors(active_doors)

	if layout_config:
		_paint_decorations_from_config(layout_config)
		_paint_indestructible_from_config(layout_config)
		return _mark_destructible_from_config(layout_config)
	else:
		_paint_decorations(room_type)
		_paint_indestructible(room_type)
		return _mark_destructible(room_type)

func _paint_floor() -> void:
	for x in range(1, ROOM_WIDTH - 1):
		for y in range(1, ROOM_HEIGHT - 1):
			set_cell(0, Vector2i(x, y), _source_id, Vector2i(0, 0))

func _paint_walls(active_doors: Array[String]) -> void:
	var door_openings: Dictionary = {
		"north": Vector2i(7, 0),
		"south": Vector2i(7, 8),
		"west":  Vector2i(0, 4),
		"east":  Vector2i(14, 4),
	}
	var skip_tiles: Array[Vector2i] = []
	for dir in active_doors:
		if door_openings.has(dir):
			skip_tiles.append(door_openings[dir])

	for x in range(ROOM_WIDTH):
		for y in range(ROOM_HEIGHT):
			var is_border := (x == 0 or x == ROOM_WIDTH - 1 or y == 0 or y == ROOM_HEIGHT - 1)
			if not is_border:
				continue
			var cell := Vector2i(x, y)
			if cell in skip_tiles:
				continue
			set_cell(1, cell, _source_id, Vector2i(1, 0))

func _paint_doors(active_doors: Array[String]) -> void:
	var door_positions: Dictionary = {
		"north": Vector2i(7, 0),
		"south": Vector2i(7, 8),
		"west":  Vector2i(0, 4),
		"east":  Vector2i(14, 4),
	}
	for dir in active_doors:
		if door_positions.has(dir):
			set_cell(2, door_positions[dir], _source_id, Vector2i(2, 0))

func _paint_decorations(room_type: String) -> void:
	var positions: Array[Vector2i] = []
	match room_type:
		"START", "NORMAL", "BOSS":
			positions = [Vector2i(2, 2), Vector2i(12, 2), Vector2i(2, 6), Vector2i(12, 6)]
		"TREASURE":
			positions = [
				Vector2i(6, 3), Vector2i(7, 3), Vector2i(8, 3),
				Vector2i(6, 5), Vector2i(7, 5), Vector2i(8, 5),
			]
		"SHOP":
			positions = [
				Vector2i(3, 2), Vector2i(5, 2), Vector2i(9, 2), Vector2i(11, 2),
				Vector2i(3, 6), Vector2i(5, 6), Vector2i(9, 6), Vector2i(11, 6),
			]
	for pos in positions:
		set_cell(3, pos, _source_id, Vector2i(3, 0))

func _paint_indestructible(room_type: String) -> void:
	var positions: Array[Vector2i] = []
	match room_type:
		"NORMAL":
			positions = [Vector2i(4, 3), Vector2i(10, 5)]
		"BOSS":
			positions = [
				Vector2i(3, 2), Vector2i(11, 2),
				Vector2i(3, 6), Vector2i(11, 6),
			]
	for pos in positions:
		set_cell(4, pos, _source_id, Vector2i(4, 0))

func _mark_destructible(room_type: String) -> Array[Vector2]:
	var tile_positions: Array[Vector2i] = []
	match room_type:
		"NORMAL":
			tile_positions = [
				Vector2i(6, 2), Vector2i(8, 2),
				Vector2i(6, 6), Vector2i(8, 6),
			]
		"BOSS":
			tile_positions = []

	for tp in tile_positions:
		set_cell(5, tp, _source_id, Vector2i(5, 0))

	var world_positions: Array[Vector2] = []
	for tp in tile_positions:
		world_positions.append(map_to_local(tp))
	return world_positions

func _paint_decorations_from_config(layout_config: Resource) -> void:
	if layout_config and "decoration_positions" in layout_config:
		var positions = layout_config.get("decoration_positions")
		for pos in positions:
			set_cell(3, pos, _source_id, Vector2i(3, 0))

func _paint_indestructible_from_config(layout_config: Resource) -> void:
	if layout_config and "indestructible_positions" in layout_config:
		var positions = layout_config.get("indestructible_positions")
		for pos in positions:
			set_cell(4, pos, _source_id, Vector2i(4, 0))

func _mark_destructible_from_config(layout_config: Resource) -> Array[Vector2]:
	var tile_positions: Array[Vector2i] = []
	if layout_config and "destructible_positions" in layout_config:
		tile_positions = layout_config.get("destructible_positions")

	for tp in tile_positions:
		set_cell(5, tp, _source_id, Vector2i(5, 0))

	var world_positions: Array[Vector2] = []
	for tp in tile_positions:
		world_positions.append(map_to_local(tp))
	return world_positions

@tool
class_name ContinuousDungeonEntity
extends Entity

const DUNGEON_TILESET_PATH: String = "res://resources/dungeon_tileset.tres"

func _ready() -> void:
	super._initialize()
	name = "ContinuousDungeon"
	_setup_tilemap()

const C_DUNGEON_GRAPH = preload("res://components/world/c_dungeon_graph.gd")

func define_components() -> Array:
	return [C_DUNGEON_GRAPH.new()]

func _setup_tilemap() -> void:
	var tilemap_root: Node2D = Node2D.new()
	tilemap_root.name = "DungeonTileMap"
	add_child(tilemap_root)

	var tileset: TileSet = _load_or_create_tileset()

	var floor_tech       = _make_layer("FloorTech",       tileset, Color(0.75, 0.90, 1.00), -10)
	var floor_hybrid     = _make_layer("FloorHybrid",     tileset, Color.WHITE,              -10)
	var floor_corruption = _make_layer("FloorCorruption", tileset, Color(0.90, 0.72, 1.00), -10)
	var walls            = _make_layer("Walls",           tileset, Color.WHITE,              -5)

	tilemap_root.add_child(floor_tech)
	tilemap_root.add_child(floor_hybrid)
	tilemap_root.add_child(floor_corruption)
	tilemap_root.add_child(walls)

func _make_layer(layer_name: String, tileset: TileSet, color: Color, z: int) -> TileMapLayer:
	var layer: TileMapLayer = TileMapLayer.new()
	layer.name = layer_name
	layer.tile_set = tileset
	layer.modulate = color
	layer.z_index = z
	return layer

func _load_or_create_tileset() -> TileSet:
	if ResourceLoader.exists(DUNGEON_TILESET_PATH):
		return load(DUNGEON_TILESET_PATH) as TileSet

	# Programmatic fallback — register all 8×10 atlas tiles (32×32 px each)
	var tileset: TileSet = TileSet.new()
	tileset.tile_size = Vector2i(32, 32)

	var source: TileSetAtlasSource = TileSetAtlasSource.new()
	source.texture = load("res://assets/tilesets/dungeon_69b.png") as Texture2D
	source.texture_region_size = Vector2i(32, 32)

	for col in range(8):
		for row in range(10):
			var coord := Vector2i(col, row)
			if not source.has_tile(coord):
				source.create_tile(coord)

	tileset.add_source(source, 0)
	return tileset

func is_point_walkable(pos: Vector2) -> bool:
	var tilemap_root: Node = get_node_or_null("DungeonTileMap")
	if not tilemap_root:
		return false
	var floor_layer: TileMapLayer = tilemap_root.get_node_or_null("FloorHybrid") as TileMapLayer
	if not floor_layer:
		return false
	var tile_coords: Vector2i = floor_layer.local_to_map(pos)
	return floor_layer.get_cell_tile_data(tile_coords) != null

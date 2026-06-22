class_name ContinuousDungeonEntity
extends Node2D

var tilemap_layer: TileMap = null
var dungeon_graph: Resource = null

func _ready() -> void:
	name = "ContinuousDungeon"

	tilemap_layer = TileMap.new()
	tilemap_layer.name = "TileMapLayer"
	tilemap_layer.set_script(preload("res://systems/DungeonTileMapLayer.gd"))
	add_child(tilemap_layer)

func setup_from_graph(graph: Resource) -> void:
	dungeon_graph = graph
	if tilemap_layer and dungeon_graph:
		call_deferred("_paint_tilemap")
		print("[ContinuousDungeon] Setup complete with dungeon graph")

func _paint_tilemap() -> void:
	if tilemap_layer and tilemap_layer.has_method("paint_dungeon"):
		tilemap_layer.paint_dungeon(dungeon_graph)

func get_spawn_position_for_chamber(chamber_id: int) -> Vector2:
	if not dungeon_graph:
		return Vector2(100, 100)

	for chamber in dungeon_graph.chambers:
		if chamber.id == chamber_id:
			return chamber.rect.get_center()

	return Vector2(100, 100)

func get_chamber_at_position(pos: Vector2) -> Object:
	if dungeon_graph:
		return dungeon_graph.find_chamber_at_position(pos)
	return null

func is_point_walkable(pos: Vector2) -> bool:
	if not tilemap_layer:
		return false

	var tile_coords = tilemap_layer.local_to_map(pos)
	var tile_data = tilemap_layer.get_cell_tile_data(0, tile_coords)
	return tile_data != null

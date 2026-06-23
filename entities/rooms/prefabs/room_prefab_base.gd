class_name RoomPrefabBase
extends Node2D

func get_floor_tiles(tile_count: int) -> Array:
	return _get_rect(tile_count, tile_count)

func _get_rect(w: int, h: int) -> Array:
	var result: Array = []
	for x in range(w):
		for y in range(h):
			result.append(Vector2i(x, y))
	return result

func _get_l_shape(w: int, h: int, cut_x: int, cut_y: int) -> Array:
	var result: Array = []
	for x in range(w):
		for y in range(h):
			if x >= (w - cut_x) and y >= (h - cut_y):
				continue
			result.append(Vector2i(x, y))
	return result

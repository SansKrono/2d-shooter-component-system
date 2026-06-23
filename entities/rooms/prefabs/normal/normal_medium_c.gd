extends RoomPrefabBase

func get_floor_tiles(tile_count: int) -> Array:
	return _get_l_shape(16, 16, 5, 5)

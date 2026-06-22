@tool
class_name RoomEntity
extends Entity

const C_ROOM_DATA = preload("res://components/character/c_room_data.gd")
const ROOM_TILEMAP_SCRIPT = preload("res://systems/RoomTileMapLayer.gd")

var _tilemap: TileMap = null

func define_components() -> Array:
	var rd = C_ROOM_DATA.new()
	rd.state = 1
	return [rd]

func setup(room_type: String, active_doors: Array[String]) -> Array[Vector2]:
	if _tilemap and is_instance_valid(_tilemap):
		_tilemap.queue_free()
	_tilemap = TileMap.new()
	_tilemap.name = "RoomTileMap"
	_tilemap.set_script(ROOM_TILEMAP_SCRIPT)
	add_child(_tilemap)
	return _tilemap.paint_room(room_type, active_doors)

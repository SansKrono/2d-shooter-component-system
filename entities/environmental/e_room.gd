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

func setup(room_type: String, active_doors: Array[String], layout_config: Resource = null) -> Array[Vector2]:
	if _tilemap and is_instance_valid(_tilemap):
		_tilemap.queue_free()

	# Create StaticBody2D wrapper for collision layer/mask configuration
	var physics_body = StaticBody2D.new()
	physics_body.name = "TileMapPhysics"
	physics_body.collision_layer = 1
	physics_body.collision_mask = 1
	add_child(physics_body)

	# Create and attach TileMap as child of physics body
	_tilemap = TileMap.new()
	_tilemap.name = "RoomTileMap"
	_tilemap.set_script(ROOM_TILEMAP_SCRIPT)
	physics_body.add_child(_tilemap)

	return _tilemap.paint_room(room_type, active_doors, layout_config)

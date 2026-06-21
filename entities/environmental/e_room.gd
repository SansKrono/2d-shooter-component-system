@tool
class_name RoomEntity
extends Entity


const C_ROOM_DATA = preload("res://components/character/c_room_data.gd")

func define_components() -> Array:
	var rd = C_ROOM_DATA.new()
	rd.state = 1 # C_RoomData.RoomState.COMBAT is 1
	return [rd]

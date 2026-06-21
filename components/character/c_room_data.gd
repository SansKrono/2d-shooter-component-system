class_name C_RoomData
extends Component

enum RoomState { INITIALIZATION, COMBAT, CLEARED, REWARD }
@export var state: RoomState = RoomState.INITIALIZATION
@export var coords: Vector2i = Vector2i.ZERO
@export var room_type: String = "normal"

func _init(c: Vector2i = Vector2i.ZERO, type: String = "normal", s: RoomState = RoomState.INITIALIZATION) -> void:
	coords = c
	room_type = type
	state = s

class_name C_Door
extends Component

@export var direction: String = "north"
@export var target_room_coords: Vector2i = Vector2i.ZERO
@export var is_locked: bool = false

func _init(dir: String = "north", coords: Vector2i = Vector2i.ZERO, locked: bool = false) -> void:
	direction = dir
	target_room_coords = coords
	is_locked = locked

class_name C_Offscreen
extends Component

@export var is_offscreen: bool = true
@export var time_offscreen: float = 0.0

func _init(off: bool = true) -> void:
	is_offscreen = off
	time_offscreen = 0.0

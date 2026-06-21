class_name C_Locomotion
extends Component

@export var base_speed: float = 1.0
@export var current_speed: float = 1.0
@export var friction: float = 800.0

func _init(base: float = 1.0, current: float = 1.0, fric: float = 800.0) -> void:
	base_speed = base
	current_speed = current
	friction = fric

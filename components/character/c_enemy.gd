class_name C_Enemy
extends Component

@export var enemy_type: String = "normal"
@export var xp_value: int = 10

func _init(type: String = "normal", xp: int = 10) -> void:
	enemy_type = type
	xp_value = xp

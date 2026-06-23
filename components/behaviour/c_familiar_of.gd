class_name C_FamiliarOf
extends Component

@export var familiar_index: int = 0
@export var follow_offset: Vector2 = Vector2(-30.0, 0.0)

func _init(idx: int = 0, offset: Vector2 = Vector2(-30.0, 0.0)) -> void:
	familiar_index = idx
	follow_offset = offset

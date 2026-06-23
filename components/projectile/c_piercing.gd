class_name C_Piercing
extends Component

@export var pierce_count: int = -1
@export var hit_count: int = 0

func _init(count: int = -1) -> void:
	pierce_count = count

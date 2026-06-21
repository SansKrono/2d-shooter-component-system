class_name C_Dead
extends Component

@export var death_timestamp: float = 0.0
@export var is_processed: bool = false

func _init(timestamp: float = 0.0) -> void:
	death_timestamp = timestamp
	is_processed = false

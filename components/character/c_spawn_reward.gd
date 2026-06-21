class_name C_SpawnReward
extends Component

@export var reward_type: String = "coin"
@export var spawn_position: Vector2 = Vector2.ZERO

func _init(type: String = "coin", pos: Vector2 = Vector2.ZERO) -> void:
	reward_type = type
	spawn_position = pos

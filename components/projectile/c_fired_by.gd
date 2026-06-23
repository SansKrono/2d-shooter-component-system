class_name C_FiredBy
extends Component

@export var shooter_id: String = ""
@export var has_friendly_fire: bool = false

func _init(id_str: String = "", friendly_fire: bool = false) -> void:
	shooter_id = id_str
	has_friendly_fire = friendly_fire

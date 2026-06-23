class_name C_DamageType
extends Component

enum Type { NORMAL, EXPLOSIVE }
@export var damage_type: Type = Type.NORMAL

func _init(t: Type = Type.NORMAL) -> void:
	damage_type = t

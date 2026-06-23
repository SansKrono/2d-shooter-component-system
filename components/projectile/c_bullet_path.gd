class_name C_BulletPath
extends Component

@export var path_modifiers: Array[BulletPathModifier] = []

func _init(modifiers: Array = []) -> void:
	path_modifiers = []
	for m in modifiers:
		if m is BulletPathModifier:
			path_modifiers.append(m.duplicate())

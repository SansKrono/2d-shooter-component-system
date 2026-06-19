class_name BulletPathModifier
extends Resource

var initialized: bool = false

func update_path(bullet: Entity, delta: float) -> void:
	if not initialized:
		initialize_path(bullet)
		initialized = true
	_tick_path(bullet, delta)

func initialize_path(_bullet: Entity) -> void:
	pass

func _tick_path(_bullet: Entity, _delta: float) -> void:
	pass

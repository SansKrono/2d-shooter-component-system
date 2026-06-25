class_name ScreenShakeSystem
extends System

var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var target_camera: Camera2D = null

func query() -> QueryBuilder:
	return q.with_all([C_Health])

func process(_entities: Array[Entity], _components: Array, delta: float) -> void:
	if not target_camera:
		target_camera = get_viewport().get_camera_2d()

	# Tick down shake
	if shake_duration > 0.0:
		shake_duration -= delta
		_apply_shake()
	else:
		shake_intensity = 0.0

func trigger_shake(intensity: float, duration: float = 0.2) -> void:
	shake_intensity = intensity
	shake_duration = duration

func _apply_shake() -> void:
	if not target_camera:
		return

	var offset = Vector2(
		randf_range(-shake_intensity, shake_intensity),
		randf_range(-shake_intensity, shake_intensity)
	)
	target_camera.offset = offset

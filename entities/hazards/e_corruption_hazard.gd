@tool
class_name CorruptionHazard
extends Entity

func define_components() -> Array:
	return [
		C_EnvironmentEffect.new(C_EnvironmentEffect.EFFECT_CORRUPTION, 5.0, 30.0, 3.0),
		C_Transform.new(Vector2.ZERO),
	]

func on_ready() -> void:
	var sprite = $Sprite2D as Sprite2D
	if sprite:
		sprite.modulate = Color(0.8, 0.2, 1.0)
		sprite.self_modulate = Color.WHITE

	var collision = $Area2D/CollisionShape2D as CollisionShape2D
	if collision and not collision.shape:
		var circle = CircleShape2D.new()
		circle.radius = 30.0
		collision.set_deferred("shape", circle)

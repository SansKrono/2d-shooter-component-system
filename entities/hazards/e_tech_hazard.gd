@tool
class_name TechHazard
extends Entity

func define_components() -> Array:
	return [
		C_EnvironmentEffect.new(C_EnvironmentEffect.EFFECT_TECH_HAZARD, 3.0, 20.0, 5.0),
		C_Transform.new(Vector2.ZERO),
	]

func on_ready() -> void:
	var sprite = $Sprite2D as Sprite2D
	if sprite:
		sprite.modulate = Color(0.2, 0.9, 1.0)
		sprite.self_modulate = Color.WHITE

	var collision = $Area2D/CollisionShape2D as CollisionShape2D
	if collision and not collision.shape:
		var circle = CircleShape2D.new()
		circle.radius = 20.0
		collision.set_deferred("shape", circle)

@tool
class_name DestructibleObstacle
extends Entity

func define_components() -> Array:
	return [C_Health.new(30.0, 0, 0, 0, false)]

func on_ready() -> void:
	if Engine.is_editor_hint():
		return
	# Generate orange sprite texture procedurally
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		var img := Image.create(56, 56, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.85, 0.45, 0.1))
		sprite.texture = ImageTexture.create_from_image(img)
		sprite.centered = true

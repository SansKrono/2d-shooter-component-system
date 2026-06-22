class_name CorruptedServerEntity
extends Entity

const C_HEALTH = preload("res://components/character/c_health.gd")
const C_TRANSFORM = preload("res://components/character/c_transform.gd")

var exploded: bool = false

func define_components() -> Array:
	return [C_HEALTH.new(50.0)]

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	name = "CorruptedServer"

	var sprite = Sprite2D.new()
	sprite.modulate = Color(0.5, 0.1, 0.8)
	add_child(sprite)

	var area = Area2D.new()
	add_child(area)

	var shape = CircleShape2D.new()
	shape.radius = 80.0
	var collision = CollisionShape2D.new()
	collision.shape = shape
	area.add_child(collision)

	area.body_entered.connect(_on_body_entered)

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if exploded:
		return

	var health = get_component(C_HEALTH)
	if health and health.current <= 0:
		_explode()

func _on_body_entered(body: Node) -> void:
	if body is Player:
		var health = get_component(C_HEALTH)
		if health:
			health.current -= 15.0

func _explode() -> void:
	exploded = true
	print("[CorruptedServer] Exploding")
	queue_free()

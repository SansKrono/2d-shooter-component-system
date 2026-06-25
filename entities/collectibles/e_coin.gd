@tool
class_name Coin
extends Entity

const C_CURRENCY_SCRIPT = preload("res://components/economy/c_currency.gd")

@export var value: int = 5

var _magnet_target: Node2D = null
var _magnet_speed := 400.0
var _collected := false

func define_components() -> Array:
	return []

func on_ready() -> void:
	if Engine.is_editor_hint():
		return
	_setup_areas()
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		NodeFX.hover(sprite)

func _setup_areas() -> void:
	var pickup_area = Area2D.new()
	pickup_area.name = "PickupArea"
	var pickup_shape = CollisionShape2D.new()
	var pickup_circle = CircleShape2D.new()
	pickup_circle.radius = 30.0
	pickup_shape.shape = pickup_circle
	pickup_area.add_child(pickup_shape)
	add_child(pickup_area)
	pickup_area.body_entered.connect(_on_pickup)

	var magnet_area = Area2D.new()
	magnet_area.name = "MagnetArea"
	var magnet_shape = CollisionShape2D.new()
	var magnet_circle = CircleShape2D.new()
	magnet_circle.radius = 150.0
	magnet_shape.shape = magnet_circle
	magnet_area.add_child(magnet_shape)
	add_child(magnet_area)
	magnet_area.body_entered.connect(func(b: Node): if b is Player: _magnet_target = b)
	magnet_area.body_exited.connect(func(b): if b == _magnet_target: _magnet_target = null)

func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _collected:
		return
	var node = get_node(".") as Node2D
	if not node:
		return
	if is_instance_valid(_magnet_target):
		var dir = _magnet_target.global_position - node.global_position
		if dir.length() > 2.0:
			node.global_position += dir.normalized() * _magnet_speed * delta

func _on_pickup(body: Node) -> void:
	if _collected or not (body is Player):
		return
	_collected = true
	var c_curr = body.get_component(C_CURRENCY_SCRIPT) as C_CURRENCY_SCRIPT
	if c_curr:
		c_curr.amount += value
		print("[Coin] Added %d coins. Total: %d" % [value, c_curr.amount])
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		NodeFX.kill_hover(sprite)
	var tween = create_tween()
	tween.set_parallel(true)
	var node2d = get_node(".") as Node2D
	tween.tween_property(self, "position:y", node2d.position.y - 60.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await get_tree().create_timer(0.6).timeout
	if ECS.world:
		ECS.world.remove_entity(self)
	queue_free()

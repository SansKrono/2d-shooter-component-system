@tool
class_name TechHazard
extends Entity

const C_HEALTH = preload("res://components/combat/c_health.gd")

@export var damage_per_tick: float = 3.0
@export var tick_interval: float = 0.5
@export var lifetime: float = 20.0

var _bodies_in_area: Array = []

func define_components() -> Array:
	return []

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

	if Engine.is_editor_hint():
		return

	var area = $Area2D as Area2D
	if area:
		area.body_entered.connect(func(b): _bodies_in_area.append(b))
		area.body_exited.connect(func(b): _bodies_in_area.erase(b))

	var tick_timer = Timer.new()
	tick_timer.wait_time = tick_interval
	tick_timer.autostart = true
	tick_timer.timeout.connect(_on_tick)
	add_child(tick_timer)

	var lifetime_timer = Timer.new()
	lifetime_timer.wait_time = lifetime
	lifetime_timer.one_shot = true
	lifetime_timer.autostart = true
	lifetime_timer.timeout.connect(queue_free)
	add_child(lifetime_timer)

func _on_tick() -> void:
	for body in _bodies_in_area:
		if not is_instance_valid(body):
			continue
		if body.has_method("get_component"):
			var c_health = body.call("get_component", C_HEALTH)
			if c_health:
				c_health.current = max(0.0, c_health.current - damage_per_tick)
				print("[TechHazard] %.1f damage to %s" % [damage_per_tick, body.name])

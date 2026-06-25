@tool
class_name Bullet
extends Entity

@export var speed: float = 600.0
@export var damage: float = 10.0
@export var knockback_force: float = 200.0
@export var max_range: float = 600.0
@export var homing_strength: float = 0.0
@export var pierce_count: int = 0
@export var fire_mode_tag: String = ""
@export var is_critical: bool = false
@export var path_modifiers: Array = []

var direction: Vector2 = Vector2.ZERO
var shooter: Entity = null
var _distance_traveled: float = 0.0
var _hit_count: int = 0
var _homing_target: Node2D = null
var _homing_search_timer: float = 0.0
var _node: Node2D = null

@onready var area_2d: Area2D = $Area2D

func define_components() -> Array:
	return []

func on_ready() -> void:
	_node = get_node(".") as Node2D
	if not Engine.is_editor_hint():
		area_2d.area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or is_queued_for_deletion() or not _node:
		return

	for mod in path_modifiers:
		if mod.has_method("update_path"):
			mod.update_path(self, delta)

	if homing_strength > 0.0:
		_homing_search_timer -= delta
		if _homing_search_timer <= 0.0:
			_homing_search_timer = 0.2
			_find_homing_target()
		if is_instance_valid(_homing_target):
			var target_dir = (_homing_target.global_position - _node.global_position).normalized()
			direction = direction.lerp(target_dir, homing_strength * delta).normalized()

	_node.global_position += direction * speed * delta
	_distance_traveled += speed * delta

	if direction != Vector2.ZERO:
		_node.rotation = direction.angle()

	if _distance_traveled >= max_range:
		_expire()

func _find_homing_target() -> void:
	if not is_inside_tree():
		return
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest: Node2D = null
	var min_dist := INF
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy is Node2D:
			continue
		if enemy.has_method("get_component"):
			var h = enemy.call("get_component", C_Health)
			if h and h.current <= 0.0:
				continue
		var dist = _node.global_position.distance_to(enemy.global_position)
		if dist < min_dist:
			min_dist = dist
			closest = enemy
	_homing_target = closest

func _on_area_entered(area: Area2D) -> void:
	if is_queued_for_deletion():
		return
	var target = area.owner as Entity
	if target and target != self and not target is Bullet and target != shooter:
		CombatSystem.apply_hit(self, target)

func _expire() -> void:
	if is_queued_for_deletion():
		return
	if ECS.world:
		ECS.world.remove_entity(self)
	queue_free()

class_name Enemy
extends Entity

const C_ENEMY = preload("res://components/behaviour/c_enemy.gd")
const C_BOSS_ARMOR = preload("res://components/combat/c_boss_armor.gd")
const COIN_SCENE := preload("res://entities/collectibles/e_coin.tscn")

enum EnemyType { CHASER, SHOOTER }

@export var type: EnemyType = EnemyType.CHASER

var _body: CharacterBody2D
var _knockback := Vector2.ZERO
var _current_velocity := Vector2.ZERO
var _i_frames_timer := 0.0
var _is_dying := false
var _is_offscreen := false
var speed := 80.0
var acceleration := 400.0
var friction := 800.0

func _init(t = null) -> void:
	if t != null:
		type = t
	elif not Engine.is_editor_hint():
		type = EnemyType.CHASER if randf() < 0.5 else EnemyType.SHOOTER

func define_components() -> Array:
	if type == EnemyType.CHASER:
		return [
			C_Health.new(50.0),
			C_Resilience.new(3.0, 1.5, 0.4),
			C_Input.new(),
			C_AIStateMachine.new(C_AIStateMachine.State.IDLE, 300.0, 0.0, 15.0),
			C_ENEMY.new(),
		]
	else:
		return [
			C_Health.new(40.0),
			C_Resilience.new(1.0, 1.0, 0.4),
			C_Input.new(),
			C_Shooter.new(1.5, 250.0),
			C_Payload.new(10.0, 150.0),
			C_AIStateMachine.new(C_AIStateMachine.State.IDLE, 300.0, 200.0, 5.0),
			C_ENEMY.new(),
		]

func on_ready() -> void:
	_body = get_node(".") as CharacterBody2D
	add_to_group("enemies")

	if Engine.is_editor_hint():
		return

	var notifier = get_node_or_null("VisibilityNotifier") as VisibleOnScreenNotifier2D
	if notifier:
		notifier.screen_exited.connect(func(): _is_offscreen = true)
		notifier.screen_entered.connect(func(): _is_offscreen = false)

	match type:
		EnemyType.CHASER:
			speed = 80.0
			acceleration = 400.0
			friction = 800.0
		EnemyType.SHOOTER:
			speed = 40.0
			acceleration = 200.0
			friction = 600.0

	var sprite = get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		if name == "EBoss":
			sprite.modulate = Color(0.8, 0.3, 0.9)
		elif type == EnemyType.CHASER:
			sprite.modulate = Color(1.0, 0.4, 0.4)
		else:
			sprite.modulate = Color(0.4, 0.6, 1.0)

	var area_2d = get_node_or_null("Area2D") as Area2D
	if area_2d:
		area_2d.area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or not _body or _is_dying:
		return

	var c_input = get_component(C_Input) as C_Input
	var move_dir = c_input.movement_vector if c_input else Vector2.ZERO

	if move_dir != Vector2.ZERO:
		_current_velocity = _current_velocity.move_toward(move_dir * speed, acceleration * delta)
	else:
		_current_velocity = _current_velocity.move_toward(Vector2.ZERO, friction * delta)

	_knockback = _knockback.move_toward(Vector2.ZERO, friction * delta)

	if _i_frames_timer > 0.0:
		_i_frames_timer -= delta

	_body.velocity = _current_velocity + _knockback
	_body.move_and_slide()

func _on_area_entered(area: Area2D) -> void:
	var target = area.owner as Entity
	if target and target is Player:
		CombatSystem.apply_contact_damage(self, target)

func take_damage(amount: float, knockback: Vector2, is_explosive: bool = false) -> bool:
	if _i_frames_timer > 0.0 or _is_dying:
		return false

	var c_health = get_component(C_Health) as C_Health
	if not c_health:
		return false

	var final_damage = amount

	# Boss armor scaling (separate from standard armor already applied by CombatSystem)
	var c_boss = get_component(C_BOSS_ARMOR) if has_component(C_BOSS_ARMOR) else null
	if c_boss and not is_explosive:
		final_damage = _calculate_scaled_damage(final_damage, c_boss)

	c_health.current = max(0.0, c_health.current - final_damage)
	_knockback += knockback

	var c_res = get_component(C_Resilience) as C_Resilience
	if c_res and c_res.invulnerability_duration > 0.0:
		_i_frames_timer = c_res.invulnerability_duration

	print("[Enemy] %s took %.1f damage. Health: %.1f/%.1f" % [name, final_damage, c_health.current, c_health.maximum])

	if c_health.current <= 0.0:
		die()

	return true

func die() -> void:
	_is_dying = true
	if _body:
		_body.velocity = Vector2.ZERO

	var fx_target = get_node_or_null("Sprite2D")
	if not fx_target:
		fx_target = get_node_or_null("AnimatedSprite2D")
	if fx_target:
		NodeFX.pop(fx_target, 0.3, true)
		NodeFX.fade(fx_target, 0.3, false, true)

	var coin = COIN_SCENE.instantiate()
	var node = get_node(".") as Node2D
	coin.set("position", node.global_position)
	var parent = get_parent()
	if parent:
		parent.add_child(coin)
		if ECS.world and coin is Entity:
			ECS.world.add_entity(coin)

	await get_tree().create_timer(0.3).timeout

	if is_instance_valid(self):
		if ECS.world:
			ECS.world.remove_entity(self)
		else:
			queue_free()

func _calculate_scaled_damage(incoming: float, armor) -> float:
	var current_time = Time.get_ticks_msec() / 1000.0
	var damage_last_4s := 0.0
	for record in armor.damage_history:
		if current_time - record.time <= 4.0:
			damage_last_4s += record.amount

	var dps_soft_cap = armor.base_hp / max(1.0, armor.armor_value)

	if incoming > dps_soft_cap * 4.0:
		incoming *= 0.25

	var damage_ratio = damage_last_4s / dps_soft_cap
	var multiplier = clamp(1.0 - (damage_ratio * 0.1), 0.09, 1.0)

	armor.damage_history.append({"time": current_time, "amount": incoming * multiplier})
	# Prune stale history
	armor.damage_history = armor.damage_history.filter(
		func(r): return current_time - r.time <= 4.0
	)

	return incoming * multiplier

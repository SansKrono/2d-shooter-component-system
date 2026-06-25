class_name Player
extends Entity

const C_ATTACK_MODE = preload("res://components/player/c_attack_mode.gd")
const C_MANA = preload("res://components/status/c_mana.gd")
const C_POWER = preload("res://components/status/c_power.gd")
const C_PROJECTILE_STATS = preload("res://components/projectile/c_projectile_stats.gd")
const C_BOSS_ARMOR = preload("res://components/combat/c_boss_armor.gd")

@export var speed := 200.0
@export var acceleration := 900.0
@export var friction := 800.0

var _body: CharacterBody2D
var _knockback := Vector2.ZERO
var _current_velocity := Vector2.ZERO
var _i_frames_timer := 0.0
var _is_dying := false

func define_components() -> Array:
	return [
		C_Health.new(100.0, 6, 0, 0, true),
		C_Input.new(),
		C_Shooter.new(0.15, 500.0),
		C_Payload.new(12.0, 200.0),
		C_Trajectory.new(600.0, 8.0, 2.5),
		C_Volatility.new(0.3, 2.0),
		C_Luck.new(2.0),
		C_Currency.new(100),
		C_RelicInventory.new(),
		C_MANA.new(100.0, 8.0),
		C_POWER.new(100.0, 15.0),
		C_PROJECTILE_STATS.new(0.15, 0.20),
		C_ATTACK_MODE.new(),
		C_Resilience.new(0.0, 1.0, 0.5),
	]

func on_ready() -> void:
	_body = get_node(".") as CharacterBody2D
	var camera = $DungeonCamera as Camera2D
	if camera and not Engine.is_editor_hint():
		if camera.zoom != Vector2.ZERO:
			camera.make_current()
		else:
			print("[Player] Warning: Camera zoom is zero, deferring make_current()")
			call_deferred("_make_camera_current")

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

func take_damage(amount: float, knockback: Vector2, _is_explosive: bool = false) -> bool:
	if _i_frames_timer > 0.0 or _is_dying:
		return false

	var c_health = get_component(C_Health) as C_Health
	if not c_health:
		return false

	c_health.current = max(0.0, c_health.current - amount)
	_knockback += knockback

	var c_res = get_component(C_Resilience) as C_Resilience
	if c_res and c_res.invulnerability_duration > 0.0:
		_i_frames_timer = c_res.invulnerability_duration

	print("[Player] Took %.1f damage. Health: %.1f/%.1f" % [amount, c_health.current, c_health.maximum])

	if c_health.current <= 0.0:
		die()

	return true

func _make_camera_current() -> void:
	var camera = $DungeonCamera as Camera2D
	if camera and camera.zoom != Vector2.ZERO:
		camera.make_current()

func die() -> void:
	_is_dying = true
	print("[Player] Died!")
	if ECS.world:
		ECS.world.remove_entity(self)

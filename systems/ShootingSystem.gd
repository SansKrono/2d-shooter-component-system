class_name ShootingSystem
extends System

const BULLET_PREFAB = preload("res://entities/projectiles/e_bullet.tscn")
const C_ATTACK_MODE = preload("res://components/player/c_attack_mode.gd")
const C_MANA = preload("res://components/status/c_mana.gd")
const C_POWER = preload("res://components/status/c_power.gd")
const C_PROJECTILE_STATS = preload("res://components/projectile/c_projectile_stats.gd")
const SPIRAL_MOD = preload("res://resources/effects/spiral_path_modifier.gd")
const CURSOR_TECH = preload("res://assets/shoot-cursor-tech.png")
const CURSOR_MAGIC = preload("res://assets/shoot-cursor-magic.png")

var screen_shake_system = null

func query() -> QueryBuilder:
	return q.with_all([C_Input, C_Shooter])

func process(entities: Array[Entity], _components: Array, delta: float) -> void:
	if not screen_shake_system and get_parent():
		screen_shake_system = get_parent().get_node_or_null("ScreenShakeSystem")

	for entity in entities:
		var c_input = entity.get_component(C_Input) as C_Input
		var c_shooter = entity.get_component(C_Shooter) as C_Shooter
		if not c_input or not c_shooter:
			continue

		var c_am = entity.get_component(C_ATTACK_MODE)
		if c_am:
			_process_attack_mode(entity, c_input, c_am, delta)
		else:
			_process_legacy(entity, c_input, c_shooter, delta)

func _process_legacy(entity: Entity, c_input: C_Input, c_shooter: C_Shooter, delta: float) -> void:
	if c_shooter.cooldown_timer > 0.0:
		c_shooter.cooldown_timer -= delta

	if c_input.shoot_vector != Vector2.ZERO and c_shooter.cooldown_timer <= 0.0:
		c_shooter.cooldown_timer = c_shooter.fire_rate

		var c_pay = entity.get_component(C_Payload) as C_Payload
		var c_traj = entity.get_component(C_Trajectory) as C_Trajectory
		var c_vol = entity.get_component(C_Volatility) as C_Volatility

		var shoot_dir = c_input.shoot_vector
		if c_traj:
			var dev = c_traj.accuracy_deviation
			shoot_dir = shoot_dir.rotated(deg_to_rad(randf_range(-dev, dev)))

		var is_crit = false
		var bullet_damage = c_pay.damage if c_pay else 10.0
		var knockback = c_pay.knockback_force if c_pay else 150.0
		if c_vol:
			is_crit = randf() < c_vol.crit_chance
			if is_crit:
				bullet_damage *= c_vol.crit_multiplier

		var bullet = BULLET_PREFAB.instantiate() as Bullet
		bullet.shooter = entity
		if "global_position" in entity:
			bullet.set("position", entity.get("global_position"))
		bullet.set("scale", Vector2.ONE * c_shooter.bullet_size)
		bullet.direction = shoot_dir
		bullet.speed = c_shooter.bullet_speed
		bullet.damage = bullet_damage
		bullet.knockback_force = knockback
		bullet.max_range = c_traj.max_range if c_traj else 500.0
		bullet.homing_strength = c_traj.homing_strength if c_traj else 0.0
		bullet.is_critical = is_crit

		var c_path = entity.get_component(C_BulletPath) as C_BulletPath
		if c_path and not c_path.path_modifiers.is_empty():
			bullet.path_modifiers = c_path.path_modifiers

		if is_crit:
			var sprite = bullet.get_node_or_null("Sprite2D") as Sprite2D
			if sprite:
				sprite.self_modulate = Color.RED

		cmd.add_entity(bullet)

func _process_attack_mode(entity: Entity, c_input: C_Input, c_am: C_AttackMode, delta: float) -> void:
	var c_proj_stats = entity.get_component(C_PROJECTILE_STATS) as C_PROJECTILE_STATS
	if not c_proj_stats:
		return

	if c_am.tech_fire_timer > 0.0:
		c_am.tech_fire_timer -= delta
	if c_am.magic_fire_timer > 0.0:
		c_am.magic_fire_timer -= delta

	if not c_am.visual_initialized:
		_apply_mode_visual(entity, C_ATTACK_MODE.MODE_TECH)
		c_am.visual_initialized = true

	if c_input.fire_button_held and c_am.tech_fire_timer <= 0.0:
		var c_power = entity.get_component(C_POWER) as C_Power
		if not c_power or c_power.current >= 10.0:
			if c_power:
				c_power.current -= 10.0
			_fire_tech_straight(entity, c_input)
			c_am.tech_fire_timer = c_proj_stats.tech_delay

	if c_input.magic_button_held and c_am.magic_fire_timer <= 0.0:
		var c_mana = entity.get_component(C_MANA) as C_Mana
		if not c_mana or c_mana.current >= 10.0:
			if c_mana:
				c_mana.current -= 10.0
			_fire_magic_spiral(entity, c_input)
			c_am.magic_fire_timer = c_proj_stats.magic_delay

	if c_input.tech_charged_held:
		c_am.tech_charge_timer += delta
		c_am.tech_charge_level = clamp(c_am.tech_charge_timer / C_ATTACK_MODE.CHARGE_DURATION, 0.0, 1.0)
		_apply_charge_visual(entity, c_am.tech_charge_level, C_ATTACK_MODE.MODE_TECH)

	if c_input.tech_charged_just_released:
		if c_am.tech_charge_level > 0.0:
			_fire_charged_tech(entity, c_input, c_am)
		c_am.tech_charge_level = 0.0
		c_am.tech_charge_timer = 0.0

	if c_input.magic_charged_held:
		c_am.magic_charge_timer += delta
		c_am.magic_charge_level = clamp(c_am.magic_charge_timer / C_ATTACK_MODE.CHARGE_DURATION, 0.0, 1.0)
		_apply_charge_visual(entity, c_am.magic_charge_level, C_ATTACK_MODE.MODE_MAGIC)

	if c_input.magic_charged_just_released:
		if c_am.magic_charge_level > 0.0:
			_fire_charged_magic(entity, c_input, c_am)
		c_am.magic_charge_level = 0.0
		c_am.magic_charge_timer = 0.0

func _fire_tech_straight(shooter: Entity, c_input: C_Input) -> void:
	var bullet = _make_bullet(shooter)
	bullet.direction = _safe_aim(c_input)
	bullet.speed = 600.0
	bullet.damage = 12.0
	bullet.knockback_force = 200.0
	bullet.max_range = 600.0
	bullet.fire_mode_tag = "TECH"
	_apply_crit(bullet, shooter)
	var sprite = bullet.get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		sprite.modulate = Color(0.4, 0.8, 1.0)
	cmd.add_entity(bullet)

func _fire_tech_fan(shooter: Entity, c_input: C_Input) -> void:
	var base_dir = _safe_aim(c_input)
	for angle in [-15.0, 0.0, 15.0]:
		var bullet = _make_bullet(shooter)
		bullet.direction = base_dir.rotated(deg_to_rad(angle))
		bullet.speed = 600.0
		bullet.damage = 10.0
		bullet.knockback_force = 200.0
		bullet.max_range = 600.0
		bullet.fire_mode_tag = "TECH"
		_apply_crit(bullet, shooter)
		var sprite = bullet.get_node_or_null("Sprite2D") as Sprite2D
		if sprite:
			sprite.modulate = Color(0.4, 0.8, 1.0)
		cmd.add_entity(bullet)

func _fire_tech_beam(shooter: Entity, c_input: C_Input, charge: float) -> void:
	var bullet = _make_bullet(shooter)
	bullet.direction = _safe_aim(c_input)
	bullet.speed = 1200.0
	bullet.damage = 25.0 * charge
	bullet.knockback_force = 250.0
	bullet.max_range = 1200.0
	bullet.pierce_count = -1
	bullet.fire_mode_tag = "TECH"
	bullet.set("scale", Vector2(3.0, 0.5))
	var sprite = bullet.get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		sprite.modulate = Color(0.2, 0.9, 1.0)
	cmd.add_entity(bullet)

func _fire_magic_spiral(shooter: Entity, c_input: C_Input) -> void:
	var base_dir = _safe_aim(c_input)
	var direction = base_dir.rotated(deg_to_rad(randf_range(-30.0, 30.0)))
	var bullet = _make_bullet(shooter)
	bullet.direction = direction
	bullet.speed = 400.0
	bullet.damage = 15.0
	bullet.knockback_force = 180.0
	bullet.max_range = 500.0
	bullet.fire_mode_tag = "MAGIC"
	var spiral = SPIRAL_MOD.new()
	spiral.rotation_speed = 6.0
	bullet.path_modifiers = [spiral]
	var sprite = bullet.get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		sprite.modulate = Color(0.8, 0.2, 1.0)
	cmd.add_entity(bullet)

func _fire_magic_wave(shooter: Entity, c_input: C_Input) -> void:
	var base_dir = _safe_aim(c_input)
	for angle in [-20.0, 0.0, 20.0]:
		var bullet = _make_bullet(shooter)
		bullet.direction = base_dir.rotated(deg_to_rad(angle))
		bullet.speed = 350.0
		bullet.damage = 18.0
		bullet.knockback_force = 160.0
		bullet.max_range = 500.0
		bullet.homing_strength = 3.0
		bullet.fire_mode_tag = "MAGIC"
		var sprite = bullet.get_node_or_null("Sprite2D") as Sprite2D
		if sprite:
			sprite.modulate = Color(0.6, 0.1, 0.9)
		cmd.add_entity(bullet)

func _fire_magic_burst(shooter: Entity, _c_input: C_Input, charge: float) -> void:
	for i in range(8):
		var direction = Vector2.RIGHT.rotated(deg_to_rad(i * 45.0))
		var bullet = _make_bullet(shooter)
		bullet.direction = direction
		bullet.speed = 300.0
		bullet.damage = 20.0 * charge
		bullet.knockback_force = 200.0
		bullet.max_range = 200.0
		bullet.fire_mode_tag = "MAGIC"
		var sprite = bullet.get_node_or_null("Sprite2D") as Sprite2D
		if sprite:
			sprite.modulate = Color(1.0, 0.0, 0.8)
		cmd.add_entity(bullet)

func _fire_charged_tech(entity: Entity, c_input: C_Input, c_am: C_AttackMode) -> void:
	var c_power = entity.get_component(C_POWER) as C_Power
	if c_am.tech_charge_level < 0.5:
		var cost = 20.0
		if not c_power or c_power.current >= cost:
			if c_power:
				c_power.current -= cost
			_fire_tech_fan(entity, c_input)
			_trigger_screen_shake(3.0, 0.15)
	else:
		var cost = 30.0
		if not c_power or c_power.current >= cost:
			if c_power:
				c_power.current -= cost
			_fire_tech_beam(entity, c_input, c_am.tech_charge_level)
			_trigger_screen_shake(6.0, 0.3)

func _fire_charged_magic(entity: Entity, c_input: C_Input, c_am: C_AttackMode) -> void:
	var c_mana = entity.get_component(C_MANA) as C_Mana
	if c_am.magic_charge_level < 0.5:
		var cost = 20.0
		if not c_mana or c_mana.current >= cost:
			if c_mana:
				c_mana.current -= cost
			_fire_magic_wave(entity, c_input)
			_trigger_screen_shake(2.5, 0.2)
	else:
		var cost = 35.0
		if not c_mana or c_mana.current >= cost:
			if c_mana:
				c_mana.current -= cost
			_fire_magic_burst(entity, c_input, c_am.magic_charge_level)
			_trigger_screen_shake(5.0, 0.25)

func _make_bullet(shooter: Entity) -> Bullet:
	var bullet = BULLET_PREFAB.instantiate() as Bullet
	bullet.shooter = shooter
	if "global_position" in shooter:
		bullet.set("position", shooter.get("global_position"))
	return bullet

func _apply_crit(bullet: Bullet, shooter: Entity) -> void:
	var c_vol = shooter.get_component(C_Volatility) as C_Volatility
	if c_vol and randf() < c_vol.crit_chance:
		bullet.is_critical = true
		var sprite = bullet.get_node_or_null("Sprite2D") as Sprite2D
		if sprite:
			sprite.self_modulate = Color.RED

func _apply_mode_visual(entity: Entity, mode: String) -> void:
	var sprite = entity.get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		sprite.modulate = Color(0.4, 0.8, 1.0) if mode == "TECH" else Color(0.8, 0.2, 1.0)
	if mode == "TECH":
		DisplayServer.cursor_set_custom_image(CURSOR_TECH, DisplayServer.CURSOR_ARROW, Vector2(32, 32))
	else:
		DisplayServer.cursor_set_custom_image(CURSOR_MAGIC, DisplayServer.CURSOR_ARROW, Vector2(32, 32))

func _apply_charge_visual(entity: Entity, charge: float, mode: String) -> void:
	var sprite = entity.get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		var base_color = Color(0.4, 0.8, 1.0) if mode == "TECH" else Color(0.8, 0.2, 1.0)
		sprite.modulate = base_color.lerp(Color.WHITE, charge * 0.4)

func _trigger_screen_shake(intensity: float, duration: float) -> void:
	if screen_shake_system:
		screen_shake_system.trigger_shake(intensity, duration)

func _safe_aim(c_input: C_Input) -> Vector2:
	return c_input.aim_direction if c_input.aim_direction != Vector2.ZERO else Vector2.RIGHT

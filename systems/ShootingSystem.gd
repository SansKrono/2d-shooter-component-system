class_name ShootingSystem
extends System

const BULLET_PREFAB = preload("res://entities/projectiles/e_bullet.tscn")
const C_BULLET_PATH_COMPONENT = preload("res://components/projectile/c_bullet_path.gd")
const C_LOCOMOTION = preload("res://components/movement/c_locomotion.gd")
const C_ATTACK_MODE = preload("res://components/player/c_attack_mode.gd")
const C_PIERCING = preload("res://components/projectile/c_piercing.gd")
const C_PHYSICS = preload("res://components/movement/c_physics.gd")
const C_MANA = preload("res://components/status/c_mana.gd")
const C_POWER = preload("res://components/status/c_power.gd")
const C_FIRE_MODE = preload("res://components/player/c_fire_mode.gd")
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
		# Reset cooldown
		c_shooter.cooldown_timer = c_shooter.fire_rate

		# Fetch player stats components
		var c_pay = entity.get_component(C_Payload) as C_Payload
		var c_traj = entity.get_component(C_Trajectory) as C_Trajectory
		var c_vol = entity.get_component(C_Volatility) as C_Volatility

		# 1. Accuracy spread calculation
		var shoot_dir = c_input.shoot_vector
		if c_traj:
			var dev = c_traj.accuracy_deviation
			var angle_offset = randf_range(-dev, dev)
			shoot_dir = shoot_dir.rotated(deg_to_rad(angle_offset))

		# 2. Critical hit calculation
		var is_crit = false
		var bullet_damage = c_pay.damage if c_pay else 10.0
		var knockback = c_pay.knockback_force if c_pay else 150.0
		var aoe = c_pay.area_of_effect if c_pay else 0.0

		if c_vol:
			is_crit = randf() < c_vol.crit_chance
			if is_crit:
				bullet_damage *= c_vol.crit_multiplier

		# Instantiate bullet prefab
		var bullet = BULLET_PREFAB.instantiate() as Entity
		bullet.shooter = entity

		# Set starting position to parent's position
		if "global_position" in entity:
			bullet.position = entity.global_position

		# Apply visual feedback for crits (turn sprite red)
		if is_crit:
			var sprite = bullet.get_node_or_null("Sprite2D") as Sprite2D
			if sprite:
				sprite.self_modulate = Color.RED

		# Scale bullet visually and physically
		bullet.scale = Vector2.ONE * c_shooter.bullet_size

		# Attach bullet path modifiers if the shooter has any
		var c_path = entity.get_component(C_BulletPath) as C_BulletPath
		if c_path and not c_path.path_modifiers.is_empty():
			bullet.add_component(C_BulletPath.new(c_path.path_modifiers))

		# Compose components for the bullet
		bullet.add_component(C_Velocity.new(shoot_dir))
		# Projectile uses C_Locomotion with instant acceleration and no decay
		# to travel at constant speed in the given direction
		bullet.add_component(C_LOCOMOTION.new(c_shooter.bullet_speed, 99999.0, 99999.0))
		bullet.add_component(C_Payload.new(bullet_damage, knockback, aoe))

		var bullet_range = c_traj.max_range if c_traj else 500.0
		var bullet_homing = c_traj.homing_strength if c_traj else 0.0
		bullet.add_component(C_Trajectory.new(bullet_range, 0.0, bullet_homing))

		var bullet_vol = C_Volatility.new()
		bullet_vol.is_critical = is_crit
		bullet.add_component(bullet_vol)

		# Queue addition to world via CommandBuffer
		cmd.add_entity(bullet)

func _process_attack_mode(entity: Entity, c_input: C_Input, c_am: C_AttackMode, delta: float) -> void:
	var c_proj_stats = entity.get_component(C_PROJECTILE_STATS) as C_PROJECTILE_STATS
	if not c_proj_stats:
		return

	# Tick fire timers
	if c_am.tech_fire_timer > 0.0:
		c_am.tech_fire_timer -= delta
	if c_am.magic_fire_timer > 0.0:
		c_am.magic_fire_timer -= delta

	# Initialize visual on first frame
	if not c_am.visual_initialized:
		_apply_mode_visual(entity, C_ATTACK_MODE.MODE_TECH)
		c_am.visual_initialized = true

	# Tech continuous fire (LMB held)
	if c_input.fire_button_held and c_am.tech_fire_timer <= 0.0:
		var c_power = entity.get_component(C_POWER) as C_Power
		if not c_power or c_power.current >= 10.0:
			if c_power:
				c_power.current -= 10.0
			_fire_tech_straight(entity, c_input)
			c_am.tech_fire_timer = c_proj_stats.tech_delay

	# Magic continuous fire (RMB held)
	if c_input.magic_button_held and c_am.magic_fire_timer <= 0.0:
		var c_mana = entity.get_component(C_MANA) as C_Mana
		if not c_mana or c_mana.current >= 10.0:
			if c_mana:
				c_mana.current -= 10.0
			_fire_magic_spiral(entity, c_input)
			c_am.magic_fire_timer = c_proj_stats.magic_delay

	# Tech charged fire (Q held)
	if c_input.tech_charged_held:
		c_am.tech_charge_timer += delta
		c_am.tech_charge_level = clamp(c_am.tech_charge_timer / C_ATTACK_MODE.CHARGE_DURATION, 0.0, 1.0)
		_apply_charge_visual(entity, c_am.tech_charge_level, C_ATTACK_MODE.MODE_TECH)

	if c_input.tech_charged_just_released:
		if c_am.tech_charge_level > 0.0:
			_fire_charged_tech(entity, c_input, c_am)
		c_am.tech_charge_level = 0.0
		c_am.tech_charge_timer = 0.0

	# Magic charged fire (E held)
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
	var bullet = BULLET_PREFAB.instantiate() as Entity
	bullet.shooter = shooter
	if "global_position" in shooter:
		bullet.position = shooter.global_position

	var direction = _safe_aim(c_input)
	bullet.add_component(C_Velocity.new(direction))
	bullet.add_component(C_LOCOMOTION.new(600.0, 99999.0, 99999.0))
	bullet.add_component(C_Payload.new(12.0, 200.0, 0.0))
	bullet.add_component(C_Trajectory.new(600.0, 0.0, 0.0))
	bullet.add_component(C_FIRE_MODE.new("TECH"))

	var vol = C_Volatility.new()
	var c_vol = shooter.get_component(C_Volatility)
	if c_vol and randf() < c_vol.crit_chance:
		vol.is_critical = true
		var sprite_crit = bullet.get_node_or_null("Sprite2D") as Sprite2D
		if sprite_crit:
			sprite_crit.self_modulate = Color.RED
	bullet.add_component(vol)

	var sprite = bullet.get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		sprite.modulate = Color(0.4, 0.8, 1.0)

	cmd.add_entity(bullet)

func _fire_tech_fan(shooter: Entity, c_input: C_Input) -> void:
	var base_dir = _safe_aim(c_input)
	var angles = [-15.0, 0.0, 15.0]

	for angle in angles:
		var direction = base_dir.rotated(deg_to_rad(angle))
		var bullet = BULLET_PREFAB.instantiate() as Entity
		bullet.shooter = shooter
		if "global_position" in shooter:
			bullet.position = shooter.global_position

		bullet.add_component(C_Velocity.new(direction))
		bullet.add_component(C_LOCOMOTION.new(600.0, 99999.0, 99999.0))
		bullet.add_component(C_Payload.new(10.0, 200.0, 0.0))
		bullet.add_component(C_Trajectory.new(600.0, 0.0, 0.0))
		bullet.add_component(C_FIRE_MODE.new("TECH"))

		var vol = C_Volatility.new()
		var c_vol = shooter.get_component(C_Volatility)
		if c_vol and randf() < c_vol.crit_chance:
			vol.is_critical = true
			var sprite_crit = bullet.get_node_or_null("Sprite2D") as Sprite2D
			if sprite_crit:
				sprite_crit.self_modulate = Color.RED
		bullet.add_component(vol)

		var sprite = bullet.get_node_or_null("Sprite2D") as Sprite2D
		if sprite:
			sprite.modulate = Color(0.4, 0.8, 1.0)

		cmd.add_entity(bullet)

func _fire_tech_beam(shooter: Entity, c_input: C_Input, charge: float) -> void:
	var bullet = BULLET_PREFAB.instantiate() as Entity
	bullet.shooter = shooter
	if "global_position" in shooter:
		bullet.position = shooter.global_position

	var direction = _safe_aim(c_input)
	bullet.add_component(C_Velocity.new(direction))
	bullet.add_component(C_LOCOMOTION.new(1200.0, 99999.0, 99999.0))

	var damage = 25.0 * charge
	bullet.add_component(C_Payload.new(damage, 250.0, 0.0))
	bullet.add_component(C_Trajectory.new(1200.0, 0.0, 0.0))
	bullet.add_component(C_PIERCING.new(-1))
	bullet.add_component(C_FIRE_MODE.new("TECH"))

	var vol = C_Volatility.new()
	bullet.add_component(vol)

	# Stretch sprite to look like a beam
	bullet.scale = Vector2(3.0, 0.5)

	var sprite = bullet.get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		sprite.modulate = Color(0.2, 0.9, 1.0)

	cmd.add_entity(bullet)

func _fire_magic_spiral(shooter: Entity, c_input: C_Input) -> void:
	var base_dir = _safe_aim(c_input)
	var deviation = randf_range(-30.0, 30.0)
	var direction = base_dir.rotated(deg_to_rad(deviation))

	var bullet = BULLET_PREFAB.instantiate() as Entity
	bullet.shooter = shooter
	if "global_position" in shooter:
		bullet.position = shooter.global_position

	bullet.add_component(C_Velocity.new(direction))
	bullet.add_component(C_LOCOMOTION.new(400.0, 99999.0, 99999.0))
	bullet.add_component(C_Payload.new(15.0, 180.0, 0.0))
	bullet.add_component(C_Trajectory.new(500.0, 0.0, 0.0))
	bullet.add_component(C_FIRE_MODE.new("MAGIC"))

	# Add spiral path modifier
	var spiral = SPIRAL_MOD.new()
	spiral.rotation_speed = 6.0
	bullet.add_component(C_BulletPath.new([spiral]))

	var vol = C_Volatility.new()
	bullet.add_component(vol)

	var sprite = bullet.get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		sprite.modulate = Color(0.8, 0.2, 1.0)

	cmd.add_entity(bullet)

func _fire_magic_wave(shooter: Entity, c_input: C_Input) -> void:
	var base_dir = _safe_aim(c_input)
	var angles = [-20.0, 0.0, 20.0]

	for angle in angles:
		var direction = base_dir.rotated(deg_to_rad(angle))
		var bullet = BULLET_PREFAB.instantiate() as Entity
		bullet.shooter = shooter
		if "global_position" in shooter:
			bullet.position = shooter.global_position

		bullet.add_component(C_Velocity.new(direction))
		bullet.add_component(C_LOCOMOTION.new(350.0, 99999.0, 99999.0))
		bullet.add_component(C_Payload.new(18.0, 160.0, 0.0))
		bullet.add_component(C_Trajectory.new(500.0, 0.0, 3.0))
		bullet.add_component(C_FIRE_MODE.new("MAGIC"))

		var vol = C_Volatility.new()
		bullet.add_component(vol)

		var sprite = bullet.get_node_or_null("Sprite2D") as Sprite2D
		if sprite:
			sprite.modulate = Color(0.6, 0.1, 0.9)

		cmd.add_entity(bullet)

func _fire_magic_burst(shooter: Entity, _c_input: C_Input, charge: float) -> void:
	# 8 directions: 0°, 45°, 90°, 135°, 180°, 225°, 270°, 315°
	for i in range(8):
		var angle = (i * 45.0)
		var direction = Vector2.RIGHT.rotated(deg_to_rad(angle))

		var bullet = BULLET_PREFAB.instantiate() as Entity
		bullet.shooter = shooter
		if "global_position" in shooter:
			bullet.position = shooter.global_position

		bullet.add_component(C_Velocity.new(direction))
		bullet.add_component(C_LOCOMOTION.new(300.0, 99999.0, 99999.0))

		var damage = 20.0 * charge
		bullet.add_component(C_Payload.new(damage, 200.0, 0.0))
		bullet.add_component(C_Trajectory.new(200.0, 0.0, 0.0))
		bullet.add_component(C_FIRE_MODE.new("MAGIC"))

		var vol = C_Volatility.new()
		bullet.add_component(vol)

		var sprite = bullet.get_node_or_null("Sprite2D") as Sprite2D
		if sprite:
			sprite.modulate = Color(1.0, 0.0, 0.8)

		cmd.add_entity(bullet)

func _fire_charged_tech(entity: Entity, c_input: C_Input, c_am: C_AttackMode) -> void:
	var c_power = entity.get_component(C_POWER) as C_Power
	if c_am.tech_charge_level < 0.5:
		# Tap or short hold: fire fan
		var cost = 20.0
		if not c_power or c_power.current >= cost:
			if c_power:
				c_power.current -= cost
			_fire_tech_fan(entity, c_input)
			_trigger_screen_shake(3.0, 0.15)
	else:
		# Long hold: fire beam
		var cost = 30.0
		if not c_power or c_power.current >= cost:
			if c_power:
				c_power.current -= cost
			_fire_tech_beam(entity, c_input, c_am.tech_charge_level)
			_trigger_screen_shake(6.0, 0.3)

func _fire_charged_magic(entity: Entity, c_input: C_Input, c_am: C_AttackMode) -> void:
	var c_mana = entity.get_component(C_MANA) as C_Mana
	if c_am.magic_charge_level < 0.5:
		# Tap or short hold: fire wave
		var cost = 20.0
		if not c_mana or c_mana.current >= cost:
			if c_mana:
				c_mana.current -= cost
			_fire_magic_wave(entity, c_input)
			_trigger_screen_shake(2.5, 0.2)
	else:
		# Long hold: fire burst
		var cost = 35.0
		if not c_mana or c_mana.current >= cost:
			if c_mana:
				c_mana.current -= cost
			_fire_magic_burst(entity, c_input, c_am.magic_charge_level)
			_trigger_screen_shake(5.0, 0.25)

func _apply_mode_visual(entity: Entity, mode: String) -> void:
	var sprite = entity.get_node_or_null("Sprite2D") as Sprite2D
	if not sprite:
		# Try alternate path
		var c_phys = entity.get_component(C_PHYSICS)
		if c_phys and is_instance_valid(c_phys.body):
			sprite = c_phys.body.get_node_or_null("Sprite2D") as Sprite2D

	if sprite:
		sprite.modulate = Color(0.4, 0.8, 1.0) if mode == "TECH" else Color(0.8, 0.2, 1.0)

	if mode == "TECH":
		DisplayServer.cursor_set_custom_image(CURSOR_TECH, DisplayServer.CURSOR_ARROW, Vector2(32, 32))
	else:
		DisplayServer.cursor_set_custom_image(CURSOR_MAGIC, DisplayServer.CURSOR_ARROW, Vector2(32, 32))

func _apply_charge_visual(entity: Entity, charge: float, mode: String) -> void:
	var sprite = entity.get_node_or_null("Sprite2D") as Sprite2D
	if not sprite:
		var c_phys = entity.get_component(C_PHYSICS)
		if c_phys and is_instance_valid(c_phys.body):
			sprite = c_phys.body.get_node_or_null("Sprite2D") as Sprite2D

	if sprite:
		var base_color = Color(0.4, 0.8, 1.0) if mode == "TECH" else Color(0.8, 0.2, 1.0)
		sprite.modulate = base_color.lerp(Color.WHITE, charge * 0.4)

func _trigger_screen_shake(intensity: float, duration: float) -> void:
	if screen_shake_system:
		screen_shake_system.trigger_shake(intensity, duration)

func _safe_aim(c_input: C_Input) -> Vector2:
	return c_input.aim_direction if c_input.aim_direction != Vector2.ZERO else Vector2.RIGHT

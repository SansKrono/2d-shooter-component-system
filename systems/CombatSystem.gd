class_name CombatSystem
extends System

const C_MASS = preload("res://components/character/c_mass.gd")
const C_PENDING_DAMAGE = preload("res://components/character/c_pending_damage.gd")
const C_DAMAGE_TYPE = preload("res://components/character/c_damage_type.gd")
const C_LOCOMOTION = preload("res://components/character/c_locomotion.gd")
const C_PIERCING = preload("res://components/character/c_piercing.gd")
const C_ATTACK_MODE = preload("res://components/character/c_attack_mode.gd")
const C_FIRE_MODE = preload("res://components/character/c_fire_mode.gd")
const TECH_HAZARD_PREFAB = preload("res://entities/hazards/e_tech_hazard.tscn")
const CORRUPTION_HAZARD_PREFAB = preload("res://entities/hazards/e_corruption_hazard.tscn")

static func apply_hit(bullet: Entity, target: Entity) -> void:
	if not is_instance_valid(bullet) or not is_instance_valid(target):
		return

	# 1. Fetch target components
	var target_health = target.get_component(C_Health) as C_Health
	var target_res = target.get_component(C_Resilience) as C_Resilience

	if not target_health:
		return

	# 2. Check Invulnerability
	if target_res and target_res.current_i_frames > 0.0:
		return # Target is currently invulnerable

	# 3. Fetch bullet components
	var bullet_payload = bullet.get_component(C_Payload) as C_Payload
	var bullet_vel = bullet.get_component(C_Velocity) as C_Velocity
	var bullet_vol = bullet.get_component(C_Volatility) as C_Volatility
	var bullet_loco = bullet.get_component(C_LOCOMOTION) as C_Locomotion

	if not bullet_payload:
		return

	# 4. Damage calculations (armor mitigation)
	var base_damage = bullet_payload.damage
	var armor = target_res.armor if target_res else 0.0
	var final_damage = max(1.0, base_damage - armor)

	# 5. Calculate displacement knockback vector using mass ratio formula
	var displacement = Vector2.ZERO
	if bullet_vel:
		var speed = bullet_loco.base_speed if bullet_loco else 400.0
		var v_p = bullet_vel.direction * speed
		if v_p == Vector2.ZERO:
			v_p = (target.global_position - bullet.global_position).normalized() * speed
		var m_p = 8.0
		if bullet.has_component(C_MASS):
			m_p = bullet.get_component(C_MASS).mass
		var m_t = 10.0
		if target.has_component(C_MASS):
			m_t = target.get_component(C_MASS).mass
		elif target_res:
			m_t = target_res.weight * 10.0
		
		var K = 1.7
		displacement = v_p * K * (m_p / m_t)

	# 6. Append C_PendingDamage component to target
	var pending = C_PENDING_DAMAGE.new(final_damage, displacement)
	target.add_component(pending)

	# Propagate damage type if applicable (e.g. explosive)
	if bullet.has_component(C_DAMAGE_TYPE):
		var dtype = bullet.get_component(C_DAMAGE_TYPE)
		target.add_component(C_DAMAGE_TYPE.new(dtype.damage_type))

	# 7. Print debug log
	var is_crit = bullet_vol.is_critical if bullet_vol else false
	var crit_label = " [CRITICAL!]" if is_crit else ""
	print("[Combat] Hit %s! Damage: %.1f%s (Armor: %.1f)" % [
		target.name, final_damage, crit_label, armor
	])

	# 8. Trigger Invulnerability Frames
	if target_res and target_res.invulnerability_duration > 0.0:
		target_res.current_i_frames = target_res.invulnerability_duration

	# 9. Trigger Bullet Split passive if applicable
	if "shooter" in bullet and is_instance_valid(bullet.shooter):
		var c_inv = bullet.shooter.get_component(C_RelicInventory) as C_RelicInventory
		if c_inv:
			var split_effects = c_inv.get_effects_of_type(BulletSplitEffect)
			for split_effect in split_effects:
				var luck_val = 1.0
				var c_luck = bullet.shooter.get_component(C_Luck) as C_Luck
				if c_luck:
					luck_val = c_luck.value
				
				var base_chance = split_effect.base_chance
				var split_chance = clamp(base_chance * luck_val, 0.0, 1.0)
				
				if randf() < split_chance:
					print("[Combat] Plasma Splitter split passive triggered! (Chance: %.2f)" % split_chance)
					_spawn_split_bullets(bullet, target, split_effect)

	# 10. Spawn environment hazard on impact if bullet has fire mode
	var c_fire_mode = bullet.get_component(C_FIRE_MODE) as C_FIRE_MODE
	if c_fire_mode:
		_spawn_hazard_on_impact(bullet, c_fire_mode.mode)
		_spawn_impact_effect(bullet, c_fire_mode.mode)

	# 11. Check for piercing before destroying bullet
	var c_piercing = bullet.get_component(C_PIERCING) as C_Piercing
	if c_piercing:
		c_piercing.hit_count += 1
		if c_piercing.pierce_count < 0 or c_piercing.hit_count < c_piercing.pierce_count:
			return  # bullet survives
	if ECS.world:
		ECS.world.remove_entity(bullet)

static func apply_contact_damage(attacker: Entity, target: Entity) -> void:
	if not is_instance_valid(attacker) or not is_instance_valid(target):
		return

	# 1. Fetch target components
	var target_health = target.get_component(C_Health) as C_Health
	var target_res = target.get_component(C_Resilience) as C_Resilience

	if not target_health:
		return

	# 2. Check Invulnerability
	if target_res and target_res.current_i_frames > 0.0:
		return # Target is currently invulnerable

	# 3. Calculate Damage
	var base_damage = 10.0
	var attacker_ai = attacker.get_component(C_AIStateMachine) as C_AIStateMachine
	if attacker_ai:
		base_damage = attacker_ai.contact_damage
	
	var armor = target_res.armor if target_res else 0.0
	var final_damage = max(1.0, base_damage - armor)

	# 4. Calculate contact knockback
	var displacement = Vector2.ZERO
	var knockback_dir = (target.global_position - attacker.global_position).normalized()
	if knockback_dir == Vector2.ZERO:
		knockback_dir = Vector2.RIGHT

	var m_t = 10.0
	if target.has_component(C_MASS):
		m_t = target.get_component(C_MASS).mass
	elif target_res:
		m_t = target_res.weight * 10.0

	var kb_force = 150.0
	var attacker_pay = attacker.get_component(C_Payload) as C_Payload
	if attacker_pay:
		kb_force = attacker_pay.knockback_force

	displacement = knockback_dir * (kb_force / m_t)

	# 5. Append C_PendingDamage component to target
	var pending = C_PENDING_DAMAGE.new(final_damage, displacement)
	target.add_component(pending)

	# Propagate damage type if attacker has one
	if attacker.has_component(C_DAMAGE_TYPE):
		var dtype = attacker.get_component(C_DAMAGE_TYPE)
		target.add_component(C_DAMAGE_TYPE.new(dtype.damage_type))

	# 6. Print debug log
	print("[Combat] Contact damage queued! %s hit %s! Damage: %.1f (Armor: %.1f)" % [
		attacker.name, target.name, final_damage, armor
	])

	# 7. Trigger Invulnerability Frames
	if target_res and target_res.invulnerability_duration > 0.0:
		target_res.current_i_frames = target_res.invulnerability_duration


static func _spawn_split_bullets(
	original_bullet: Entity,
	target: Entity,
	split_effect: BulletSplitEffect
) -> void:
	var orig_vel = original_bullet.get_component(C_Velocity) as C_Velocity
	if not orig_vel:
		return

	var orig_payload = original_bullet.get_component(C_Payload) as C_Payload
	var orig_traj = original_bullet.get_component(C_Trajectory) as C_Trajectory
	var orig_vol = original_bullet.get_component(C_Volatility) as C_Volatility

	# Spawn two split bullets angled at -split_angle_deg and +split_angle_deg
	var angle_val = split_effect.split_angle_deg
	var angles = [-angle_val, angle_val]
	for angle in angles:
		var new_dir = orig_vel.direction.rotated(deg_to_rad(angle))

		var split = load("res://entities/projectiles/e_bullet.tscn").instantiate() as Entity
		split.shooter = original_bullet.shooter
		split.position = original_bullet.position

		# Split bullets do configurable percentage of damage and knockback force
		var dmg_mult = split_effect.damage_multiplier
		var dmg = orig_payload.damage * dmg_mult if orig_payload else 5.0
		var kb = orig_payload.knockback_force * dmg_mult if orig_payload else 75.0
		var aoe = orig_payload.area_of_effect if orig_payload else 0.0

		split.add_component(C_Velocity.new(new_dir))
		split.add_component(C_Payload.new(dmg, kb, aoe))

		var max_range = orig_traj.max_range if orig_traj else 500.0
		var homing = orig_traj.homing_strength if orig_traj else 0.0
		split.add_component(C_Trajectory.new(max_range, 0.0, homing))

		if orig_vol:
			var vol = C_Volatility.new()
			vol.is_critical = orig_vol.is_critical
			split.add_component(vol)

			if vol.is_critical:
				var sprite = split.get_node_or_null("Sprite2D") as Sprite2D
				if sprite:
					sprite.self_modulate = Color.RED

		# Add split bullet to the scene tree and ECS world
		var main_node = target.get_parent()
		if main_node:
			main_node.add_child.call_deferred(split)
			ECS.world.add_entity.call_deferred(split)

static func _spawn_hazard_on_impact(bullet: Entity, mode: String) -> void:
	if not is_instance_valid(bullet) or not "global_position" in bullet:
		return

	var hazard: Entity = null
	if mode == "TECH":
		hazard = TECH_HAZARD_PREFAB.instantiate() as Entity
	elif mode == "MAGIC":
		hazard = CORRUPTION_HAZARD_PREFAB.instantiate() as Entity
	else:
		return

	if hazard:
		hazard.global_position = bullet.global_position
		if ECS.world:
			ECS.world.add_entity(hazard)
		print("[Hazard] Spawned %s hazard at %v" % [mode, bullet.global_position])

static func _spawn_impact_effect(bullet: Entity, mode: String) -> void:
	if not is_instance_valid(bullet):
		return

	var sprite = bullet.get_node_or_null("Sprite2D") as Sprite2D
	if sprite and NodeFX:
		if mode == "TECH":
			NodeFX.pop(sprite, 0.2, false)
		else:  # MAGIC
			NodeFX.pulse(sprite, 0.15, 1)

class_name CombatSystem
extends System

const C_DAMAGE_TYPE = preload("res://components/combat/c_damage_type.gd")
const C_PIERCING = preload("res://components/projectile/c_piercing.gd")
const C_ATTACK_MODE = preload("res://components/player/c_attack_mode.gd")
const C_FIRE_MODE = preload("res://components/player/c_fire_mode.gd")
const TECH_HAZARD_PREFAB = preload("res://entities/hazards/e_tech_hazard.tscn")
const CORRUPTION_HAZARD_PREFAB = preload("res://entities/hazards/e_corruption_hazard.tscn")

static func apply_hit(bullet: Entity, target: Entity) -> void:
	if not is_instance_valid(bullet) or not is_instance_valid(target):
		return

	if not target.has_method("take_damage"):
		return

	# 1. Fetch target components
	var target_res = target.get_component(C_Resilience) as C_Resilience

	# 2. Fetch bullet components
	var bullet_payload = bullet.get_component(C_Payload) as C_Payload
	var bullet_vel = bullet.get_component(C_Velocity) as C_Velocity
	var bullet_vol = bullet.get_component(C_Volatility) as C_Volatility

	var base_damage := 0.0
	var knockback_dir := Vector2.ZERO

	if bullet_payload:
		base_damage = bullet_payload.damage
		# Calculate knockback using bullet velocity and target weight
		if bullet_vel:
			var c_loco = bullet.get_component(C_Locomotion) as C_Locomotion
			var bullet_speed = c_loco.base_speed if c_loco else 400.0
			var v_p = bullet_vel.direction * bullet_speed
			if v_p == Vector2.ZERO:
				v_p = ((target.get("global_position") as Vector2) - (bullet.get("global_position") as Vector2)).normalized() * bullet_speed
			var m_t = target_res.weight * 10.0 if target_res else 10.0
			knockback_dir = v_p * 1.7 * (8.0 / m_t)
	elif "damage" in bullet:
		# Phase 4+ bullet: uses @export vars
		base_damage = bullet.get("damage")
		var dir = bullet.get("direction") if "direction" in bullet else Vector2.RIGHT
		var kb_force = bullet.get("knockback_force") if "knockback_force" in bullet else 150.0
		knockback_dir = dir * kb_force

	if base_damage <= 0.0:
		return

	# 3. Armor mitigation (applied before passing to take_damage)
	var armor = target_res.armor if target_res else 0.0
	var final_damage = max(1.0, base_damage - armor)

	# 4. Check explosive damage type
	var is_explosive = false
	if bullet.has_component(C_DAMAGE_TYPE):
		var dtype = bullet.get_component(C_DAMAGE_TYPE)
		is_explosive = dtype.damage_type == 1

	# 5. Debug log
	var is_crit = bullet_vol.is_critical if bullet_vol else false
	print("[Combat] Hit %s! Damage: %.1f%s (Armor: %.1f)" % [
		target.name, final_damage, " [CRITICAL!]" if is_crit else "", armor
	])

	# 6. Trigger bullet split passive if applicable
	if "shooter" in bullet and is_instance_valid(bullet.shooter):
		var c_inv = bullet.shooter.get_component(C_RelicInventory) as C_RelicInventory
		if c_inv:
			var split_effects = c_inv.get_effects_of_type(BulletSplitEffect)
			for split_effect in split_effects:
				var luck_val = 1.0
				var c_luck = bullet.shooter.get_component(C_Luck) as C_Luck
				if c_luck:
					luck_val = c_luck.value
				var split_chance = clamp(split_effect.base_chance * luck_val, 0.0, 1.0)
				if randf() < split_chance:
					print("[Combat] Plasma Splitter split passive triggered! (Chance: %.2f)" % split_chance)
					_spawn_split_bullets(bullet, target, split_effect)

	# 7. Spawn environment hazard on impact
	var fire_mode := ""
	if bullet.has_component(C_FIRE_MODE):
		fire_mode = bullet.get_component(C_FIRE_MODE).mode
	elif "fire_mode_tag" in bullet:
		fire_mode = bullet.get("fire_mode_tag")
	if fire_mode != "":
		_spawn_hazard_on_impact(bullet, fire_mode)
		_spawn_impact_effect(bullet, fire_mode)

	# 8. Piercing check
	var c_piercing = bullet.get_component(C_PIERCING) as C_Piercing
	if c_piercing:
		c_piercing.hit_count += 1
		var bullet_survives = c_piercing.pierce_count < 0 or c_piercing.hit_count < c_piercing.pierce_count
		target.call("take_damage", final_damage, knockback_dir, is_explosive)
		if bullet_survives:
			return
	elif "pierce_count" in bullet:
		var pierce_count = bullet.get("pierce_count") as int
		var hit_count = (bullet.get("_hit_count") as int) + 1
		bullet.set("_hit_count", hit_count)
		var bullet_survives = pierce_count < 0 or hit_count < pierce_count
		target.call("take_damage", final_damage, knockback_dir, is_explosive)
		if bullet_survives:
			return
	else:
		target.call("take_damage", final_damage, knockback_dir, is_explosive)

	if ECS.world:
		ECS.world.remove_entity(bullet)
	if is_instance_valid(bullet):
		bullet.queue_free()

static func apply_contact_damage(attacker: Entity, target: Entity) -> void:
	if not is_instance_valid(attacker) or not is_instance_valid(target):
		return

	if not target.has_method("take_damage"):
		return

	var target_res = target.get_component(C_Resilience) as C_Resilience

	var base_damage = 10.0
	var attacker_ai = attacker.get_component(C_AIStateMachine) as C_AIStateMachine
	if attacker_ai:
		base_damage = attacker_ai.contact_damage

	var armor = target_res.armor if target_res else 0.0
	var final_damage = max(1.0, base_damage - armor)

	var knockback_dir = (target.global_position - attacker.global_position).normalized()
	if knockback_dir == Vector2.ZERO:
		knockback_dir = Vector2.RIGHT

	var m_t = target_res.weight * 10.0 if target_res else 10.0
	var kb_force = 150.0
	var attacker_pay = attacker.get_component(C_Payload) as C_Payload
	if attacker_pay:
		kb_force = attacker_pay.knockback_force
	var displacement = knockback_dir * (kb_force / m_t)

	print("[Combat] Contact damage queued! %s hit %s! Damage: %.1f (Armor: %.1f)" % [
		attacker.name, target.name, final_damage, armor
	])

	target.call("take_damage", final_damage, displacement)

static func _spawn_split_bullets(
	original_bullet: Entity,
	target: Entity,
	split_effect: BulletSplitEffect
) -> void:
	var orig_vel = original_bullet.get_component(C_Velocity) as C_Velocity

	var base_dir := Vector2.RIGHT
	if orig_vel:
		base_dir = orig_vel.direction
	elif "direction" in original_bullet:
		base_dir = original_bullet.get("direction")

	var orig_payload = original_bullet.get_component(C_Payload) as C_Payload
	var orig_traj = original_bullet.get_component(C_Trajectory) as C_Trajectory
	var orig_vol = original_bullet.get_component(C_Volatility) as C_Volatility

	var angle_val = split_effect.split_angle_deg
	var angles = [-angle_val, angle_val]
	for angle in angles:
		var new_dir = base_dir.rotated(deg_to_rad(angle))
		var split = load("res://entities/projectiles/e_bullet.tscn").instantiate() as Entity
		split.shooter = original_bullet.shooter
		split.set("position", original_bullet.get("position"))

		var dmg_mult = split_effect.damage_multiplier
		var dmg = (orig_payload.damage if orig_payload else 5.0) * dmg_mult
		var kb = (orig_payload.knockback_force if orig_payload else 75.0) * dmg_mult

		if "direction" in split:
			# Phase 4+ bullet
			split.set("direction", new_dir)
			split.set("damage", dmg)
			split.set("knockback_force", kb)
			split.set("max_range", orig_traj.max_range if orig_traj else 500.0)
			split.set("homing_strength", orig_traj.homing_strength if orig_traj else 0.0)
			if orig_vol:
				split.set("is_critical", orig_vol.is_critical)
		else:
			# Phase 1-3 bullet (still uses components)
			split.add_component(C_Velocity.new(new_dir))
			split.add_component(C_Payload.new(dmg, kb, orig_payload.area_of_effect if orig_payload else 0.0))
			split.add_component(C_Trajectory.new(
				orig_traj.max_range if orig_traj else 500.0,
				0.0,
				orig_traj.homing_strength if orig_traj else 0.0
			))
			if orig_vol:
				var vol = C_Volatility.new()
				vol.is_critical = orig_vol.is_critical
				split.add_component(vol)

		if orig_vol and orig_vol.is_critical:
			var sprite = split.get_node_or_null("Sprite2D") as Sprite2D
			if sprite:
				sprite.self_modulate = Color.RED

		var main_node = target.get_parent()
		if main_node:
			main_node.add_child.call_deferred(split)
			ECS.world.add_entity.call_deferred(split)

static func _spawn_hazard_on_impact(bullet: Entity, mode: String) -> void:
	if not is_instance_valid(bullet) or not "global_position" in bullet:
		return

	var hazard: Node2D = null
	if mode == "TECH":
		hazard = TECH_HAZARD_PREFAB.instantiate()
	elif mode == "MAGIC":
		hazard = CORRUPTION_HAZARD_PREFAB.instantiate()
	else:
		return

	if hazard:
		var bullet_pos = bullet.get("global_position") as Vector2
		hazard.global_position = bullet_pos
		var parent = bullet.get_parent()
		if parent:
			parent.add_child(hazard)
		print("[Hazard] Spawned %s hazard at %v" % [mode, bullet_pos])

static func _spawn_impact_effect(bullet: Entity, mode: String) -> void:
	if not is_instance_valid(bullet):
		return

	var sprite = bullet.get_node_or_null("Sprite2D") as Sprite2D
	if sprite and NodeFX:
		if mode == "TECH":
			NodeFX.pop(sprite, 0.2, false)
		else:
			NodeFX.pulse(sprite, 0.15, 1)

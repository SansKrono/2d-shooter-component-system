class_name CombatSystem
extends System

static func apply_hit(bullet: Entity, target: Entity) -> void:
	if not is_instance_valid(bullet) or not is_instance_valid(target):
		return

	# 1. Fetch target components
	var target_health = target.get_component(C_Health) as C_Health
	var target_res = target.get_component(C_Resilience) as C_Resilience
	var target_vel = target.get_component(C_Velocity) as C_Velocity

	if not target_health:
		return

	# 2. Check Invulnerability
	if target_res and target_res.current_i_frames > 0.0:
		return # Target is currently invulnerable

	# 3. Fetch bullet components
	var bullet_payload = bullet.get_component(C_Payload) as C_Payload
	var bullet_vel = bullet.get_component(C_Velocity) as C_Velocity
	var bullet_vol = bullet.get_component(C_Volatility) as C_Volatility

	if not bullet_payload:
		return

	# 4. Damage calculations (armor mitigation)
	var base_damage = bullet_payload.damage
	var armor = target_res.armor if target_res else 0.0
	var final_damage = max(1.0, base_damage - armor)

	# 5. Apply health modification
	target_health.current = max(0.0, target_health.current - final_damage)

	# 6. Apply knockback
	if bullet_vel and target_vel:
		var knockback_dir = bullet_vel.direction.normalized()
		if knockback_dir == Vector2.ZERO:
			# Fallback: direction from bullet to target
			knockback_dir = (target.global_position - bullet.global_position).normalized()
		
		var weight = target_res.weight if target_res else 1.0
		var kb_force = bullet_payload.knockback_force
		target_vel.knockback += knockback_dir * (kb_force / weight)

	# 7. Print debug log
	var is_crit = bullet_vol.is_critical if bullet_vol else false
	var crit_label = " [CRITICAL!]" if is_crit else ""
	print("[Combat] Hit %s! Damage: %.1f%s (Armor: %.1f) | Health: %.1f/%.1f" % [
		target.name, final_damage, crit_label, armor, target_health.current, target_health.maximum
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
					print("[Combat] Ghost Pepper split passive triggered! (Chance: %.2f)" % split_chance)
					_spawn_split_bullets(bullet, target, split_effect)

	# 10. Destroy Bullet via ECS World
	if ECS.world:
		ECS.world.remove_entity(bullet)

static func apply_contact_damage(attacker: Entity, target: Entity) -> void:
	if not is_instance_valid(attacker) or not is_instance_valid(target):
		return

	# 1. Fetch target components
	var target_health = target.get_component(C_Health) as C_Health
	var target_res = target.get_component(C_Resilience) as C_Resilience
	var target_vel = target.get_component(C_Velocity) as C_Velocity

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

	# 4. Apply health modification
	target_health.current = max(0.0, target_health.current - final_damage)

	# 5. Apply knockback
	if target_vel:
		var knockback_dir = (target.global_position - attacker.global_position).normalized()
		if knockback_dir == Vector2.ZERO:
			knockback_dir = Vector2.RIGHT

		var weight = target_res.weight if target_res else 1.0
		var kb_force = 150.0
		var attacker_pay = attacker.get_component(C_Payload) as C_Payload
		if attacker_pay:
			kb_force = attacker_pay.knockback_force

		target_vel.knockback += knockback_dir * (kb_force / weight)

	# 6. Print debug log
	print("[Combat] Contact damage! %s hit %s! Damage: %.1f (Armor: %.1f) | Health: %.1f/%.1f" % [
		attacker.name, target.name, final_damage, armor, target_health.current, target_health.maximum
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

		split.add_component(C_Velocity.new(new_dir, orig_vel.speed))
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

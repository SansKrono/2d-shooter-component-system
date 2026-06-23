class_name DamageResolutionSystem
extends System

const C_HEALTH = preload("res://components/combat/c_health.gd")
const C_PENDING_DAMAGE = preload("res://components/combat/c_pending_damage.gd")
const C_DAMAGE_TYPE = preload("res://components/combat/c_damage_type.gd")
const C_BOSS_ARMOR = preload("res://components/combat/c_boss_armor.gd")
const C_DEAD = preload("res://components/combat/c_dead.gd")

func query() -> QueryBuilder:
	return q.with_all([C_HEALTH, C_PENDING_DAMAGE])

func process(entities: Array[Entity], _components: Array, _delta: float) -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	
	for entity in entities:
		var health = entity.get_component(C_HEALTH) as C_Health
		var pending = entity.get_component(C_PENDING_DAMAGE)
		if not health or not pending:
			continue
			
		var final_damage = pending.amount
		
		# Check if explosive damage type bypasses boss armor
		var is_explosive = false
		if entity.has_component(C_DAMAGE_TYPE):
			var dtype = entity.get_component(C_DAMAGE_TYPE)
			if dtype.damage_type == 1: # C_DamageType.Type.EXPLOSIVE is 1
				is_explosive = true
		
		if entity.has_component(C_BOSS_ARMOR) and not is_explosive:
			var armor = entity.get_component(C_BOSS_ARMOR)
			final_damage = _calculate_scaled_damage(final_damage, armor, current_time)
			armor.damage_history.append({"time": current_time, "amount": final_damage})
			
		_apply_damage_to_health(health, final_damage)
		
		if entity.has_component(C_BOSS_ARMOR) and not is_explosive:
			_cleanup_stale_damage_history(entity.get_component(C_BOSS_ARMOR), current_time)
			
		# Log the combat hit for debug purposes
		var armor_label = " (Bypassed)" if is_explosive else ""
		print("[Combat/ECS] Resolved Damage to %s! Amount: %.1f%s | Health: %.1f/%.1f" % [
			entity.name, final_damage, armor_label, health.current, health.maximum
		])
		
		# Clear the damage instance via command buffer
		cmd.remove_component(entity, C_PENDING_DAMAGE)
		if entity.has_component(C_DAMAGE_TYPE):
			cmd.remove_component(entity, C_DAMAGE_TYPE)
			
		if _is_entity_dead(health):
			cmd.add_component(entity, C_DEAD.new())

func _calculate_scaled_damage(incoming_dmg: float, armor, current_time: float) -> float:
	var damage_last_4s: float = 0.0
	for record in armor.damage_history:
		if current_time - record.time <= 4.0:
			damage_last_4s += record.amount
			
	var dps_soft_cap = armor.base_hp / max(1.0, armor.armor_value)
	
	# Preemptive scaling for massive single instances
	if incoming_dmg > (dps_soft_cap * 4.0):
		incoming_dmg *= 0.25
		
	var damage_ratio = damage_last_4s / dps_soft_cap
	var multiplier = clamp(1.0 - (damage_ratio * 0.1), 0.09, 1.0)
	
	return incoming_dmg * multiplier

func _cleanup_stale_damage_history(armor, current_time: float) -> void:
	armor.damage_history = armor.damage_history.filter(
		func(record): return current_time - record.time <= 4.0
	)

func _apply_damage_to_health(health: C_Health, amount: float) -> void:
	health.current = max(0.0, health.current - amount)

func _is_entity_dead(health: C_Health) -> bool:
	return health.current <= 0.0

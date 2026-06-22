class_name EnvironmentEffectSystem
extends System

const C_ENVIRONMENT_EFFECT = preload("res://components/character/c_environment_effect.gd")
const C_HEALTH = preload("res://components/character/c_health.gd")

func query() -> QueryBuilder:
	return q.with_all([C_ENVIRONMENT_EFFECT])

func process(entities: Array[Entity], _components: Array, delta: float) -> void:
	for entity in entities:
		var c_env = entity.get_component(C_ENVIRONMENT_EFFECT)
		if not c_env:
			continue

		# Tick duration
		c_env.remaining_time -= delta
		if c_env.remaining_time <= 0.0:
			ECS.world.remove_entity(entity)
			continue

		# Tick damage counter
		c_env.time_since_last_tick += delta
		if c_env.time_since_last_tick < c_env.tick_interval:
			continue

		c_env.time_since_last_tick -= c_env.tick_interval

		# Find entities in radius and apply damage
		var hazard_pos = entity.global_position if "global_position" in entity else Vector2.ZERO
		var nearby = ECS.world.query.with_all([C_HEALTH]).execute()

		for target in nearby:
			if target == entity or not "global_position" in target:
				continue

			var dist = hazard_pos.distance_to(target.global_position)
			if dist <= c_env.radius:
				var c_health = target.get_component(C_HEALTH)
				if c_health:
					c_health.current = max(0.0, c_health.current - c_env.damage_per_tick)
					print("[Hazard] %s took %.1f damage from %s" % [
						target.name, c_env.damage_per_tick, c_env.effect_type
					])

					# Apply corruption weakness if magic hazard
					if c_env.effect_type == C_ENVIRONMENT_EFFECT.EFFECT_CORRUPTION:
						_apply_corruption_weakness(target)

func _apply_corruption_weakness(target: Entity) -> void:
	var c_resilience = target.get_component(C_Resilience)
	if c_resilience:
		c_resilience.current_armor_multiplier = 0.5

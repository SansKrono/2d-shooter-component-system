class_name StatRecalculationSystem
extends System

const C_TEAR_STATS = preload("res://components/projectile/c_tear_stats.gd")
const C_RELIC_INVENTORY = preload("res://components/economy/c_relic_inventory.gd")
const C_STAT_MODIFIER = preload("res://components/synergy/c_stat_modifier.gd")
const C_SYNERGY_STATE = preload("res://components/synergy/c_synergy_state.gd")

func query() -> QueryBuilder:
	return q.with_all([C_TEAR_STATS, C_RELIC_INVENTORY])

func process(entities: Array[Entity], _components: Array, _delta: float) -> void:
	for entity in entities:
		var stats = entity.get_component(C_TEAR_STATS)
		if not stats:
			continue
			
		# Baseline stats
		var base_damage = 3.5
		var base_delay = 10
		
		# Accumulate modifiers
		var dmg_add = 0.0
		var dmg_mult = 1.0
		var delay_add = 0
		var delay_mult = 1.0
		
		var has_polyphemus = false
		var has_soy_milk = false
		
		var dummy_modifier_relation = C_STAT_MODIFIER.new()
		var rel_query = Relationship.new(dummy_modifier_relation, null)
		var relationships = entity.get_relationships(rel_query)
		for rel in relationships:
			var mod = rel.relation
			if not mod:
				continue
			dmg_add += mod.damage_add
			dmg_mult *= mod.damage_mult
			delay_add += mod.tear_delay_add
			delay_mult *= mod.tear_delay_mult
			
			if mod.is_polyphemus:
				has_polyphemus = true
			if mod.is_soy_milk:
				has_soy_milk = true
				
		# Apply synergy effects
		var c_synergy_state = entity.get_component(C_SYNERGY_STATE) as C_SYNERGY_STATE
		if c_synergy_state:
			for synergy in c_synergy_state.get_active_synergies():
				for effect in synergy.synergy_effects:
					if effect:
						dmg_mult *= effect.get_stat_multiplier("damage")

		# 1. Additive first
		var final_damage = base_damage + dmg_add
		var final_delay = base_delay + delay_add

		# 2. Multiplicative next
		final_damage *= dmg_mult
		final_delay = int(float(final_delay) * delay_mult)

		# 3. Special overrides/formulas
		if has_polyphemus:
			final_delay = int(float(final_delay) * 2.1) + 3
			final_damage *= 2.0
			
		if has_soy_milk:
			final_delay = int(float(final_delay) * 0.25) - 2
			final_damage *= 0.2
			
		# Enforce natural minimum delay of 5 unless soy milk is active
		if not has_soy_milk:
			final_delay = max(5, final_delay)
		else:
			final_delay = max(1, final_delay)
			
		# Assign back to stats
		stats.damage = final_damage
		stats.tear_delay = final_delay

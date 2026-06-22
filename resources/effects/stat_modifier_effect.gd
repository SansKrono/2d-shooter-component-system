class_name StatModifierEffect
extends "res://resources/effects/relic_effect.gd"

@export var stat_name: String = ""
@export var value: float = 0.0

const C_LOCOMOTION = preload("res://components/character/c_locomotion.gd")

func apply(entity: Entity) -> void:
	match stat_name:
		"damage":
			var c = entity.get_component(C_Payload) as C_Payload
			if c:
				c.damage += value
		"speed":
			var c = entity.get_component(C_LOCOMOTION) as C_Locomotion
			if c:
				c.base_speed += value
		"fire_rate":
			var c = entity.get_component(C_Shooter) as C_Shooter
			if c:
				c.fire_rate = max(0.05, c.fire_rate - value)
		"crit_chance":
			var c = entity.get_component(C_Volatility) as C_Volatility
			if c:
				c.crit_chance += value
		"luck":
			var c = entity.get_component(C_Luck) as C_Luck
			if c:
				c.value += value
		"armor":
			var c = entity.get_component(C_Resilience) as C_Resilience
			if c:
				c.armor += value
		"homing_strength":
			var c = entity.get_component(C_Trajectory) as C_Trajectory
			if c:
				c.homing_strength += value
		"max_health":
			var c = entity.get_component(C_Health) as C_Health
			if c:
				c.maximum += value
				c.current += value
		"bullet_size":
			var c = entity.get_component(C_Shooter) as C_Shooter
			if c:
				c.bullet_size += value

class_name DeathResolutionSystem
extends System

const C_DEAD = preload("res://components/combat/c_dead.gd")
const C_ENEMY = preload("res://components/behaviour/c_enemy.gd")
const C_SPAWN_REWARD = preload("res://components/world/c_spawn_reward.gd")
const C_TRANSFORM = preload("res://components/movement/c_transform.gd")

func query() -> QueryBuilder:
	return q.with_all([C_DEAD])

func process(entities: Array[Entity], _components: Array, _delta: float) -> void:
	var current_time = Time.get_ticks_msec() / 1000.0

	for entity in entities:
		var dead = entity.get_component(C_DEAD)
		if not dead:
			continue

		if not dead.is_processed:
			dead.is_processed = true
			dead.death_timestamp = current_time

			# Trigger visual effects on Sprite2D or AnimatedSprite2D or entity itself
			var fx_target = entity.get_node_or_null("Sprite2D")
			if not fx_target:
				fx_target = entity.get_node_or_null("AnimatedSprite2D")
			if not fx_target and (entity as Node) is Node2D:
				fx_target = entity

			if fx_target:
				NodeFX.pop(fx_target, 0.3, true)
				NodeFX.fade(fx_target, 0.3, false, true)

			# If it's an enemy, queue a coin reward spawn at its death location
			if entity.has_component(C_ENEMY):
				var trans = entity.get_component(C_TRANSFORM)
				var spawn_pos = trans.position if trans else Vector2.ZERO
				cmd.add_component(entity, C_SPAWN_REWARD.new("coin", spawn_pos))
				print("[DeathResolutionSystem] Enemy %s died, queued coin at %s" % [
					entity.name, str(spawn_pos)
				])
			else:
				print("[DeathResolutionSystem] Entity %s died" % entity.name)

		# Defer actual entity deletion to allow death FX to play
		if current_time - dead.death_timestamp >= 0.3:
			print("[DeathResolutionSystem] Cleaning up dead entity: ", entity.name)
			cmd.remove_entity(entity)

class_name CollectibleSystem
extends System

const C_COLLECTIBLE_SCRIPT = preload("res://components/economy/c_collectible.gd")
const C_AI_STATE_MACHINE_SCRIPT = preload("res://components/behaviour/c_ai_state_machine.gd")

func query() -> QueryBuilder:
	return q.with_all([C_COLLECTIBLE_SCRIPT])

func process(entities: Array[Entity], _components: Array, delta: float) -> void:
	# 1. Locate the player entity via C_Input
	var players = q.with_all([C_Input]).with_none([C_AI_STATE_MACHINE_SCRIPT]).execute()
	if players.is_empty():
		return

	var player = players[0]
	var player_pos = player.global_position if "global_position" in player else Vector2.ZERO

	# 2. Process all collectibles
	for entity in entities:
		var c_coll = entity.get_component(C_COLLECTIBLE_SCRIPT) as C_COLLECTIBLE_SCRIPT
		if not c_coll or c_coll.collected:
			continue

		var entity_pos = entity.global_position if "global_position" in entity else Vector2.ZERO
		var dist = entity_pos.distance_to(player_pos)

		# Check collection proximity first
		if dist <= c_coll.collection_range:
			c_coll.collected = true
			print("[CollectibleSystem] Player collected: %s!" % entity.name)
			if c_coll.on_collected.is_valid():
				c_coll.on_collected.call(player)
			else:
				print("[CollectibleSystem] Collection callback is NOT valid.")
			continue

		# Magnet functionality
		if dist <= c_coll.magnet_range:
			if "global_position" in entity:
				# Move entity towards player
				var dir = (player_pos - entity_pos).normalized()
				entity.global_position += dir * c_coll.magnet_speed * delta



class_name AISystem
extends System

func query() -> QueryBuilder:
	return q.with_all([C_AIStateMachine])

func process(entities: Array[Entity], _components: Array, _delta: float) -> void:
	# 1. Locate the player entity
	var players = q.with_all([C_Input]).execute()
	var player: Entity = null
	for p in players:
		if p is Player:
			player = p
			break

	if not player or not is_instance_valid(player):
		for entity in entities:
			var c_ai = entity.get_component(C_AIStateMachine) as C_AIStateMachine
			if c_ai:
				c_ai.current_state = C_AIStateMachine.State.IDLE
			var c_input = entity.get_component(C_Input) as C_Input
			if c_input:
				c_input.movement_vector = Vector2.ZERO
				c_input.shoot_vector = Vector2.ZERO
		return

	var player_pos = player.global_position if "global_position" in player else Vector2.ZERO

	for entity in entities:
		var c_ai = entity.get_component(C_AIStateMachine) as C_AIStateMachine
		if not c_ai:
			continue

		# Skip offscreen entities (check script var directly since C_OFFSCREEN removed later)
		if entity.get("_is_offscreen"):
			continue

		var entity_pos = entity.global_position if "global_position" in entity else Vector2.ZERO
		var dist = entity_pos.distance_to(player_pos)
		var c_input = entity.get_component(C_Input) as C_Input
		var c_shooter = entity.get_component(C_Shooter) as C_Shooter

		# 2. State transitions
		var old_state = c_ai.current_state
		if dist <= c_ai.shoot_range and c_shooter:
			c_ai.current_state = C_AIStateMachine.State.SHOOT
		elif dist <= c_ai.chase_range:
			c_ai.current_state = C_AIStateMachine.State.CHASE
		else:
			c_ai.current_state = C_AIStateMachine.State.IDLE

		if c_ai.current_state != old_state:
			var state_name = C_AIStateMachine.State.keys()[c_ai.current_state]
			print("[AI] %s transitioned state: %s -> %s (Dist: %.1f)" % [entity.name, C_AIStateMachine.State.keys()[old_state], state_name, dist])

		# 3. Handle state behaviors
		match c_ai.current_state:
			C_AIStateMachine.State.IDLE:
				if c_input:
					c_input.movement_vector = Vector2.ZERO
					c_input.shoot_vector = Vector2.ZERO

			C_AIStateMachine.State.CHASE:
				var dir = (player_pos - entity_pos).normalized()
				if c_input:
					c_input.movement_vector = dir
					c_input.shoot_vector = Vector2.ZERO

			C_AIStateMachine.State.SHOOT:
				var dir = (player_pos - entity_pos).normalized()
				if c_input:
					c_input.movement_vector = Vector2.ZERO
					c_input.shoot_vector = dir

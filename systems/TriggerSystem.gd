class_name TriggerSystem
extends System

const C_TRIGGER_SCRIPT = preload("res://components/character/c_trigger.gd")

func query() -> QueryBuilder:
	return q.with_all([C_TRIGGER_SCRIPT])

func process(entities: Array[Entity], _components: Array, _delta: float) -> void:
	# 1. Locate the player entity via C_Input
	var players = q.with_all([C_Input]).execute()
	if players.is_empty():
		return

	var player = players[0]
	var player_pos = player.global_position if "global_position" in player else Vector2.ZERO

	# 2. Update and check all triggers
	for trigger in entities:
		var c_trig = trigger.get_component(C_TRIGGER_SCRIPT) as C_TRIGGER_SCRIPT
		if not c_trig:
			continue

		# Proximity check
		var trigger_pos = trigger.global_position if "global_position" in trigger else Vector2.ZERO
		var dist = trigger_pos.distance_to(player_pos)
		var in_range = dist <= c_trig.trigger_range

		if in_range:
			if not c_trig.triggered:
				c_trig.triggered = true
				print("[TriggerSystem] Player entered trigger range of %s!" % trigger.name)

				# Call trigger callback
				if c_trig.trigger_action.is_valid():
					c_trig.trigger_action.call()
				else:
					print("[TriggerSystem] Trigger action callback is NOT valid.")

				if c_trig.one_shot:
					cmd.remove_entity(trigger)
		else:
			# Reset triggered state if player walked out of range and not one-shot
			if c_trig.triggered and not c_trig.one_shot:
				c_trig.triggered = false

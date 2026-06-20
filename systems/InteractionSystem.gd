class_name InteractionSystem
extends System

var last_reset_frame: int = -1

func query() -> QueryBuilder:
	return q.with_all([C_Input])

func process(entities: Array[Entity], _components: Array, _delta: float) -> void:
	# Query for all interactables in the world
	var interactables = q.with_all([C_Interactable]).execute()
	if interactables.is_empty():
		return

	# Reset triggered state from previous frame (only once per frame)
	var current_frame = Engine.get_process_frames()
	if current_frame != last_reset_frame:
		last_reset_frame = current_frame
		for obj in interactables:
			if is_instance_valid(obj):
				var c_inter = obj.get_component(C_Interactable) as C_Interactable
				if c_inter:
					c_inter.triggered = false


	# Track the closest interactable in range for each actor
	var closest_per_actor = {}
	for actor in entities:
		var c_input = actor.get_component(C_Input) as C_Input
		if not c_input:
			continue

		var actor_pos = actor.global_position if "global_position" in actor else Vector2.ZERO
		var closest: Entity = null
		var min_dist := INF

		for obj in interactables:
			if not is_instance_valid(obj):
				continue
			var c_inter = obj.get_component(C_Interactable) as C_Interactable
			if not c_inter:
				continue

			var obj_pos = obj.global_position if "global_position" in obj else Vector2.ZERO
			var dist = actor_pos.distance_to(obj_pos)
			if dist <= c_inter.interaction_range and dist < min_dist:
				min_dist = dist
				closest = obj

		if closest:
			closest_per_actor[actor] = closest

		# Handle interaction trigger if interact_just_pressed
		if c_input.interact_just_pressed:
			c_input.interact_just_pressed = false
			if closest:
				var c_inter = closest.get_component(C_Interactable) as C_Interactable
				print("[Interaction] %s interacted with %s! ID: %d" % [
					actor.name, closest.name, c_inter.get_instance_id()
				])
				c_inter.triggered = true
				if c_inter.interaction_action.is_valid():
					c_inter.interaction_action.call()
				elif c_inter.channel < 0:
					print("[Interaction] Interaction action is NOT valid!")

	# Update the UI prompts for all interactable entities
	var active_targets = closest_per_actor.values()

	for obj in interactables:
		if not is_instance_valid(obj):
			continue
		var c_inter = obj.get_component(C_Interactable) as C_Interactable
		if not c_inter:
			continue

		var should_show = obj in active_targets
		var label = obj.get_node_or_null("InteractionPrompt") as Label

		if should_show:
			if not label:
				label = Label.new()
				label.name = "InteractionPrompt"
				label.position = Vector2(-100, -50)
				label.size = Vector2(200, 30)
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

				var settings = LabelSettings.new()
				settings.font_size = 14
				settings.font_color = Color.GOLD
				settings.outline_color = Color.BLACK
				settings.outline_size = 4
				label.label_settings = settings

				obj.add_child(label)

			label.text = c_inter.interaction_text
			label.visible = true
		else:
			if label:
				label.visible = false

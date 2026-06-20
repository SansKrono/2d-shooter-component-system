class_name SpawnerSystem
extends System

const C_SPAWNER_SCRIPT = preload("res://components/character/c_spawner.gd")

func query() -> QueryBuilder:
	return q.with_all([C_SPAWNER_SCRIPT])

func process(entities: Array[Entity], _components: Array, delta: float) -> void:
	for spawner in entities:
		var c_spawn = spawner.get_component(C_SPAWNER_SCRIPT) as C_SPAWNER_SCRIPT
		if not c_spawn or not c_spawn.scene_to_spawn:
			continue

		# Check max spawn limits
		if c_spawn.max_spawn_count >= 0 and c_spawn.current_spawn_count >= c_spawn.max_spawn_count:
			continue

		c_spawn.spawn_timer += delta
		if c_spawn.spawn_timer >= c_spawn.spawn_cooldown:
			c_spawn.spawn_timer = 0.0
			c_spawn.current_spawn_count += 1

			# Calculate spawn position
			var spawn_pos = (spawner.global_position if "global_position" in spawner else Vector2.ZERO) + c_spawn.spawn_offset

			# Instantiate the scene
			var spawned_node = c_spawn.scene_to_spawn.instantiate()
			if "position" in spawned_node:
				spawned_node.position = spawn_pos

			# Add child to scene tree
			var parent_node = spawner.get_parent()
			if parent_node:
				parent_node.add_child(spawned_node)
				print("[SpawnerSystem] Spawner %s instantiated node: %s" % [spawner.name, spawned_node.name])
				
				# Register in ECS World if it is an Entity
				if spawned_node is Entity:
					# Use command buffer or world directly (since add_entity has thread safety checks, direct is fine)
					ECS.world.add_entity(spawned_node)
					print("[SpawnerSystem] Registered spawned Entity %s in GECS World." % spawned_node.name)

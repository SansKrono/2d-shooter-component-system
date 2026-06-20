class_name ChannelSpawnerSystem
extends System

const C_CHANNEL_SPAWNER_SCRIPT = preload("res://components/character/c_channel_spawner.gd")
const C_TRIGGER_SCRIPT = preload("res://components/character/c_trigger.gd")
const C_INTERACTABLE_SCRIPT = preload("res://components/character/c_interactable.gd")

func query() -> QueryBuilder:
	return q.with_all([C_CHANNEL_SPAWNER_SCRIPT])

func process(entities: Array[Entity], _components: Array, _delta: float) -> void:


	# Find all triggered channels this frame
	var triggered_channels = {}


	# Check triggers
	var triggers = q.with_all([C_TRIGGER_SCRIPT]).execute()
	for trig in triggers:
		var c_trig = trig.get_component(C_TRIGGER_SCRIPT) as C_TRIGGER_SCRIPT
		if c_trig and c_trig.triggered and c_trig.channel >= 0:
			triggered_channels[c_trig.channel] = true

	# Check interactable buttons
	var buttons = q.with_all([C_INTERACTABLE_SCRIPT]).execute()
	for btn in buttons:
		var c_inter = btn.get_component(C_INTERACTABLE_SCRIPT) as C_INTERACTABLE_SCRIPT
		if c_inter and c_inter.triggered and c_inter.channel >= 0:
			triggered_channels[c_inter.channel] = true

	if triggered_channels.is_empty():
		return

	# Replace spawners on triggered channels
	for spawner in entities:
		var c_spawner = spawner.get_component(C_CHANNEL_SPAWNER_SCRIPT) as C_CHANNEL_SPAWNER_SCRIPT
		if c_spawner and triggered_channels.has(c_spawner.channel):
			_spawn_replacement(spawner, c_spawner)

func _spawn_replacement(spawner: Entity, c_spawner: Resource) -> void:
	var channel_val = c_spawner.channel
	if not c_spawner.scene_to_spawn:
		cmd.remove_entity(spawner)
		print("[ChannelSpawnerSystem] Removed spawner %s on channel %d (no scene configured)" % [spawner.name, channel_val])
		return

	var new_entity = c_spawner.scene_to_spawn.instantiate() as Node2D
	new_entity.position = spawner.global_position if "global_position" in spawner else Vector2.ZERO
	
	# Add child under the same parent node
	var parent = spawner.get_parent()
	if parent:
		parent.add_child(new_entity)
	else:
		print("[ChannelSpawnerSystem] Warning: Spawner has no parent!")
	
	# Add to GECS world
	cmd.add_entity(new_entity)
	cmd.remove_entity(spawner)
	print("[ChannelSpawnerSystem] Replaced %s with %s on channel %d" % [spawner.name, new_entity.name, channel_val])

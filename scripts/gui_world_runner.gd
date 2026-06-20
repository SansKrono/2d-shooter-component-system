extends Node2D

const C_TRIGGER_SCRIPT = preload("res://components/character/c_trigger.gd")
const COLLECTIBLE_SYSTEM = preload("res://systems/CollectibleSystem.gd")
const CHANNEL_SPAWNER_SYSTEM = preload("res://systems/ChannelSpawnerSystem.gd")
const COIN_SCENE = preload("res://entities/collectibles/e_coin.tscn")
const CHANNEL_SPAWNER_SCENE = preload("res://entities/environmental/e_channel_spawner.tscn")
const SEEKING_RELIC_PICKUP_SCENE = preload("res://entities/collectibles/e_seeking_relic_pickup.tscn")
const C_CHANNEL_SPAWNER = preload("res://components/character/c_channel_spawner.gd")

var sim_timer: float = 0.0
@onready var world: World = $World
var test_button_replaced: bool = false

func _ready() -> void:
	ECS.world = world

	# Hook up button interaction callback
	var button = get_node_or_null("Entities/EButton")
	if button:
		var c_inter = button.get_component(C_Interactable) as C_Interactable
		if c_inter:
			c_inter.interaction_action = _on_button_interacted
			print("[GUI Runner] Spawner button interaction registered successfully.")
	
	print("[Trace] Children of Systems node:")
	var sys_node = get_node("Systems")
	if sys_node:
		for child in sys_node.get_children():
			print("  - Node: %s, Class: %s, Script: %s, is System: %s" % [
				child.name, 
				child.get_class(), 
				child.get_script().resource_path if child.get_script() else "None",
				str(child is System)
			])
		print("[Trace] find_children('*', 'System') returned: ", sys_node.find_children("*", "System"))

	print("[Trace] GECS World Systems:")
	for s in world.systems:
		print("  - %s (%s) obj: %s" % [s.name, s.get_script().resource_path, str(s)])

var systems_printed: bool = false

func _process(delta: float) -> void:
	if ECS.world == world:
		ECS.process(delta)
	
	# Automatically test and verify headlessly
	if DisplayServer.get_name() == "headless":
		sim_timer += delta

		# 1. Teleport player onto ETrigger at 1.0s (ETrigger is at 486, 273)
		if sim_timer >= 1.0 and sim_timer < 1.1:
			var player = get_node_or_null("Entities/EPlayer")
			if player and player.global_position != Vector2(486, 273):
				player.global_position = Vector2(486, 273)
				print("[GUI Runner] Teleported player onto ETrigger (486, 273).")

		# 2. Teleport player onto SeekingAlgorithmPickup at 2.0s (relic spawned at 350, 450)
		if sim_timer >= 2.0 and sim_timer < 2.1:
			var player = get_node_or_null("Entities/EPlayer")
			if player and player.global_position != Vector2(350, 450):
				player.global_position = Vector2(350, 450)
				print("[GUI Runner] Teleported player onto spawned Relic Pickup (350, 450).")

		# 3. Simulate interact press on player at 2.3s to pick up the relic
		if sim_timer >= 2.3 and sim_timer < 2.4:
			var player = get_node_or_null("Entities/EPlayer")
			if player:
				var c_input = player.get_component(C_Input) as C_Input
				if c_input and not c_input.interact_just_pressed:
					c_input.interact_just_pressed = true
					print("[GUI Runner] Simulating interact input to pick up relic.")

		# 4. Teleport player onto EButton at 3.0s (EButton is at 204, 409)
		if sim_timer >= 3.0 and sim_timer < 3.1:
			var player = get_node_or_null("Entities/EPlayer")
			if player and player.global_position != Vector2(204, 409):
				player.global_position = Vector2(204, 409)
				print("[GUI Runner] Teleported player onto Spawner Button EButton (204, 409).")

		# 5. Simulate interact press on player at 3.3s to press the button
		if sim_timer >= 3.3 and sim_timer < 3.4:
			var player = get_node_or_null("Entities/EPlayer")
			if player:
				var c_input = player.get_component(C_Input) as C_Input
				if c_input and not c_input.interact_just_pressed:
					c_input.interact_just_pressed = true
					print("[GUI Runner] Simulating interact input to activate Spawner Button.")

		# 6. Activate Trigger99 programmatically at 4.0s to test SpawnerButton replacement on channel 99
		if sim_timer >= 4.0 and sim_timer < 4.1:
			var trigger99 = get_node_or_null("Entities/Trigger99")
			if trigger99:
				var c_trig = trigger99.get_component(C_TRIGGER_SCRIPT) as C_TRIGGER_SCRIPT
				if c_trig and not c_trig.triggered:
					c_trig.triggered = true
					print("[GUI Runner] Simulating Trigger99 activation on channel 99.")

		# Verify replacement of SpawnerButton on channel 99
		if sim_timer >= 4.2 and not test_button_replaced:
			test_button_replaced = true
			var button99 = get_node_or_null("Entities/EButton99")
			if button99:
				print("[GUI Runner] Error: SpawnerButton on channel 99 was NOT replaced!")
			else:
				print("[GUI Runner] Success: SpawnerButton 99 replaced.")

		# 7. Teleport player onto EButton2 at 4.3s (EButton2 is at 371, 546)
		if sim_timer >= 4.3 and sim_timer < 4.4:
			var player = get_node_or_null("Entities/EPlayer")
			if player and player.global_position != Vector2(371, 546):
				player.global_position = Vector2(371, 546)
				print("[GUI Runner] Teleported player onto EButton2 (371, 546).")

		# 8. Simulate interact press on player at 4.6s to press EButton2
		if sim_timer >= 4.6 and sim_timer < 4.7:
			var player = get_node_or_null("Entities/EPlayer")
			if player:
				var c_input = player.get_component(C_Input) as C_Input
				if c_input and not c_input.interact_just_pressed:
					c_input.interact_just_pressed = true
					print("[GUI Runner] Simulating interact input to activate EButton2.")

		# 9. Verify replacement of EChannelSpawner on channel 2 at 5.0s
		if sim_timer >= 5.0 and sim_timer < 5.1:
			var spawner2 = get_node_or_null("Entities/EChannelSpawner")
			if spawner2:
				print("[GUI Runner] Error: EChannelSpawner on channel 2 was NOT replaced!")
			else:
				print("[GUI Runner] Success: EChannelSpawner 2 replaced.")

		# Automatically quit after 5.5 seconds
		if sim_timer >= 5.5:
			print("[GUI Runner] Headless execution completed. Quitting.")
			get_tree().quit()



func _on_button_interacted() -> void:
	print("[GUI Runner] Spawner button callback invoked!")
	# Dynamically spawn an enemy under the Entities folder and register it in GECS World
	var enemy_scene = load("res://entities/enemies/e_enemy.tscn")
	var new_enemy = enemy_scene.instantiate() as Enemy
	new_enemy.position = Vector2(250, 150)

	var entities_node = get_node_or_null("Entities")
	if entities_node:
		entities_node.add_child(new_enemy)
		world.add_entity(new_enemy)
		print("[GUI Runner] Spawned new enemy at (250, 150) and registered in ECS World.")

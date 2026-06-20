extends Node2D

const C_TRIGGER_SCRIPT = preload("res://components/character/c_trigger.gd")

var sim_timer: float = 0.0
@onready var world: World = $World

func _ready() -> void:
	ECS.world = world

	# Hook up button interaction callback
	var button = get_node_or_null("Entities/EButton")
	if button:
		var c_inter = button.get_component(C_Interactable) as C_Interactable
		if c_inter:
			c_inter.interaction_action = _on_button_interacted
			print("[GUI Runner] Spawner button interaction registered successfully.")

	# Hook up trigger callback
	var trigger = get_node_or_null("Entities/ETrigger")
	if trigger:
		var c_trig = trigger.get_component(C_TRIGGER_SCRIPT) as C_TRIGGER_SCRIPT
		if c_trig:
			c_trig.trigger_action = _on_trigger_activated
			print("[GUI Runner] Proximity trigger callback registered successfully.")

func _process(delta: float) -> void:
	ECS.process(delta)

	# Automatically test and verify headlessly
	if DisplayServer.get_name() == "headless":
		sim_timer += delta
		
		# Teleport player onto ETrigger at 2.0s
		if sim_timer >= 2.0 and sim_timer < 2.1:
			var player = get_node_or_null("Entities/EPlayer")
			if player and player.global_position != Vector2(250, 300):
				player.global_position = Vector2(250, 300)
				print("[GUI Runner] Teleported player onto ETrigger to verify collision trigger.")
		
		# Automatically quit after 5 seconds
		if sim_timer >= 5.0:
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

func _on_trigger_activated() -> void:
	print("[GUI Runner] Proximity trigger callback invoked!")
	var relic_scene = load("res://entities/environmental/e_relic.tscn")
	var seeking_relic = load("res://resources/relics/seeking_algorithm.tres")

	var relic_pickup = relic_scene.instantiate() as Node2D
	relic_pickup.relic_resource = seeking_relic
	relic_pickup.position = Vector2(350, 450)
	relic_pickup.name = "SeekingAlgorithmPickup"

	var entities_node = get_node_or_null("Entities")
	if entities_node:
		entities_node.add_child(relic_pickup)
		world.add_entity(relic_pickup)
		print("[GUI Runner] Spawned seeking algorithm relic pickup at (350, 450).")

extends Node

const NodeFX = preload("res://addons/node_fx/node_fx.gd")
const PLAYER_SCENE = preload("res://entities/player/e_player.tscn")
const ENEMY_SCENE = preload("res://entities/enemies/e_enemy.tscn")
const BUTTON_SCENE = preload("res://entities/environmental/e_button.tscn")
const RELIC_PICKUP_SCENE = preload("res://entities/environmental/e_relic.tscn")
const AETHERIC_KERNEL = preload("res://resources/relics/aetheric_kernel.tres")
const PLASMA_SPLITTER = preload("res://resources/relics/plasma_splitter.tres")
const SEEKING_ALGORITHM = preload("res://resources/relics/seeking_algorithm.tres")
const BIOTIC_CAPACITOR = preload("res://resources/relics/biotic_capacitor.tres")
const AMPLIFICATION_ARRAY = preload("res://resources/relics/amplification_array.tres")
const SINE_WAVE_MODULATOR = preload("res://resources/relics/sine_wave_modulator.tres")
const ORBITAL_ATTRACTOR = preload("res://resources/relics/orbital_attractor.tres")
const VORTEX_ACCELERATOR = preload("res://resources/relics/vortex_accelerator.tres")
const C_BulletPath = preload("res://components/projectile/c_bullet_path.gd")
const COIN_SCENE = preload("res://entities/collectibles/e_coin.tscn")
const CHANNEL_SPAWNER_SYSTEM = preload("res://systems/ChannelSpawnerSystem.gd")

var player: Player
var enemy: Enemy
var button: SpawnerButton
var print_timer: float = 0.0
var sim_timer: float = 0.0
var button_interacted: bool = false
var relic_interacted: bool = false
var added_biotic_capacitor: bool = false
var added_amplification_array: bool = false
var added_sine_wave_modulator: bool = false
var added_orbital_attractor: bool = false
var added_vortex_accelerator: bool = false
var coin_collected_verified: bool = false

@onready var world: World = $World

func _ready():
	ECS.world = world

	# Register Systems
	world.add_system(PlayerInputSystem.new())
	world.add_system(MovementSystem.new())
	world.add_system(ShootingSystem.new())
	world.add_system(TrajectorySystem.new())
	world.add_system(InvulnerabilitySystem.new())
	world.add_system(LifetimeSystem.new())
	world.add_system(ManaSystem.new())
	world.add_system(PowerSystem.new())
	world.add_system(HealthSystem.new())
	world.add_system(InteractionSystem.new())
	world.add_system(InteractableDebugSystem.new())
	world.add_system(AISystem.new())
	world.add_system(CollectibleSystem.new())
	world.add_system(CHANNEL_SPAWNER_SYSTEM.new())

	# Spawn the player entity scene
	player = PLAYER_SCENE.instantiate() as Player
	player.position = Vector2(50, 50) # Set starting position


	add_child(player) # Add to scene tree
	world.add_entity(player) # Add to ECS world

	# Apply starting relics
	var c_inv = player.get_component(C_RelicInventory) as C_RelicInventory
	if c_inv:
		c_inv.add_relic(player, AETHERIC_KERNEL)
		c_inv.add_relic(player, PLASMA_SPLITTER)
		print("[Main] Loaded and applied relics to player! Aetheric Kernel and Plasma Splitter added.")

	# Spawn the test enemy
	enemy = ENEMY_SCENE.instantiate() as Enemy
	enemy.position = Vector2(850, 150) # Spawn to the right, slightly offset on Y to test homing
	add_child(enemy)
	world.add_entity(enemy)

	# Spawn the button
	button = BUTTON_SCENE.instantiate() as SpawnerButton
	button.position = Vector2(150, 150)
	add_child(button)
	world.add_entity(button) # This calls _initialize() and generates components

	var c_inter = button.get_component(C_Interactable) as C_Interactable
	if c_inter:
		c_inter.interaction_action = _on_button_interacted

	# Spawn a relic pickup in the world
	var relic_pickup = RELIC_PICKUP_SCENE.instantiate() as Node2D
	relic_pickup.relic_resource = SEEKING_ALGORITHM
	relic_pickup.position = Vector2(350, 450)
	relic_pickup.name = "SeekingAlgorithmPickup"
	add_child(relic_pickup)
	world.add_entity(relic_pickup)
	NodeFX.hover(relic_pickup.get_node("Sprite2D"))
	
	
	# Spawn a relic pickup in the world
	var relic_ghost_pepper = RELIC_PICKUP_SCENE.instantiate() as Node2D
	relic_ghost_pepper.relic_resource = PLASMA_SPLITTER
	relic_ghost_pepper.position = Vector2(450, 450)
	relic_ghost_pepper.name = "PlasmaSplitterPickup"
	add_child(relic_ghost_pepper)
	world.add_entity(relic_ghost_pepper)
	NodeFX.hover(relic_ghost_pepper.get_node("Sprite2D"))

	
	# Spawn a relic pickup in the world
	var relic_crickets_head = RELIC_PICKUP_SCENE.instantiate() as Node2D
	relic_crickets_head.relic_resource = AMPLIFICATION_ARRAY
	relic_crickets_head.position = Vector2(550, 450)
	relic_crickets_head.name = "AmplificationArrayPickup"
	add_child(relic_crickets_head)
	world.add_entity(relic_crickets_head)
	NodeFX.hover(relic_crickets_head.get_node("Sprite2D"))
	
	
	# Spawn a relic pickup in the world
	var relic_tiny_planet = RELIC_PICKUP_SCENE.instantiate() as Node2D
	relic_tiny_planet.relic_resource = ORBITAL_ATTRACTOR
	relic_tiny_planet.position = Vector2(650, 450)
	relic_tiny_planet.name = "OrbitalAttractorPickup"
	add_child(relic_tiny_planet)
	world.add_entity(relic_tiny_planet)
	NodeFX.hover(relic_tiny_planet.get_node("Sprite2D"))
	
	
	# Spawn a relic pickup in the world
	var relic_wiggle_worm = RELIC_PICKUP_SCENE.instantiate() as Node2D
	relic_wiggle_worm.relic_resource = SINE_WAVE_MODULATOR
	relic_wiggle_worm.position = Vector2(750, 450)
	relic_wiggle_worm.name = "SineWaveModulatorRelic"
	add_child(relic_wiggle_worm)
	world.add_entity(relic_wiggle_worm)
	NodeFX.hover(relic_wiggle_worm.get_node("Sprite2D"))

	# Spawn a coin in the world
	var test_coin = COIN_SCENE.instantiate() as Node2D
	test_coin.position = Vector2(200, 300)
	test_coin.name = "TestCoin"
	add_child(test_coin)
	world.add_entity(test_coin)

func _process(delta):
	ECS.process(delta)

	# If running headlessly (automated verification), simulate behavior timeline
	if DisplayServer.get_name() == "headless":
		sim_timer += delta
		if is_instance_valid(player):
			var input = player.get_component(C_Input) as C_Input
			if input:
				# 0.0s - 1.0s: Shoot right to kill initial enemy
				if sim_timer < 1.0:
					input.shoot_vector = Vector2.RIGHT
				else:
					input.shoot_vector = Vector2.ZERO

				# Apply Biotic Capacitor at 1.2s
				if sim_timer >= 1.2 and not added_biotic_capacitor:
					added_biotic_capacitor = true
					var c_inv = player.get_component(C_RelicInventory) as C_RelicInventory
					if c_inv:
						c_inv.add_relic(player, BIOTIC_CAPACITOR)
						print("[Simulation] Added BIOTIC CAPACITOR relic directly to player!")

				# Apply Amplification Array at 1.6s
				if sim_timer >= 1.6 and not added_amplification_array:
					added_amplification_array = true
					var c_inv = player.get_component(C_RelicInventory) as C_RelicInventory
					if c_inv:
						c_inv.add_relic(player, AMPLIFICATION_ARRAY)
						print("[Simulation] Added AMPLIFICATION ARRAY relic directly to player!")

				# Teleport close to button at 2.0s
				if sim_timer >= 2.0 and sim_timer < 2.1:
					if player.global_position != Vector2(150, 100):
						player.global_position = Vector2(150, 100)
						print("[Simulation] Teleported player close to button: ",
							player.global_position)

				# Trigger button interaction at 2.5s (only once)
				if sim_timer >= 2.5 and not button_interacted:
					button_interacted = true
					input.interact_just_pressed = true
					print("[Simulation] Player pressed button interaction key")

				# Apply Sine Wave Modulator at 2.8s and shoot right briefly
				if sim_timer >= 2.8 and not added_sine_wave_modulator:
					added_sine_wave_modulator = true
					var c_inv = player.get_component(C_RelicInventory) as C_RelicInventory
					if c_inv:
						c_inv.add_relic(player, SINE_WAVE_MODULATOR)
						print("[Simulation] Added SINE WAVE MODULATOR relic directly to player!")
				if sim_timer >= 2.8 and sim_timer < 3.1:
					input.shoot_vector = Vector2.RIGHT

				# Teleport player to (50, 50) at 3.2s to trigger enemy CHASE state
				if sim_timer >= 3.2 and sim_timer < 3.3:
					input.shoot_vector = Vector2.ZERO
					if player.global_position != Vector2(50, 50):
						player.global_position = Vector2(50, 50)
						print("[Simulation] Teleported player to (50, 50) to test CHASE: ",
							player.global_position)

				# Apply Orbital Attractor at 3.4s and shoot right briefly
				if sim_timer >= 3.4 and not added_orbital_attractor:
					added_orbital_attractor = true
					var c_inv = player.get_component(C_RelicInventory) as C_RelicInventory
					if c_inv:
						c_inv.add_relic(player, ORBITAL_ATTRACTOR)
						print("[Simulation] Added ORBITAL ATTRACTOR relic directly to player!")
				if sim_timer >= 3.4 and sim_timer < 3.7:
					input.shoot_vector = Vector2.RIGHT

				# Teleport player on top of enemy at (250, 150) at 3.8s to test contact damage
				if sim_timer >= 3.8 and sim_timer < 3.9:
					input.shoot_vector = Vector2.ZERO
					if player.global_position != Vector2(250, 150):
						player.global_position = Vector2(250, 150)
						print("[Simulation] Teleported player on top of enemy to test contact")

				# Teleport player close to Seeking Algorithm pickup at 4.2s
				if sim_timer >= 4.2 and sim_timer < 4.3:
					if player.global_position != Vector2(350, 300):
						player.global_position = Vector2(350, 300)
						print("[Simulation] Teleported player close to relic pickup: ",
							player.global_position)

				# Trigger relic interaction at 4.5s (only once)
				if sim_timer >= 4.5 and not relic_interacted:
					relic_interacted = true
					input.interact_just_pressed = true
					print("[Simulation] Player pressed relic pickup interaction key")

				# Apply Vortex Accelerator at 4.8s and shoot right briefly
				if sim_timer >= 4.8 and not added_vortex_accelerator:
					added_vortex_accelerator = true
					var c_inv = player.get_component(C_RelicInventory) as C_RelicInventory
					if c_inv:
						c_inv.add_relic(player, VORTEX_ACCELERATOR)
						print("[Simulation] Added VORTEX ACCELERATOR relic directly to player!")
				if sim_timer >= 4.8 and sim_timer < 5.1:
					input.shoot_vector = Vector2.RIGHT

				# Teleport player to (500, 500) at 5.2s to trigger enemy IDLE state
				if sim_timer >= 5.2 and sim_timer < 5.3:
					input.shoot_vector = Vector2.ZERO
					if player.global_position != Vector2(500, 500):
						player.global_position = Vector2(500, 500)
						print("[Simulation] Teleported player to (500, 500) to test IDLE: ",
							player.global_position)

				# Teleport player near the coin at 5.4s to test magnetization and collection
				if sim_timer >= 5.4 and sim_timer < 5.5:
					if player.global_position != Vector2(200, 320):
						player.global_position = Vector2(200, 320)
						print("[Simulation] Teleported player near coin to test magnet & collect: ",
							player.global_position)

				# Verify coin collection at 5.8s
				if sim_timer >= 5.8 and not coin_collected_verified:
					coin_collected_verified = true
					var currency = player.get_component(C_Currency) as C_Currency
					if currency and currency.amount == 105:
						print("[Simulation] Success: Coin collected! Currency amount: ", currency.amount)
					else:
						var amt = currency.amount if currency else -1
						print("[Simulation] Error: Coin collection failed! Currency: ", amt)

				# Test Combined Orbital Attractor + Sine Wave Modulator at 6.0s
				if sim_timer >= 6.0 and sim_timer < 6.1:
					if player.global_position != Vector2(50, 50):
						player.global_position = Vector2(50, 50)
						var c_path = player.get_component(C_BulletPath) as C_BulletPath
						if c_path:
							c_path.path_modifiers.clear()
							# Apply Orbital Attractor and Sine Wave Modulator together
							ORBITAL_ATTRACTOR.effects[0].apply(player)
							SINE_WAVE_MODULATOR.effects[0].apply(player)
						print("[Simulation] Applied Orbital Attractor + Sine Wave Modulator combination!")
				if sim_timer >= 6.0 and sim_timer < 6.8:
					input.shoot_vector = Vector2.RIGHT

	# Print player status every second for rapid testing verification
	print_timer += delta
	if print_timer >= 1.0:
		print_timer = 0.0
		_print_status()

	# Automatically quit after 9 seconds if running headlessly
	if DisplayServer.get_name() == "headless" and Time.get_ticks_msec() > 9000:
		get_tree().quit()

func _on_button_interacted() -> void:
	print("[Main] Spawner button callback invoked!")
	spawn_enemy(Vector2(250, 150))

func spawn_enemy(pos: Vector2) -> void:
	var new_enemy = ENEMY_SCENE.instantiate() as Enemy
	new_enemy.position = pos
	add_child(new_enemy)
	world.add_entity(new_enemy)
	print("[Main] Spawned new enemy at %s!" % str(pos))

func _print_status():
	if not player or not is_instance_valid(player):
		return

	var health = player.get_component(C_Health) as C_Health
	var mana = player.get_component(C_Mana) as C_Mana
	var pos = player.global_position if "global_position" in player else Vector2.ZERO

	var h_str = "Health: %.1f/%.1f" % [health.current, health.maximum] if health else "No Health"
	var m_str = "Mana: %.1f" % mana.current if mana else "No Mana"
	var p_str = "Pos: (%.2f, %.2f)" % [pos.x, pos.y]

	var currency = player.get_component(C_Currency) as C_Currency
	var coin_str = "%d coins" % currency.amount if currency else "No Coins"

	var shooter = player.get_component(C_Shooter) as C_Shooter
	var payload = player.get_component(C_Payload) as C_Payload
	var path = player.get_component(C_BulletPath) as C_BulletPath

	var dmg_str = "Dmg: %.1f" % payload.damage if payload else "No Dmg"
	var size_str = "Size: %.1f" % shooter.bullet_size if shooter else "No Size"
	var path_str = "Path: None"
	if path and not path.path_modifiers.is_empty():
		var names = []
		for modifier in path.path_modifiers:
			var script_path = modifier.get_script().resource_path
			if script_path != "":
				names.append(script_path.get_file().get_basename())
			else:
				names.append(modifier.get_class())
		path_str = "Paths: [%s]" % ", ".join(names)

	var c_inv = player.get_component(C_RelicInventory) as C_RelicInventory
	var relic_str = "Relics: []"
	if c_inv:
		var relic_names = []
		for relic in c_inv.relics:
			relic_names.append(relic.name)
		relic_str = "Relics: [%s]" % ", ".join(relic_names)

	var enemy_nodes = get_tree().get_nodes_in_group("enemies")
	var e_health_str = "Enemies: %d" % enemy_nodes.size()
	if not enemy_nodes.is_empty():
		var details = []
		for e in enemy_nodes:
			if is_instance_valid(e):
				var e_health = e.get_component(C_Health) as C_Health
				if e_health:
					details.append("%s: %.1f/%.1f" % [e.name, e_health.current, e_health.maximum])
		e_health_str += " (%s)" % ", ".join(details)

	var status_format = "[GECS Test] %s | %s | %s | %s | %s | %s | %s | %s | %s"
	print(status_format % [p_str, h_str, m_str, coin_str, dmg_str, size_str, path_str, relic_str, e_health_str])

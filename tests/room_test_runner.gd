extends Node2D

const C_ROOM_DATA = preload("res://components/world/c_room_data.gd")
const C_DOOR = preload("res://components/world/c_door.gd")
const C_ENEMY = preload("res://components/behaviour/c_enemy.gd")
const C_CURRENCY = preload("res://components/economy/c_currency.gd")
const C_INPUT = preload("res://components/player/c_input.gd")

var sim_timer: float = 0.0
var enemies_killed_programmatically: bool = false
var coin_collected: bool = false
var boss_room_entered: bool = false
var boss_killed: bool = false
var stairs_stepped: bool = false
var descended_verified: bool = false

@onready var world: World = $World

func _ready() -> void:
	ECS.world = world
	print("[RoomTest] Scene ready. GECS world initialized.")

func _process(delta: float) -> void:
	if ECS.world == world:
		ECS.process(delta)

	if DisplayServer.get_name() == "headless":
		sim_timer += delta

		# 1. Verify start room loaded at 0.5s
		if sim_timer >= 0.5 and sim_timer < 0.6:
			var rooms = world.query.with_all([C_ROOM_DATA]).execute()
			if rooms.is_empty():
				print("[RoomTest] Error: No room entity active at start!")
			else:
				var c_room = rooms[0].get_component(C_ROOM_DATA)
				print("[RoomTest] Current Room Type: %s, Coords: %s" % [
					c_room.room_type, str(c_room.coords)
				])
				if c_room.coords != Vector2i.ZERO:
					print("[RoomTest] Error: Start room coordinates mismatch!")

		# 2. Teleport player to East Door at 1.0s to trigger transition
		if sim_timer >= 1.0 and sim_timer < 1.1:
			var player = get_node_or_null("Entities/EPlayer")
			if player:
				# Find East Door position and teleport player past its threshold
				var east_door = get_node_or_null("Entities/ERoomStart/DoorEast")
				if east_door:
					player.global_position = east_door.global_position + Vector2(15, 0)
					print("[RoomTest] Teleported player onto East Door: ", player.global_position)
				else:
					player.global_position = Vector2(1127, 324)
					print("[RoomTest] Teleported player onto default East Door: ", player.global_position)

		# 3. Verify transition to new room completed at 1.8s
		if sim_timer >= 1.8 and sim_timer < 1.9:
			var rooms = world.query.with_all([C_ROOM_DATA]).execute()
			if not rooms.is_empty():
				var c_room = rooms[0].get_component(C_ROOM_DATA)
				print("[RoomTest] Current Room Type: %s, Coords: %s" % [
					c_room.room_type, str(c_room.coords)
				])
				if c_room.coords == Vector2i.ZERO:
					print("[RoomTest] Error: Player failed to transition out of Start Room!")
				else:
					print("[RoomTest] Success: Player transitioned to coordinate: ", c_room.coords)

		# 4. If transitioned into combat room, kill enemies programmatically at 2.2s
		if sim_timer >= 2.2 and not enemies_killed_programmatically:
			enemies_killed_programmatically = true
			var enemies = world.query.with_all([C_ENEMY]).execute()
			if not enemies.is_empty():
				print("[RoomTest] Spawns: killing %d enemies to simulate clearing room." % enemies.size())
				for enemy in enemies:
					var health = enemy.get_component(C_Health) as C_Health
					if health:
						health.current = 0.0 # Trigger death resolution
			else:
				print("[RoomTest] No enemies in this room (probably a Treasure room).")

		# 5. Verify room cleared and doors unlocked at 3.0s
		if sim_timer >= 3.0 and sim_timer < 3.1:
			var rooms = world.query.with_all([C_ROOM_DATA]).execute()
			if not rooms.is_empty():
				var c_room = rooms[0].get_component(C_ROOM_DATA)
				print("[RoomTest] Room state: ", c_room.state) # 2 is CLEARED
				var doors = world.query.with_all([C_DOOR]).execute()
				var all_unlocked = true
				for door in doors:
					var c_door = door.get_component(C_DOOR)
					if c_door and c_door.is_locked:
						all_unlocked = false
						break
				print("[RoomTest] All doors unlocked: ", all_unlocked)

		# 6. Teleport player onto dropped reward coin at 3.5s
		if sim_timer >= 3.5 and sim_timer < 3.6:
			var coin = get_node_or_null("Entities/TestCoin")
			if not coin:
				# Search for any coin in the entities group
				for child in get_node("Entities").get_children():
					if child.name.begins_with("Coin") or child is Coin:
						coin = child
						break
			var player = get_node_or_null("Entities/EPlayer")
			if coin and player:
				player.global_position = coin.global_position
				print("[RoomTest] Teleported player onto dropped coin at: ", player.global_position)

		# 7. Verify coin collection and increase of currency at 4.2s
		if sim_timer >= 4.2 and not coin_collected:
			coin_collected = true
			var player = get_node_or_null("Entities/EPlayer")
			if player:
				var currency = player.get_component(C_CURRENCY) as C_Currency
				if currency:
					print("[RoomTest] Player currency: %d" % currency.amount)
					if currency.amount > 100:
						print("[RoomTest] Success: Coin collected and resolved.")
					else:
						print("[RoomTest] Warning: Currency was not incremented.")

		# 8. Programmatically transition to Boss Room at 4.6s
		if sim_timer >= 4.6 and not boss_room_entered:
			boss_room_entered = true
			var gen_sys = world.get_node(world.system_nodes_root).get_node_or_null("RoomGenerationSystem")
			if gen_sys:
				var boss_coords = Vector2i.MAX
				for coords in gen_sys.grid.keys():
					if gen_sys.grid[coords]["type"] == "BOSS":
						boss_coords = coords
						break
				if boss_coords != Vector2i.MAX:
					print("[RoomTest] Teleporting player to BOSS room at coords: ", boss_coords)
					gen_sys.transition_to_coords(boss_coords, "south")
				else:
					print("[RoomTest] Error: Boss room not found in layout grid!")

		# 9. Verify Boss Room loaded and spawn boss check at 5.2s
		if sim_timer >= 5.2 and sim_timer < 5.3:
			var rooms = world.query.with_all([C_ROOM_DATA]).execute()
			if not rooms.is_empty():
				var c_room = rooms[0].get_component(C_ROOM_DATA)
				print("[RoomTest] Boss Room Type: %s, Coords: %s" % [
					c_room.room_type, str(c_room.coords)
				])
				if c_room.room_type != "BOSS":
					print("[RoomTest] Error: Failed to transition to BOSS room!")
				
				var boss_node = get_node_or_null("Entities/EBoss")
				if boss_node:
					print("[RoomTest] Success: Boss entity spawned in Boss Room.")
				else:
					print("[RoomTest] Error: Boss entity not found!")

		# 10. Kill boss programmatically at 5.5s
		if sim_timer >= 5.5 and not boss_killed:
			boss_killed = true
			var boss_node = get_node_or_null("Entities/EBoss")
			if boss_node:
				var health = boss_node.get_component(C_Health) as C_Health
				if health:
					print("[RoomTest] Defeating boss programmatically.")
					health.current = 0.0 # Kill the boss
			else:
				print("[RoomTest] Error: Boss not found at 5.5s!")

		# 11. Verify stairs spawned at 6.0s
		if sim_timer >= 6.0 and sim_timer < 6.1:
			var stairs = get_node_or_null("Entities/EStairs")
			if stairs:
				print("[RoomTest] Success: Stairs entity spawned in cleared Boss room.")
			else:
				print("[RoomTest] Error: Stairs entity not found after boss death!")

		# 12. Teleport player onto stairs at 6.3s
		if sim_timer >= 6.3 and not stairs_stepped:
			stairs_stepped = true
			var stairs = get_node_or_null("Entities/EStairs")
			var player = get_node_or_null("Entities/EPlayer")
			if stairs and player:
				player.global_position = stairs.global_position
				print("[RoomTest] Teleported player onto Stairs at: ", player.global_position)

		# 13. Verify transition to Floor 2 (Caves) at 7.0s
		if sim_timer >= 7.0 and not descended_verified:
			descended_verified = true
			var gen_sys = world.get_node(world.system_nodes_root).get_node_or_null("RoomGenerationSystem")
			if gen_sys:
				print("[RoomTest] Current Floor Index: %d" % gen_sys.current_floor_index)
				var rooms = world.query.with_all([C_ROOM_DATA]).execute()
				if not rooms.is_empty():
					var c_room = rooms[0].get_component(C_ROOM_DATA)
					print("[RoomTest] Caves Room Type: %s, Coords: %s" % [
						c_room.room_type, str(c_room.coords)
					])
					if gen_sys.current_floor_index == 1 and c_room.coords == Vector2i.ZERO:
						print("[RoomTest] Success: Descended to Floor 2 (Caves) successfully.")
					else:
						print("[RoomTest] Error: Failed to transition/regenerate next floor.")

		# 14. Quit after 7.6 seconds
		if sim_timer >= 7.6:
			print("[RoomTest] Headless room test simulation finished. Quitting.")
			get_tree().quit()

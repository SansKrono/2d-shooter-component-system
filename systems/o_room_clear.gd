class_name RoomClearObserver
extends Observer

const C_ENEMY = preload("res://components/character/c_enemy.gd")
const C_ROOM_DATA = preload("res://components/character/c_room_data.gd")
const C_SPAWN_REWARD = preload("res://components/character/c_spawn_reward.gd")

const C_DOOR = preload("res://components/character/c_door.gd")
const STAIRS_SCENE = preload("res://entities/rooms/e_stairs.tscn")

func watch() -> Resource:
	return C_ENEMY

func match() -> QueryBuilder:
	return q

func on_component_removed(_entity: Entity, _component: Resource) -> void:
	call_deferred("_check_room_clear")

func _check_room_clear() -> void:
	if not ECS.world:
		return
	var enemies = ECS.world.query.with_all([C_ENEMY]).execute()
	if enemies.is_empty():
		var room_entities = ECS.world.query.with_all([C_ROOM_DATA]).execute()
		if not room_entities.is_empty():
			var room_entity = room_entities[0]
			var room_data = room_entity.get_component(C_ROOM_DATA)
			if room_data.state == 1: # C_RoomData.RoomState.COMBAT is 1
				room_data.state = 2 # C_RoomData.RoomState.CLEARED is 2
				print("[Observer] Room cleared! Spawning reward.")
				room_entity.add_component(C_SPAWN_REWARD.new())
				_unlock_doors()
				if room_data.room_type == "BOSS":
					_spawn_stairs()

func _unlock_doors() -> void:
	print("[Observer] Doors unlocked!")
	if not ECS.world:
		return
	var doors = ECS.world.query.with_all([C_DOOR]).execute()
	for door in doors:
		var c_door = door.get_component(C_DOOR)
		if c_door:
			c_door.is_locked = false
		if door.has_method("_update_visuals"):
			door._update_visuals()

func _spawn_stairs() -> void:
	print("[Observer] Spawning stairs to next floor...")
	var stairs_inst = STAIRS_SCENE.instantiate() as Entity
	stairs_inst.position = Vector2(576, 324)
	var entities_root = ECS.world.get_node(ECS.world.entity_nodes_root)
	entities_root.add_child(stairs_inst)
	ECS.world.add_entity(stairs_inst)


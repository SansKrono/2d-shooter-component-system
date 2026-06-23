# DEPRECATED: Superseded by DungeonGenerationSystem.gd and DungeonTileMapLayer.gd
# Safe to delete once dungeon system is fully stable.
class_name RoomGenerationSystem
extends System

const C_ROOM_DATA = preload("res://components/world/c_room_data.gd")
const C_DOOR = preload("res://components/world/c_door.gd")
const C_INPUT = preload("res://components/player/c_input.gd")
const C_TRANSFORM = preload("res://components/movement/c_transform.gd")
const C_FAMILIAR_OF = preload("res://components/behaviour/c_familiar_of.gd")
const C_BOSS_ARMOR = preload("res://components/combat/c_boss_armor.gd")

const ENEMY_SCENE = preload("res://entities/enemies/e_enemy.tscn")
const RELIC_PICKUP_SCENE = preload("res://entities/environmental/e_relic.tscn")
const AMPLIFICATION_ARRAY = preload("res://resources/relics/amplification_array.tres")
const DESTRUCTIBLE_OBSTACLE_SCENE = preload("res://entities/rooms/e_destructible_obstacle.tscn")

@export var map_seed: int = 12345
@export var target_room_count: int = 6
@export var run_config: Resource = null

var grid: Dictionary = {}
var current_coords: Vector2i = Vector2i.ZERO
var active_room_instance: Entity = null
var generated: bool = false
var transition_cooldown: float = 0.0
var current_floor_index: int = 0

func query() -> QueryBuilder:
	process_empty = true
	return q.with_all([C_ROOM_DATA])

func process(entities: Array[Entity], _components: Array, _delta: float) -> void:
	if Engine.is_editor_hint():
		return

	var dungeon_gen_sys = _world.get_node_or_null("Systems/DungeonGenerationSystem") as DungeonGenerationSystem
	if dungeon_gen_sys and dungeon_gen_sys.enable_tilemap:
		return

	if transition_cooldown > 0.0:
		transition_cooldown -= _delta

	if not generated:
		generated = true
		generate_layout()
		# Instantly load start room at coordinate (0,0)
		call_deferred("_deferred_transition", Vector2i.ZERO, "center")
		return

	# Keep grid layout synced with cleared status
	for entity in entities:
		var c_room = entity.get_component(C_ROOM_DATA)
		if c_room and c_room.coords == current_coords and c_room.state == 2: # CLEARED
			var room_data = grid.get(current_coords)
			if room_data and not room_data["cleared"]:
				room_data["cleared"] = true
				print("[RoomGen] Coords %s marked cleared" % str(current_coords))

func generate_layout() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = map_seed + current_floor_index

	grid.clear()
	grid[Vector2i.ZERO] = {"type": "START", "cleared": true}

	var floor_cfg: Resource = null
	if run_config and current_floor_index < run_config.floors.size():
		floor_cfg = run_config.floors[current_floor_index]

	var min_rooms = target_room_count if not floor_cfg else floor_cfg.min_room_count
	var treasures = 1 if not floor_cfg else floor_cfg.treasure_room_count
	var shops = 1 if not floor_cfg else floor_cfg.shop_room_count
	var bosses = 1

	var total_special_rooms = treasures + shops + bosses
	var path_rooms_needed = max(min_rooms - total_special_rooms - 1, 1)

	var rooms_placed: Array[Vector2i] = [Vector2i.ZERO]
	var neighbor_dirs := [
		Vector2i(0, -1),
		Vector2i(0, 1),
		Vector2i(-1, 0),
		Vector2i(1, 0)
	]

	while rooms_placed.size() < (path_rooms_needed + 1):
		var base_coords = rooms_placed[rng.randi() % rooms_placed.size()]
		var dir = neighbor_dirs[rng.randi() % neighbor_dirs.size()]
		var target_coords = base_coords + dir

		if not grid.has(target_coords):
			grid[target_coords] = {"type": "NORMAL", "cleared": false}
			rooms_placed.append(target_coords)

	var special_to_place: Array[String] = []
	for i in range(bosses):
		special_to_place.append("BOSS")
	for i in range(treasures):
		special_to_place.append("TREASURE")
	for i in range(shops):
		special_to_place.append("SHOP")

	for type in special_to_place:
		var candidates: Array[Vector2i] = []
		for coord in rooms_placed:
			if grid.get(coord, {}).get("type", "NORMAL") != "NORMAL" and coord != Vector2i.ZERO:
				continue
			for dir in neighbor_dirs:
				var candidate = coord + dir
				if not grid.has(candidate) and not candidates.has(candidate):
					candidates.append(candidate)

		candidates.sort_custom(func(a, b):
			var dist_a = abs(a.x) + abs(a.y)
			var dist_b = abs(b.x) + abs(b.y)
			return dist_a > dist_b
		)

		if not candidates.is_empty():
			var chosen = candidates[0]
			grid[chosen] = {"type": type, "cleared": false}
			rooms_placed.append(chosen)
		else:
			for coord in rooms_placed:
				if coord != Vector2i.ZERO and grid[coord]["type"] == "NORMAL":
					grid[coord]["type"] = type
					break

	print("[RoomGen] Floor %d layout generated: %s" % [current_floor_index, str(grid)])

func transition_to_coords(coords: Vector2i, entering_from_dir: String) -> void:
	if transition_cooldown > 0.0:
		return
	transition_cooldown = 1.0 # 1.0s transition cooldown
	call_deferred("_deferred_transition", coords, entering_from_dir)

func _deferred_transition(coords: Vector2i, entering_from_dir: String) -> void:
	if not _world:
		return

	var player: Entity = null
	var players = _world.query.with_all([C_INPUT]).execute()
	for p in players:
		if p is Player:
			player = p
			break

	if not player:
		print("[RoomGen] Error: Player entity not found in GECS world!")
		return

	# Unload previous entities
	var to_remove: Array[Entity] = []
	var dummy_familiar = C_FAMILIAR_OF.new()
	for ent in _world.entities:
		if ent == player:
			continue
		var rel = ent.get_relationship(Relationship.new(dummy_familiar, ECS.wildcard))
		if rel != null:
			continue
		to_remove.append(ent)

	for ent in to_remove:
		_world.remove_entity(ent)

	if active_room_instance and is_instance_valid(active_room_instance):
		active_room_instance.queue_free()
		active_room_instance = null

	current_coords = coords
	var room_data = grid.get(coords)
	if not room_data:
		print("[RoomGen] Error: Coords %s not found in grid!" % str(coords))
		return

	var type: String = room_data["type"]
	var scene_path = ""
	match type:
		"START":
			scene_path = "res://entities/rooms/e_room_start.tscn"
		"NORMAL":
			scene_path = "res://entities/rooms/e_room_normal.tscn"
		"TREASURE":
			scene_path = "res://entities/rooms/e_room_treasure.tscn"
		"BOSS":
			scene_path = "res://entities/rooms/e_room_boss.tscn"
		"SHOP":
			scene_path = "res://entities/rooms/e_room_shop.tscn"

	var scene = load(scene_path) as PackedScene
	if not scene:
		print("[RoomGen] Error: Failed to load room scene: ", scene_path)
		return

	active_room_instance = scene.instantiate() as Entity
	var entities_root = _world.get_node(_world.entity_nodes_root)
	entities_root.add_child(active_room_instance)
	_world.add_entity(active_room_instance)

	# Reposition player safely away from doors to prevent transition bouncing
	# 960x576 room, center at (480, 288)
	var spawn_pos = Vector2(480, 288)
	match entering_from_dir:
		"north": spawn_pos = Vector2(480, 512)  # Enters from south door
		"south": spawn_pos = Vector2(480, 64)   # Enters from north door
		"east": spawn_pos = Vector2(64, 288)    # Enters from west door
		"west": spawn_pos = Vector2(896, 288)   # Enters from east door
		"center": spawn_pos = Vector2(480, 288) # Initial spawn at room center

	player.global_position = spawn_pos
	var phys_body = player.get_node_or_null("PhysicsBody")
	if phys_body:
		phys_body.global_position = spawn_pos
		phys_body.position = Vector2.ZERO
	var trans = player.get_component(C_TRANSFORM)
	if trans:
		trans.position = spawn_pos

	# Apply theme modulation based on the current floor configuration
	var floor_name = "Floor %d" % current_floor_index
	var theme_col = Color.WHITE
	if run_config and current_floor_index < run_config.floors.size():
		var floor_cfg = run_config.floors[current_floor_index]
		floor_name = floor_cfg.floor_name
		theme_col = floor_cfg.theme_color

	var label = active_room_instance.get_node_or_null("DebugLabel") as Label
	if label:
		label.text = "%s\n(%s)\nCoords: %s" % [
			active_room_instance.name.replace("ERoom", "").to_upper(),
			floor_name,
			str(coords)
		]
		label.modulate = theme_col

	var neighbor_dirs = {
		"north": Vector2i(0, -1),
		"south": Vector2i(0, 1),
		"west": Vector2i(-1, 0),
		"east": Vector2i(1, 0)
	}

	var is_combat = (type == "NORMAL" or type == "BOSS") and not room_data["cleared"]

	for dir_name in neighbor_dirs.keys():
		var offset = neighbor_dirs[dir_name]
		var n_coords = coords + offset
		var door_name = "Door" + dir_name.capitalize()
		var door_node = active_room_instance.get_node_or_null(door_name)

		if door_node:
			if grid.has(n_coords):
				door_node.direction = dir_name
				door_node.target_room_coords = n_coords
				door_node.is_locked = is_combat
				_world.add_entity(door_node as Entity)
				# Modulate door's visual color to fit floor theme
				var rect = door_node.get_node_or_null("ColorRect") as ColorRect
				if rect:
					rect.color = theme_col.darkened(0.2)
			else:
				door_node.visible = false
				var area = door_node.get_node_or_null("Area2D") as Area2D
				if area:
					area.process_mode = PROCESS_MODE_DISABLED

	# Collect active door directions and pick layout variation
	var active_doors: Array[String] = []
	for dir_name in neighbor_dirs.keys():
		if grid.has(coords + neighbor_dirs[dir_name]):
			active_doors.append(dir_name)

	# Pick room layout via seeded RNG — deterministic per room
	var room_rng := RandomNumberGenerator.new()
	room_rng.seed = map_seed + current_floor_index * 1000 + coords.x * 100 + coords.y
	var layout_config = _pick_layout(type, room_rng)

	if active_room_instance and active_room_instance.has_method("setup"):
		var obstacle_positions: Array[Vector2] = active_room_instance.setup(type, active_doors, layout_config)
		for obs_pos in obstacle_positions:
			var obs = DESTRUCTIBLE_OBSTACLE_SCENE.instantiate() as Entity
			obs.position = obs_pos
			var er = _world.get_node(_world.entity_nodes_root)
			er.add_child(obs)
			_world.add_entity(obs)

	var c_room = active_room_instance.get_component(C_ROOM_DATA)
	if c_room:
		c_room.coords = coords
		c_room.room_type = type
		c_room.state = 1 if is_combat else 2

	if not room_data["cleared"]:
		# Use enemy positions from layout config if available
		var enemy_positions: Array[Vector2] = []
		if layout_config and "enemy_spawn_positions" in layout_config:
			enemy_positions = layout_config.get("enemy_spawn_positions")

		if type == "NORMAL":
			if enemy_positions.is_empty():
				enemy_positions = [Vector2(256, 192), Vector2(704, 384)]
			for pos in enemy_positions:
				_spawn_enemy(pos)
		elif type == "TREASURE":
			_spawn_relic(Vector2(480, 288))
		elif type == "BOSS":
			_spawn_boss(Vector2(480, 288))
		elif type == "SHOP":
			_spawn_shop_items(Vector2(480, 288))

	print("[RoomGen] Finished loading room coords: %s (%s)" % [str(coords), type])

func _spawn_enemy(pos: Vector2) -> void:
	var enemy_inst = ENEMY_SCENE.instantiate() as Entity
	enemy_inst.position = pos
	var trans = enemy_inst.get_component(C_TRANSFORM)
	if trans:
		trans.position = pos
	var entities_root = _world.get_node(_world.entity_nodes_root)
	entities_root.add_child(enemy_inst)
	_world.add_entity(enemy_inst)

func _spawn_boss(pos: Vector2) -> void:
	var boss_inst = ENEMY_SCENE.instantiate() as Enemy
	boss_inst.type = Enemy.EnemyType.SHOOTER
	boss_inst.name = "EBoss"
	boss_inst.position = pos
	var trans = boss_inst.get_component(C_TRANSFORM)
	if trans:
		trans.position = pos

	var health = boss_inst.get_component(C_Health) as C_Health
	if health:
		health.maximum = 250.0
		health.current = 250.0

	boss_inst.add_component(C_BOSS_ARMOR.new(250.0, 50.0))
	var entities_root = _world.get_node(_world.entity_nodes_root)
	entities_root.add_child(boss_inst)
	_world.add_entity(boss_inst)

func _spawn_relic(pos: Vector2) -> void:
	var relic_inst = RELIC_PICKUP_SCENE.instantiate() as Entity
	relic_inst.name = "TreasureRelic"
	relic_inst.relic_resource = AMPLIFICATION_ARRAY
	relic_inst.position = pos
	var entities_root = _world.get_node(_world.entity_nodes_root)
	entities_root.add_child(relic_inst)
	_world.add_entity(relic_inst)
	NodeFX.hover(relic_inst.get_node("Sprite2D"))

func _spawn_shop_items(pos: Vector2) -> void:
	var relic_inst = RELIC_PICKUP_SCENE.instantiate() as Entity
	relic_inst.name = "ShopRelic"
	relic_inst.relic_resource = AMPLIFICATION_ARRAY
	relic_inst.position = pos
	var entities_root = _world.get_node(_world.entity_nodes_root)
	entities_root.add_child(relic_inst)
	_world.add_entity(relic_inst)
	NodeFX.hover(relic_inst.get_node("Sprite2D"))

func _pick_layout(room_type: String, rng: RandomNumberGenerator) -> Resource:
	var floor_cfg: Resource = null
	if run_config and current_floor_index < run_config.floors.size():
		floor_cfg = run_config.floors[current_floor_index]

	var layouts: Array[Resource] = []
	if floor_cfg:
		match room_type:
			"NORMAL":
				if "normal_room_layouts" in floor_cfg:
					layouts = floor_cfg.get("normal_room_layouts")
			"BOSS":
				if "boss_room_layouts" in floor_cfg:
					layouts = floor_cfg.get("boss_room_layouts")
			"TREASURE":
				if "treasure_room_layouts" in floor_cfg:
					layouts = floor_cfg.get("treasure_room_layouts")
			"SHOP":
				if "shop_room_layouts" in floor_cfg:
					layouts = floor_cfg.get("shop_room_layouts")
			"START":
				if "start_room_layouts" in floor_cfg:
					layouts = floor_cfg.get("start_room_layouts")

	if layouts.is_empty():
		return null
	return layouts[rng.randi() % layouts.size()]

func descend_floor() -> void:
	if transition_cooldown > 0.0:
		return
	transition_cooldown = 1.0 # 1.0s transition cooldown
	call_deferred("_deferred_descend")

func _deferred_descend() -> void:
	current_floor_index += 1
	if run_config and current_floor_index >= run_config.floors.size():
		print("[RoomGen] Run completed! Victory!")
		var gm = get_tree().root.get_node_or_null("MainGame")
		if gm and gm.has_method("trigger_victory"):
			gm.trigger_victory()
		else:
			if get_tree():
				get_tree().quit()
		return

	generated = false # Force map regeneration
	print("[RoomGen] Descending to floor index %d" % current_floor_index)
	if not _world:
		return
	generate_layout()
	_deferred_transition(Vector2i.ZERO, "south")

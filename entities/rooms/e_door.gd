@tool
class_name DoorEntity
extends Entity

const C_DOOR = preload("res://components/character/c_door.gd")

@export var direction: String = "north"
@export var target_room_coords: Vector2i = Vector2i.ZERO
@export var is_locked: bool = false:
	set(val):
		is_locked = val
		_update_visuals()

var global_pos: Vector2:
	get:
		var node = self as Node
		if "global_position" in node:
			return node.get("global_position") as Vector2
		return Vector2.ZERO

var _notified_locked: bool = false

func define_components() -> Array:
	return [
		C_DOOR.new(direction, target_room_coords, is_locked)
	]

func on_ready() -> void:
	if not Engine.is_editor_hint():
		_update_visuals()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return

	var area = get_node_or_null("Area2D") as Area2D
	if not area:
		return

	var player_found = false
	for overlapping_area in area.get_overlapping_areas():
		var target = overlapping_area.owner as Entity
		if not target:
			target = overlapping_area.get_parent() as Entity
		if target and target is Player:
			player_found = true
			_check_and_trigger_transition(target)
			break

	if not player_found:
		_notified_locked = false

func _check_and_trigger_transition(player: Player) -> void:
	var c_door = get_component(C_DOOR)
	if not c_door:
		return

	var threshold_passed = false
	# Require player to move partially offscreen past the door center
	match direction:
		"north":
			if player.global_position.y <= global_pos.y - 12.0:
				threshold_passed = true
		"south":
			if player.global_position.y >= global_pos.y + 12.0:
				threshold_passed = true
		"west":
			if player.global_position.x <= global_pos.x - 12.0:
				threshold_passed = true
		"east":
			if player.global_position.x >= global_pos.x + 12.0:
				threshold_passed = true

	if threshold_passed:
		if not c_door.is_locked:
			_notified_locked = false
			print("[DoorDebug] %s Transitioning to %s (player pos: %s, door pos: %s)" % [
				direction,
				str(c_door.target_room_coords),
				str(player.global_position),
				str(global_pos)
			])
			var systems_root = ECS.world.get_node(ECS.world.system_nodes_root)
			var gen_sys = systems_root.get_node_or_null("RoomGenerationSystem")
			if gen_sys:
				gen_sys.transition_to_coords(c_door.target_room_coords, c_door.direction)
		else:
			if not _notified_locked:
				_notified_locked = true
				print("[DoorDebug] %s This door is locked!" % direction)

func _update_visuals() -> void:
	var label = get_node_or_null("Label") as Label
	if label:
		var status = " [L]" if is_locked else ""
		label.text = direction.to_upper() + status

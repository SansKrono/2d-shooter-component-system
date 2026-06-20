@tool
class_name ChannelSpawnerEntity
extends Entity

const C_CHANNEL_SPAWNER_SCRIPT = preload("res://components/character/c_channel_spawner.gd")

@export var channel: int = -1:
	set(val):
		channel = val
		_update_component()

@export var scene_to_spawn: PackedScene:
	set(val):
		scene_to_spawn = val
		_update_component()

var _spawner: Resource

func define_components() -> Array:
	_spawner = C_CHANNEL_SPAWNER_SCRIPT.new(channel, scene_to_spawn)
	return [
		_spawner
	]

func _update_component() -> void:
	var c_spawner = get_component(C_CHANNEL_SPAWNER_SCRIPT) as C_CHANNEL_SPAWNER_SCRIPT
	if c_spawner:
		c_spawner.channel = channel
		c_spawner.scene_to_spawn = scene_to_spawn
	elif _spawner:
		_spawner.channel = channel
		_spawner.scene_to_spawn = scene_to_spawn

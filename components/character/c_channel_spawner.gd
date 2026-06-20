class_name C_ChannelSpawner
extends Component

@export var channel: int = -1
@export var scene_to_spawn: PackedScene

func _init(chan: int = -1, scene: PackedScene = null) -> void:
	channel = chan
	scene_to_spawn = scene

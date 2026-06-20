class_name C_Spawner
extends Component

@export var scene_to_spawn: PackedScene
@export var spawn_cooldown: float = 4.0
@export var max_spawn_count: int = -1
@export var spawn_offset: Vector2 = Vector2.ZERO

var spawn_timer: float = 0.0
var current_spawn_count: int = 0

func _init(scene: PackedScene = null, cooldown: float = 4.0, max_spawns: int = -1, offset: Vector2 = Vector2.ZERO) -> void:
	scene_to_spawn = scene
	spawn_cooldown = cooldown
	max_spawn_count = max_spawns
	spawn_offset = offset
	spawn_timer = 0.0
	current_spawn_count = 0

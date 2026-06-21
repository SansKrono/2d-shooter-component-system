extends Node2D

@onready var world: World = $World

func _ready() -> void:
	ECS.world = world
	print("[DungeonGame] Game scene ready. GECS world initialized.")

func _process(delta: float) -> void:
	if ECS.world == world:
		ECS.process(delta)

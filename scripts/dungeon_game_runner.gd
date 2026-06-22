extends Node2D

@onready var world: World = $World

func _ready() -> void:
	ECS.world = world
	print("[DungeonGame] Game scene ready. GECS world initialized.")

	var cursor_tex = load("res://assets/shoot-cursor.png") as Texture2D
	if cursor_tex:
		DisplayServer.cursor_set_custom_image(cursor_tex, DisplayServer.CURSOR_ARROW, Vector2(8, 8))

func _process(delta: float) -> void:
	if ECS.world == world:
		ECS.process(delta)

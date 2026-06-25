extends Node

func _ready():
	var player_scene = load("res://entities/player/e_player.tscn")
	print("Loaded player scene: ", player_scene)
	var player = player_scene.instantiate()
	print("Instantiated player: ", player)
	var camera = player.get_node_or_null("DungeonCamera")
	print("Camera: ", camera)
	if camera:
		print("Camera zoom: ", camera.zoom)
	else:
		print("No camera found!")
	get_tree().quit()

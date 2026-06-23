extends Control

signal retry_pressed
signal main_menu_pressed

@onready var stats_text: Label = $Panel/VBoxContainer/StatsText
@onready var retry_button: TextureButton = $Panel/VBoxContainer/RetryButton
@onready var menu_button: TextureButton = $Panel/VBoxContainer/MenuButton

func _ready() -> void:
	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

func _on_retry_pressed() -> void:
	retry_pressed.emit()

func _on_menu_pressed() -> void:
	main_menu_pressed.emit()

func set_stats(time_str: String, kills: int, relics_str: String) -> void:
	stats_text.text = "Time Survived: %s\nEnemies Defeated: %d\nRelics Collected: %s" % [
		time_str, kills, relics_str
	]

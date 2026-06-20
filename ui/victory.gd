extends Control

signal play_again_pressed
signal main_menu_pressed

@onready var stats_text: Label = $Panel/VBoxContainer/StatsText
@onready var play_again_button: Button = $Panel/VBoxContainer/PlayAgainButton
@onready var menu_button: Button = $Panel/VBoxContainer/MenuButton

func _ready() -> void:
	play_again_button.pressed.connect(_on_play_again_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

func _on_play_again_pressed() -> void:
	play_again_pressed.emit()

func _on_menu_pressed() -> void:
	main_menu_pressed.emit()

func set_stats(time_str: String, kills: int, relics_str: String) -> void:
	stats_text.text = "Time Cleared: %s\nEnemies Killed: %d\nRelics: %s" % [
		time_str, kills, relics_str
	]

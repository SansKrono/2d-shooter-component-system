extends Control

signal start_run_pressed
signal quit_game_pressed

@onready var start_button: TextureButton = $Panel/VBoxContainer/StartButton
@onready var quit_button: TextureButton = $Panel/VBoxContainer/QuitButton

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_start_pressed() -> void:
	start_run_pressed.emit()

func _on_quit_pressed() -> void:
	quit_game_pressed.emit()

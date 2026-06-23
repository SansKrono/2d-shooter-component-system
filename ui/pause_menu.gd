extends Control

signal resume_pressed
signal restart_pressed
signal main_menu_pressed

@onready var resume_button: TextureButton = $Panel/VBoxContainer/ResumeButton
@onready var restart_button: TextureButton = $Panel/VBoxContainer/RestartButton
@onready var menu_button: TextureButton = $Panel/VBoxContainer/MenuButton

func _ready() -> void:
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

func _on_resume_pressed() -> void:
	resume_pressed.emit()

func _on_restart_pressed() -> void:
	restart_pressed.emit()

func _on_menu_pressed() -> void:
	main_menu_pressed.emit()

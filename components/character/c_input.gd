class_name C_Input
extends Component

@export var movement_vector: Vector2 = Vector2.ZERO
@export var shoot_vector: Vector2 = Vector2.ZERO
@export var interact_pressed: bool = false
@export var interact_just_pressed: bool = false
@export var fire_button_held: bool = false
@export var fire_button_just_pressed: bool = false
@export var fire_button_just_released: bool = false
@export var aim_direction: Vector2 = Vector2.ZERO
@export var mode_toggle_just_pressed: bool = false

func is_shooting() -> bool:
	return shoot_vector != Vector2.ZERO

func get_shoot_direction() -> Vector2:
	return shoot_vector.normalized()

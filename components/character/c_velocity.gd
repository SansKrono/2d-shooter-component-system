class_name C_Velocity
extends Component

@export var direction: Vector2 = Vector2.ZERO
@export var speed: float = 200.0
@export var knockback: Vector2 = Vector2.ZERO

func _init(dir: Vector2 = Vector2.ZERO, spd: float = 200.0):
	direction = dir
	speed = spd
	knockback = Vector2.ZERO

class_name C_Shooter
extends Component

@export var cooldown_timer: float = 0.0
@export var fire_rate: float = 0.2 # Cooldown in seconds between shots
@export var bullet_speed: float = 400.0
@export var bullet_size: float = 1.0

func _init(rate: float = 0.2, speed: float = 400.0, size: float = 1.0):
	fire_rate = rate
	bullet_speed = speed
	bullet_size = size
	cooldown_timer = 0.0

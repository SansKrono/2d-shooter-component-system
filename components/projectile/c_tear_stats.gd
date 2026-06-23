class_name C_TearStats
extends Component

@export var damage: float = 3.5
@export var tear_delay: int = 10
@export var tear_range: float = 6.5
@export var shot_speed: float = 1.0
@export var luck: float = 0.0

# Runtime tracking
var current_cooldown_sec: float = 0.0

func _init(
	dmg: float = 3.5,
	delay: int = 10,
	rng: float = 6.5,
	spd: float = 1.0,
	lck: float = 0.0
) -> void:

	damage = dmg
	tear_delay = delay
	tear_range = rng
	shot_speed = spd
	luck = lck


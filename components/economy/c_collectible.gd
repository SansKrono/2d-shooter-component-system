class_name C_Collectible
extends Component

@export var collection_range: float = 30.0
@export var magnet_range: float = 150.0
@export var magnet_speed: float = 400.0

var on_collected: Callable
var collected: bool = false

func _init(rng: float = 30.0, mag_rng: float = 150.0, mag_spd: float = 400.0, action: Callable = Callable()) -> void:
	collection_range = rng
	magnet_range = mag_rng
	magnet_speed = mag_spd
	on_collected = action
	collected = false

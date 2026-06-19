class_name C_Trajectory
extends Component

@export var max_range: float = 500.0 # Distance traveled before fading/dropping
@export var accuracy_deviation: float = 5.0 # Degrees of random spread on firing
@export var homing_strength: float = 0.0 # 0.0 = straight line, higher = tracking speed
@export var distance_traveled: float = 0.0 # Runtime tracking

func _init(rng: float = 500.0, dev: float = 5.0, homing: float = 0.0):
	max_range = rng
	accuracy_deviation = dev
	homing_strength = homing
	distance_traveled = 0.0

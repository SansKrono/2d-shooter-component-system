class_name C_Locomotion
extends Component

# --- Designer-facing exports ---
@export var base_speed: float = 180.0   # pixels/sec at full input
@export var acceleration: float = 900.0  # px/s² — time to reach top speed
@export var friction: float = 1200.0   # px/s² — time to stop (higher = snappier)

# --- Runtime state (written by MovementSystem) ---
var current_velocity: Vector2 = Vector2.ZERO  # smoothed locomotion vel
var speed_multiplier: float = 1.0             # set by corruption / buffs

func _init(spd: float = 180.0, accel: float = 900.0, fric: float = 1200.0) -> void:
	base_speed = spd
	acceleration = accel
	friction = fric

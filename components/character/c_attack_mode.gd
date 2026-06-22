class_name C_AttackMode
extends Component

const MODE_TECH: String = "TECH"
const MODE_MAGIC: String = "MAGIC"

@export var mode: String = MODE_TECH
@export var charge_level: float = 0.0
@export var charge_timer: float = 0.0
@export var cooldown_timer: float = 0.0
@export var is_charging: bool = false
@export var visual_initialized: bool = false

const CHARGE_DURATION: float = 0.8
const BASE_COOLDOWN_TECH: float = 0.15
const BASE_COOLDOWN_MAGIC: float = 0.20

func _init(initial_mode: String = MODE_TECH) -> void:
	mode = initial_mode

func get_scaled_cooldown() -> float:
	var base = BASE_COOLDOWN_TECH if mode == MODE_TECH else BASE_COOLDOWN_MAGIC
	return base * (1.0 + charge_level * 0.5)

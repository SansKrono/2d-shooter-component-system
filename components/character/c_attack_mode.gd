class_name C_AttackMode
extends Component

const MODE_TECH: String = "TECH"
const MODE_MAGIC: String = "MAGIC"
const CHARGE_DURATION: float = 0.8

@export var tech_fire_timer: float = 0.0
@export var magic_fire_timer: float = 0.0
@export var tech_charge_level: float = 0.0
@export var tech_charge_timer: float = 0.0
@export var magic_charge_level: float = 0.0
@export var magic_charge_timer: float = 0.0
@export var visual_initialized: bool = false

func _init() -> void:
	pass

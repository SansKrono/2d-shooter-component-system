class_name C_Power
extends Component

@export var current: float = 100.0
@export var maximum: float = 100.0
@export var regen_rate: float = 15.0

func _init(max_power: float = 100.0, regen: float = 15.0):
	maximum = max_power
	current = max_power
	regen_rate = regen

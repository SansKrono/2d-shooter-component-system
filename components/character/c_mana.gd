class_name C_Mana
extends Component

@export var current: float = 100.0
@export var maximum: float = 100.0
@export var regen_rate: float = 5.0 # Regenerate 5 mana per second

func _init(max_mana: float = 100.0, regen: float = 5.0):
	maximum = max_mana
	current = max_mana
	regen_rate = regen

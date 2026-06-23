class_name C_BossArmor
extends Component

@export var base_hp: float = 1000.0
@export var armor_value: float = 90.0
var damage_history: Array[Dictionary] = [] # Stores {timestamp: float, amount: float}

func _init(hp: float = 1000.0, armor: float = 90.0) -> void:
	base_hp = hp
	armor_value = armor
